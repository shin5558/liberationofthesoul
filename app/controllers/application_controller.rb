class ApplicationController < ActionController::Base
  helper_method :current_player, :current_story_progress

  private

  def current_player
    @current_player ||= Player.find_by(id: session[:player_id])
  end

  def current_story_progress
    return nil unless current_player

    @current_story_progress ||= StoryProgress.find_or_create_by!(
      player: current_player
    ) do |sp|
      sp.current_step = 'npc_talk'
      sp.flags = { 'talk_logs' => [] }
    end
  end

  def require_player!
    # すでにプレイヤーがいればそのまま
    return if current_player

    # ★ 開発環境だけ、自動でデバッグ勇者を作る
    if Rails.env.development?
      player = Player.create!(
        name: 'デバッグ勇者',
        name_kana: 'デバッグユウシャ'
      )
      session[:player_id] = player.id
      @current_player = player # current_player でも同じものが返るようにしておく
    else
      # 本番などでは、今まで通りキャラ作成画面へ
      redirect_to new_character_path, alert: 'キャラクターを作成してください。'
    end
  end
end
