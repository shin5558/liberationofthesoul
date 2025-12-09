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
    @player = Player.find_by(id: session[:player_id])
    @step = session[:current_step] || 'prologue'
    render "screens/story/#{@step}"
  end

  # A：バトル画面（とりあえず共通）
  def battle
    @battle = Battle.find_by(id: session[:battle_id])
  end

  # # # ★ A：モード確認 API
  def mode
    mode = session[:screen_mode].presence || 'title'
    render plain: mode
  end

  # ★ A：モード＋ステップ確認 API
  def state
    mode = session[:screen_mode].presence || 'title'
    step = session[:current_step].presence || 'prologue'

    render json: { mode: mode, step: step }
  end
end
