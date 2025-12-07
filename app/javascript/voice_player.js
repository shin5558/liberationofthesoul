// app/javascript/voice_player.js

// 🔸 今鳴っているストーリー用 Audio をグローバルで保持
window.currentStoryAudio = window.currentStoryAudio || null;

// 🔸 どこからでも呼べる「ストーリー音声を止める」関数
window.stopStoryVoices = function stopStoryVoices() {
  const audio = window.currentStoryAudio;
  if (!audio) return;

  try {
    audio.pause();
    audio.currentTime = 0;
    audio.removeAttribute("src");
  } catch (e) {
    console.warn("stopStoryVoices 失敗:", e);
  }
};

// グローバルに公開して、どのビューからも使えるようにする
window.setupVoicePlayer = function setupVoicePlayer(options) {
  const {
    order,                // ["narrator_1", "narrator_2", ...]
    containerSelector,    // "#prologue-script" など
    lineSelector,         // ".prologue-line" / ".branch1-line" など
    playButtonSelector,   // "#prologue-play" など（任意）
    basePath              // "/voices/prologue" など
  } = options;

  const container = document.querySelector(containerSelector);
  if (!container) return;

  // 🔹 ページが変わるたびに「前のシーンの音声」をいったん止める
  if (window.stopStoryVoices) {
    window.stopStoryVoices();
  }

  // セリフDOMを集める
  const lineEls = {};
  container.querySelectorAll(lineSelector).forEach((el) => {
    const id = el.dataset.lineId;
    if (id) lineEls[id] = el;
  });

  function setActive(lineId) {
    Object.values(lineEls).forEach((el) => {
      el.classList.remove("is-speaking", "is-active");
    });
    if (lineId && lineEls[lineId]) {
      const el = lineEls[lineId];
      el.classList.add("is-speaking", "is-active");
      el.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }

  let currentIndex = -1;

  // 🔹 「ストーリー専用 Audio」を 1 台だけ使い回す
  const audio = window.currentStoryAudio || new Audio();
  window.currentStoryAudio = audio;

  // 念のため初期化
  try {
    audio.pause();
  } catch (e) {}
  audio.currentTime = 0;
  audio.onended = null; // 古いハンドラを消す

  const voiceCache = {};

  function preloadVoice(lineId) {
    if (voiceCache[lineId]) return Promise.resolve();

    const url =
      basePath +
      "?line=" +
      encodeURIComponent(lineId) +
      "&t=" +
      Date.now();

    return fetch(url)
      .then((res) => res.arrayBuffer())
      .then((buf) => {
        const blob = new Blob([buf], { type: "audio/wav" });
        const objectUrl = URL.createObjectURL(blob);
        voiceCache[lineId] = objectUrl;
      })
      .catch((err) => {
        console.error("preload error:", err);
      });
  }

  function playNext() {
    currentIndex += 1;
    if (currentIndex >= order.length) {
      setActive(null);
      return;
    }

    const lineId = order[currentIndex];
    setActive(lineId);

    const cached = voiceCache[lineId];
    const btn = playButtonSelector
      ? document.querySelector(playButtonSelector)
      : null;

    function handlePlayError(err) {
      console.warn("play error:", err);
      if (btn) btn.style.display = "inline-block";
    }

    if (cached) {
      audio.src = cached;
      audio.play().catch(handlePlayError);
    } else {
      const url =
        basePath +
        "?line=" +
        encodeURIComponent(lineId) +
        "&t=" +
        Date.now();
      audio.src = url;
      audio.play().catch(handlePlayError);
    }
  }

  // 🔹 ended は addEventListener ではなく onended で上書き
  audio.onended = function () {
    playNext();
  };

  const btn = playButtonSelector
    ? document.querySelector(playButtonSelector)
    : null;
  if (btn) {
    btn.addEventListener("click", function () {
      btn.style.display = "none";
      currentIndex = -1;
      playNext();
    });
  }

  // 1行目だけプリロード → 再生開始
  if (order && order.length > 0) {
    preloadVoice(order[0]).then(() => {
      currentIndex = -1;
      playNext();
    });

    // 残りは裏でプリロード
    order.slice(1).forEach((lineId) => {
      preloadVoice(lineId);
    });
  }
};