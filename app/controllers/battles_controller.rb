class BattlesController < ApplicationController
  HAND_LABELS = { 'g' => 'グー', 't' => 'チョキ', 'p' => 'パー' }.freeze

  def new
    # パラメータ優先、なければセッションから復元
    pid = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)
    # ここで flash は設定しない（画面表示だけ）

    return if @player

    redirect_to new_character_path, alert: '先にキャラクターを作成してください。'
    nil
  end

  def create
    pid = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)

    # new と同じ“形”を保ちつつ、意味は「@playerがいなければリダイレクト」
    unless @player
      redirect_to new_character_path, alert: '先にキャラクターを作成してください。'
      return
    end

    player_hand = params[:hand].presence # "g"/"t"/"p"
    unless HAND_LABELS.key?(player_hand)
      redirect_to new_battle_path(player_id: @player.id), alert: '手の指定が不正です。'
      return
    end

    # ここは仮の受け皿（M2-13想定）
    @battle = Battle.create!(
      player: @player,
      enemy: Enemy.first,
      status: :ongoing,
      turns_count: 0,
      flags: {}
    )
    cpu_hand = %w[g t p].sample

    # リロードでも残るように flags に保存
    @battle.update!(flags: (@battle.flags || {}).merge(player_hand: player_hand, cpu_hand: cpu_hand))

    # 仮のCPU手（tなど）や判定は後で実装
    redirect_to battle_path(@battle, hand: player_hand)
  end

  def show
    @battle = Battle.find_by(id: params[:id])
    unless @battle
      redirect_to new_battle_path(player_id: session[:player_id]),
                  alert: 'バトルが見つかりません。もう一度はじめてください。'
      return
    end

    # URLの hand を優先。無ければ flags から復元
    @hand     = params[:hand].presence || @battle.flags&.dig('player_hand')
    @cpu_hand = @battle.flags&.dig('cpu_hand') || 't'

    @hand_label     = HAND_LABELS[@hand]     || '未設定'
    @cpu_hand_label = HAND_LABELS[@cpu_hand] || '未設定'
  end
end
