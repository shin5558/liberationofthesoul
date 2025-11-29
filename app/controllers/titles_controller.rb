class TitlesController < ApplicationController
  # B画面：タイトル
  def show
    reset_session
    # A画面用：今はタイトルフェーズ
    session[:screen_mode] = 'title'
  end

  # 「ゲームを始める」ボタン（B画面）
  def start_game
    # A画面用：キャラ作成フェーズに入った
    session[:screen_mode] = 'character'

    # B画面はキャラ作成へ
    redirect_to new_character_path
  end

  # どこからでも全リセット
  def reset
    reset_session
    redirect_to root_path, notice: 'ゲームを最初からに戻しました。'
  end
end
