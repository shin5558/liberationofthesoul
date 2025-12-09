class BattlesController < ApplicationController
  HAND_LABELS = { 'g' => 'グー', 't' => 'チョキ', 'p' => 'パー' }.freeze

  # =========================
  # バトル開始
  # =========================
  def new
    pid = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)

    unless @player
      redirect_to new_character_path, alert: '先にキャラクターを作成してください。'
      return
    end

    session[:player_id] = @player.id

    requested_enemy_code = params[:enemy_type].presence

    # 進行中バトル（同じプレイヤーで status: ongoing）を探す
    @battle = Battle.find_by(player: @player, status: :ongoing)

    # もし進行中バトルがあるのに、別の enemy_code が指定されたら捨てて作り直す
    if @battle && requested_enemy_code.present? && @battle.enemy.code != requested_enemy_code
      @battle.update(status: :aborted)
      @battle = nil
    end

    unless @battle
      enemy_code = requested_enemy_code || 'goblin'
      enemy      = Enemy.find_by(code: enemy_code)
      enemy    ||= Enemy.find_by(code: 'goblin')

      unless enemy
        redirect_to root_path, alert: "指定された敵（#{enemy_code}）が存在しません。"
        return
      end

      @battle = Battle.create!(
        player: @player,
        enemy: enemy,
        status: :ongoing,
        turns_count: 0,
        flags: { 'enemy_code' => enemy.code }
      )

      # 無属性カード 1枚
      @battle.assign_random_neutral_card!
      # 通常手札 5枚
      @battle.prepare_initial_hands!
      @battle.save!
    end

    # ★★ ここを追加：A画面に「今はバトル＋このID」と伝える
    session[:screen_mode] = 'battle'
    session[:battle_id]   = @battle.id

    # ★ show ではなく control_screen へ
    redirect_to control_screen_battle_path(@battle)
  end

  # =========================
  # じゃんけん
  # =========================
  def create
    pid = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)
    unless @player
      redirect_to new_character_path, alert: '先にキャラクターを作成してください。'
      return
    end

    @battle = Battle.find_by(id: params[:battle_id], player: @player) ||
              Battle.find_by(player: @player, status: :ongoing)

    unless @battle
      redirect_to new_battle_path(player_id: @player.id), alert: 'バトルが見つかりません。'
      return
    end

    flags = (@battle.flags || {}).deep_dup

    unless flags['can_janken']
      # ★ ここも control_screen へ戻す
      redirect_to control_screen_battle_path(@battle), alert: '先にカードを1枚使ってください。'
      return
    end

    player_hand = params[:hand].presence
    unless HAND_LABELS.key?(player_hand)
      redirect_to new_battle_path(player_id: @player.id),
                  alert: '手の指定が不正です。'
      return
    end

    cpu_hand = %w[g t p].sample
    result   = JankenJudgeService.resolve(player_hand, cpu_hand)

    buffs_before_player = @battle.buffs_for(:player)

    base_damage = 1
    dmg        = 0
    calc_atk   = nil
    calc_def   = nil

    case result
    when :player_win
      calc_atk = @battle.effective_attack_power(:player, base_damage)
      calc_def = @battle.effective_defense(:enemy, 0)
      dmg      = [calc_atk - calc_def, 0].max
      @battle.damage_enemy!(dmg)
    when :cpu_win
      @battle.damage_player!(1)
    when :draw
      @battle.heal_player!(1)
    end

    @battle.turns_count += 1

    logs = flags['logs'] || []
    logs << {
      'turn' => @battle.turns_count,
      'mode' => (params[:mode] == 'heal' ? 'heal' : 'attack'),
      'player_hand' => player_hand,
      'cpu_hand' => cpu_hand,
      'result' => result.to_s,
      'player_hp' => @battle.player_hp,
      'enemy_hp' => @battle.enemy_hp,
      'first_actor' => @battle.current_priority_side || 'player',
      'damage' => dmg,
      'calc_atk' => calc_atk,
      'calc_def' => calc_def,
      'buffs' => { 'player' => buffs_before_player }
    }
    flags['logs'] = logs

    flags.merge!(
      'player_hand' => player_hand,
      'cpu_hand' => cpu_hand,
      'result' => result
    )

    flags['card_used_in_turn'] = false
    flags['can_janken']        = false

    @battle.flags = flags

    @battle.clear_buff!(side: :player, stat: :attack) if buffs_before_player['attack'].present?

    @battle.advance_priority_turn!
    @battle.tick_buffs!
    @battle.tick_card_ct!

    @battle.save!

    outcome = @battle.check_battle_end!
    update_no_game_over_flag_if_lost(@battle)

    if @battle.won? || @battle.lost?
      redirect_to result_battle_path(@battle)
      return # ★ ここを追加しておくと二重レンダ防止になる
    end

    control_screen
    render :control_screen
  end

  # =========================
  # プレイヤー操作画面
  # =========================
  def control_screen
    @battle ||= Battle.find_by(id: params[:id])
    unless @battle
      redirect_to new_battle_path(player_id: session[:player_id]),
                  alert: 'バトルが見つかりません。'
      return
    end

    @hand     = @battle.flags&.dig('player_hand')
    @cpu_hand = @battle.flags&.dig('cpu_hand')
    @result   = @battle.flags&.dig('result')

    @hand_label     = HAND_LABELS[@hand]     || '未設定'
    @cpu_hand_label = HAND_LABELS[@cpu_hand] || '未設定'

    @result_text =
      case @result&.to_sym
      when :player_win then 'あなたの勝ち！'
      when :cpu_win    then 'あなたの負け…'
      when :draw       then '引き分け（+1回復）'
      else                  'カードまたは手を選んでください'
      end

    @player_hands =
      @battle.battle_hands
             .includes(:card)
             .where(owner_type: :player, owner_id: @battle.player_id, consumed: false)
             .order(:slot_index)
             .limit(6)

    @player_buffs = @battle.buffs_for(:player)
    @can_janken   = @battle.flags&.dig('can_janken') == true
  end

  # =========================
  # /battles/:id → control_screen へ
  # =========================
  def show
    redirect_to control_screen_battle_path(params[:id])
  end

  # =========================
  # カード使用
  # =========================
  def use_battle_card
    @battle = Battle.find_by(id: params[:id])
    unless @battle
      redirect_to new_battle_path(player_id: session[:player_id]),
                  alert: 'バトルが見つかりません。'
      return
    end

    hand = @battle.battle_hands
                  .includes(:card)
                  .where(
                    id: params[:hand_id],
                    owner_type: :player,
                    owner_id: @battle.player_id,
                    consumed: false
                  )
                  .first

    unless hand
      redirect_to control_screen_battle_path(@battle),
                  alert: '使用できるカードがありません。'
      return
    end

    card = hand.card

    if card.element_id.nil? && @battle.turns_count.positive?
      redirect_to control_screen_battle_path(@battle),
                  alert: '無属性カードは戦闘前にしか使えません。'
      return
    end

    flags = (@battle.flags || {}).deep_dup

    if flags['card_used_in_turn']
      redirect_to control_screen_battle_path(@battle),
                  alert: 'このターンではすでにカードを使っています。'
      return
    end

    ct = @battle.card_ct_for(hand.id)
    if ct > 0
      redirect_to control_screen_battle_path(@battle),
                  alert: "このカードはあと #{ct} ターン使用できません。"
      return
    end

    CardEffectApplier.apply(battle: @battle, card: card)

    hand.update!(consumed: true) if card.element_id.nil?

    @battle.reload
    flags = (@battle.flags || {}).deep_dup

    flags['card_used_in_turn'] = true
    flags['can_janken']        = true

    logs = flags['logs'] || []
    logs << {
      'turn' => 0,
      'mode' => 'pre_card_use',
      'card_id' => card.id,
      'card_name' => card.name,
      'player_hp' => @battle.player_hp,
      'enemy_hp' => @battle.enemy_hp,
      'buffs' => { 'player' => @battle.buffs_for(:player) }
    }
    flags['logs'] = logs

    @battle.flags = flags
    @battle.set_card_ct!(hand.id, 3)
    @battle.save!

    # ★ ここも redirect_to ではなく render
    control_screen
    render :control_screen
  end

  # =========================
  # リザルト
  # =========================
  def result
    @battle = Battle.find_by(id: params[:id])
    unless @battle
      redirect_to new_battle_path(player_id: session[:player_id]),
                  alert: 'バトルが見つかりません。'
      return
    end

    if @battle.ongoing?
      redirect_to control_screen_battle_path(@battle)
      return
    end

    logs = (@battle.flags || {})['logs'] || []

    @turns_count = @battle.turns_count
    @win_count   = logs.count { |log| log['result'] == 'player_win' }
    @lose_count  = logs.count { |log| log['result'] == 'cpu_win' }
    @draw_count  = logs.count { |log| log['result'] == 'draw' }
  end

  private

  def update_no_game_over_flag_if_lost(battle)
    return unless battle.lost?

    player = battle.player
    return unless player

    progress =
      StoryProgress.find_or_create_by!(player: player) do |sp|
        sp.current_step = 'npc_talk'
        sp.flags        = {
          'talk_logs' => [],
          'no_game_over' => true
        }
      end

    flags = (progress.flags || {}).dup
    flags['no_game_over'] = false

    progress.update!(flags: flags)
  end
end
