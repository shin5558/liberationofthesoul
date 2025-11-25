class BattlesController < ApplicationController
  HAND_LABELS = { 'g' => 'グー', 't' => 'チョキ', 'p' => 'パー' }.freeze

  # =========================
  # バトル開始（作成だけして show へ飛ばす）
  # =========================
  def new
    pid     = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)
    unless @player
      redirect_to new_character_path, alert: '先にキャラクターを作成してください。'
      return
    end

    session[:player_id] = @player.id

    # 進行中があればそれを使う。なければここで作る
    @battle = Battle.find_by(player: @player, status: :ongoing)

    unless @battle
      enemy = Enemy.first
      unless enemy
        redirect_to root_path, alert: '敵データがありません。'
        return
      end

      @battle = Battle.create!(
        player: @player,
        enemy: enemy,
        status: :ongoing,
        turns_count: 0,
        flags: {}
      )

      # 無属性カード( slot_index:0 )を1枚配布
      @battle.assign_random_neutral_card!
      # 通常手札 5 枚 (slot_index:1〜5)
      @battle.prepare_initial_hands!
      @battle.save!
    end

    # ここではビューを表示しないで、メイン画面(show)へ
    redirect_to battle_path(@battle)
  end

  # =========================
  # じゃんけん実行（リアルタイム進行）
  # =========================
  def create
    pid = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)
    return redirect_to new_character_path, alert: '先にキャラクターを作成してください。' unless @player

    @battle = Battle.find_by(id: params[:battle_id], player: @player) ||
              Battle.find_by(player: @player, status: :ongoing)
    return redirect_to new_battle_path(player_id: @player.id), alert: 'バトルが見つかりません。' unless @battle

    flags = (@battle.flags || {}).deep_dup

    # ★ 先にカードを使わせたいならここでチェック
    unless flags['can_janken']
      return redirect_to battle_path(@battle),
                         alert: '先にカードを1枚使ってください。'
    end

    player_hand = params[:hand].presence
    unless HAND_LABELS.key?(player_hand)
      return redirect_to new_battle_path(player_id: @player.id),
                         alert: '手の指定が不正です。'
    end

    cpu_hand = %w[g t p].sample
    result   = JankenJudgeService.resolve(player_hand, cpu_hand)

    # このターン開始時点のバフ（ログ用／バフ消去判定用）
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
      'buffs' => {
        'player' => buffs_before_player
      }
    }
    flags['logs'] = logs

    flags.merge!(
      'player_hand' => player_hand,
      'cpu_hand' => cpu_hand,
      'result' => result
    )

    # 次のターン用フラグリセット
    flags['card_used_in_turn'] = false
    flags['can_janken']        = false

    # ここで一旦 flags を反映
    @battle.flags = flags

    # ★ 攻撃バフは「このじゃんけん1回だけ」有効にしたいので、
    #   このターンの攻撃バフがあった場合はここで消す
    @battle.clear_buff!(side: :player, stat: :attack) if buffs_before_player['attack'].present?

    # 先行権、バフの残りターン、カードCTを進める
    @battle.advance_priority_turn!
    @battle.tick_buffs!
    @battle.tick_card_ct!

    @battle.save!

    outcome = @battle.check_battle_end!

    if @battle.won? || @battle.lost?
      redirect_to result_battle_path(@battle)
    else
      redirect_to battle_path(@battle)
    end
  end

  # =========================
  # メイン戦闘画面（じゃんけん＋ログ＋手札）
  # =========================
  def show
    @battle = Battle.find_by(id: params[:id]) or
      return redirect_to(
        new_battle_path(player_id: session[:player_id]),
        alert: 'バトルが見つかりません。'
      )

    # 直近の結果表示用
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

    # ★ プレイヤーの未使用手札を「6枚」まで（0〜5）表示
    @player_hands =
      @battle.battle_hands
             .includes(:card)
             .where(owner_type: :player, owner_id: @battle.player_id, consumed: false)
             .order(:slot_index)
             .limit(6)

    # バフ情報（プレイヤー / 敵）
    @player_buffs = @battle.buffs_for(:player)

    # ★ じゃんけんしていい状態かどうか
    @can_janken = @battle.flags&.dig('can_janken') == true
  end

  # =========================
  # 手札カードを使う（無属性も含む）
  # =========================
  def use_battle_card
    @battle = Battle.find_by(id: params[:id]) or begin
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
      redirect_to battle_path(@battle),
                  alert: '使用できるカードがありません。'
      return
    end

    card = hand.card

    # 無属性カードは「戦闘前だけ使える」制限
    if card.element_id.nil? && @battle.turns_count.positive?
      redirect_to battle_path(@battle),
                  alert: '無属性カードは戦闘前にしか使えません。'
      return
    end

    # ★ このターンですでにカード使用済みなら禁止
    flags = (@battle.flags || {}).deep_dup
    if flags['card_used_in_turn']
      redirect_to battle_path(@battle),
                  alert: 'このターンではすでにカードを使っています。'
      return
    end

    # ★ カードごとのクールタイムチェック
    ct = @battle.card_ct_for(hand.id)
    if ct > 0
      redirect_to battle_path(@battle),
                  alert: "このカードはあと #{ct} ターン使用できません。"
      return
    end

    # カード効果適用（バフ／ダメージ／回復など）
    CardEffectApplier.apply(battle: @battle, card: card)

    # 無属性カードだけ消費したい場合
    hand.update!(consumed: true) if card.element_id.nil?

    # 効果反映後の状態で flags を取り直す
    @battle.reload
    flags = (@battle.flags || {}).deep_dup

    # このターンはカード使用済み & じゃんけん可能
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
      'buffs' => {
        'player' => @battle.buffs_for(:player)
      }
    }
    flags['logs'] = logs

    # ★ 先に flags を全部反映してから CT セット（ここが重要）
    @battle.flags = flags

    # ★ クールタイムを「3」にすると、実質 2ターンの間使えない
    #   ・このターンで使う → CT=3
    #   ・ターン終了で tick_card_ct! により 2
    #   ・次のターン終了で 1
    #   ・次のターン終了で 0 → その次のターンから再使用可
    @battle.set_card_ct!(hand.id, 3)

    @battle.save!

    redirect_to battle_path(@battle),
                notice: 'カードを使用しました。'
  end

  # =========================
  # リザルト画面
  # =========================
  def result
    @battle = Battle.find_by(id: params[:id]) or
      return redirect_to(
        new_battle_path(player_id: session[:player_id]),
        alert: 'バトルが見つかりません。'
      )

    return redirect_to(battle_path(@battle)) if @battle.ongoing?

    logs = (@battle.flags || {})['logs'] || []

    @turns_count = @battle.turns_count
    @win_count   = logs.count { |log| log['result'] == 'player_win' }
    @lose_count  = logs.count { |log| log['result'] == 'cpu_win' }
    @draw_count  = logs.count { |log| log['result'] == 'draw' }
  end

  private

  # （※ assign_random_neutral_card! は Battle モデル側にあるのでここでは使わない）
end
