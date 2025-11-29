class ScreensController < ApplicationController
  # A：タイトル画面
  def title
  end

  # A：キャラクター作成フェーズ用（妖精）
  def character
    @player = Player.find_by(id: session[:player_id])
  end

  # A：キャラ作成完了（光＋キャラ）
  def summary
    @player = Player.find_by(id: session[:player_id])
  end

  # A：プロローグ以降（街の背景）
  def story
    @player   = Player.find_by(id: session[:player_id])
    @progress = @player && StoryProgress.find_by(player: @player)
    @step     = @progress&.current_step || 'prologue'
  end

  # A：バトル画面（とりあえず共通）
  def battle
  end

  # A：モード確認 API  —— ★ここをシンプルに戻す
  def mode
    mode = session[:screen_mode].presence || 'title'
    render plain: mode
  end
end
