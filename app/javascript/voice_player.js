// app/javascript/voice_player.js

// グローバルに公開して、どのビューからも使えるようにする
window.setupVoicePlayer = function setupVoicePlayer(options) {
  const {
    order,                // ["narrator_1", "narrator_2", ...]
    containerSelector,    // "#prologue-script" など
    lineSelector,         // ".prologue-line" / ".branch1-line" などビューごと
    playButtonSelector,   // "#prologue-play" など（任意）
    basePath              // "/voices/prologue" など
  } = options;

  const container = document.querySelector(containerSelector);
  if (!container) return;

  // セリフDOMを集める
  const lineEls = {};
  container.querySelectorAll(lineSelector).forEach((el) => {
    const id = el.dataset.lineId;
    if (id) lineEls[id] = el;
  });

  function setActive(lineId) {
    Object.values(lineEls).forEach((el) => {
      el.classList.remove("is-speaking");
    });
    if (lineId && lineEls[lineId]) {
      const el = lineEls[lineId];
      el.classList.add("is-speaking");
      el.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }

  let currentIndex = -1;
  const audio = new Audio();
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

  audio.addEventListener("ended", playNext);

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

  // 1行目だけプリロード → 終わったら再生開始
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