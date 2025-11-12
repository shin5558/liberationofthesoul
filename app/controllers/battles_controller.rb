class BattlesController < ApplicationController
  HAND_LABELS = { 'g' => 'グー', 't' => 'チョキ', 'p' => 'パー' }.freeze

  def new
    pid = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)
    return redirect_to new_character_path, alert: '先にキャラクターを作成してください。' unless @player

    @battle = Battle.find_by(player: @player, status: :ongoing)
    return if @battle

    @battle = Battle.create!(
      player: @player,
      enemy: Enemy.first,
      status: :ongoing,
      turns_count: 0,
      player_hp: @player.base_hp, # ← 初回だけ初期HPをセット
      enemy_hp: Enemy.first.base_hp,
      flags: {}
    )
  end

  def create
    pid = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)
    return redirect_to new_character_path, alert: '先にキャラクターを作成してください。' unless @player

    @battle = Battle.find_by(id: params[:battle_id], player: @player) ||
              Battle.find_by(player: @player, status: :ongoing)
    return redirect_to new_battle_path(player_id: @player.id), alert: 'バトルが見つかりません。' unless @battle

    player_hand = params[:hand].presence
    return redirect_to new_battle_path(player_id: @player.id), alert: '手の指定が不正です。' unless HAND_LABELS.key?(player_hand)

    cpu_hand = %w[g t p].sample
    result   = JankenJudgeService.resolve(player_hand, cpu_hand)

    # ダメージ反映（1点想定）
    case result
    when :player_win
      @battle.enemy_hp = [@battle.enemy_hp - 1, 0].max # 小さい方を切り上げ
    when :cpu_win
      @battle.player_hp = [@battle.player_hp - 1, 0].max
    end

    # 勝敗確定
    @battle.status = if @battle.enemy_hp <= 0
                       :won
                     elsif @battle.player_hp <= 0
                       :lost
                     else
                       :ongoing
                     end

    @battle.turns_count += 1
    @battle.flags = (@battle.flags || {}).merge(player_hand: player_hand, cpu_hand: cpu_hand, result: result)
    @battle.save!

    redirect_to battle_path(@battle)
  end

  def show
    @battle = Battle.find_by(id: params[:id]) or
      return redirect_to new_battle_path(player_id: session[:player_id]), alert: 'バトルが見つかりません。'

    @hand        = @battle.flags&.dig('player_hand')
    @cpu_hand    = @battle.flags&.dig('cpu_hand')
    @result      = @battle.flags&.dig('result')

    @hand_label     = HAND_LABELS[@hand]     || '未設定'
    @cpu_hand_label = HAND_LABELS[@cpu_hand] || '未設定'

    @result_text =
      case @result&.to_sym
      when :player_win then 'あなたの勝ち！'
      when :cpu_win    then 'あなたの負け…'
      when :draw       then '引き分けです。'
      else                  '判定不能'
      end
  end
end
