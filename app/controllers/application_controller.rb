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
    redirect_to new_character_path, alert: 'キャラクターを作成してください。' unless current_player
  end
end
