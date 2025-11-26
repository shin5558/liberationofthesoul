class CharactersController < ApplicationController
  def new
    @player = Player.new
  end

  def create
    @player = Player.new(player_params)

    # ★DBの name が NOT NULL なので、ひとまず name_kana をそのまま入れておく
    @player.name = @player.name_kana
    # base_hp を使っているなら、ここで初期値をセット（前の仕様を引き継ぐ）
    @player.base_hp ||= 5

    if @player.save
      session[:player_id] = @player.id

      # ストーリー進行の初期レコード
      StoryProgress.find_or_create_by!(player: @player) do |sp|
        sp.current_step = 'npc_talk' # まずはNPC会話ステップに入る
        sp.flags        = { 'talk_logs' => [] }
      end

      redirect_to npc_intro_story_path, notice: 'キャラクターを作成しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def player_params
    params.require(:player).permit(:name_kana, :gender)
  end
end
