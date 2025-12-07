// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "./voice_player";

// === BGM を止める共通関数 ===
function stopBattleBgm() {
  var bgm = document.getElementById("battle-bgm"); // ← これ
  if (!bgm) {
    console.warn("battle-bgm が見つからないよ");
    return;
  }
  bgm.pause();
  bgm.currentTime = 0;
  console.log("BGM 停止: battle-bgm");
}

// 🚩 ページ遷移前にストーリー音声も止める
document.addEventListener("turbo:before-visit", function () {
  if (window.stopStoryVoices) {
    window.stopStoryVoices();
  }
});

// === 「リザルト用の frame なら止める」ヘルパー ===
function stopBattleBgmIfResultFrame(frame) {
  if (!frame) return;

  // data-battle-result="true" が付いているときだけ止める
  if (frame.dataset && frame.dataset.battleResult === "true") {
    stopBattleBgm();
  }
}
