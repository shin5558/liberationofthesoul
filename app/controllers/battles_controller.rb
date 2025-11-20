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
    pid     = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)
    return redirect_to new_character_path, alert: '先にキャラクターを作成してください。' unless @player

    # 進行中バトルを掴む（明示指定があれば優先）
    @battle = Battle.find_by(id: params[:battle_id], player: @player) ||
              Battle.find_by(player: @player, status: :ongoing)
    return redirect_to new_battle_path(player_id: @player.id), alert: 'バトルが見つかりません。' unless @battle

    player_hand = params[:hand].presence
    unless HAND_LABELS.key?(player_hand)
      return redirect_to battle_path(@battle),
                         alert: '手の指定が不正です。'
    end

    cpu_hand = %w[g t p].sample
    result   = JankenJudgeService.resolve(player_hand, cpu_hand) # :player_win / :cpu_win / :draw

    # --- HP反映（バフ込みダメージ） ---
    base_damage = 1

    case result
    when :player_win
      atk  = @battle.effective_attack_power(:player, base_damage)
      defe = @battle.effective_defense(:enemy, 0)
      dmg  = [atk - defe, 0].max
      @battle.damage_enemy!(dmg)
    when :cpu_win
      @battle.damage_player!(1)
    when :draw
      @battle.heal_player!(1)
    end

    # ターン数と履歴フラグを更新
    @battle.turns_count += 1

    flags = (@battle.flags || {}).deep_dup
    logs  = flags['logs'] || []
    logs << {
      'turn' => @battle.turns_count,
      'mode' => (params[:mode] == 'heal' ? 'heal' : 'attack'),
      'player_hand' => player_hand,
      'cpu_hand' => cpu_hand,
      'result' => result.to_s,
      'player_hp' => @battle.player_hp,
      'enemy_hp' => @battle.enemy_hp,
      'first_actor' => @battle.current_priority_side || 'player'
    }
    flags['logs'] = logs

    # 「最後の一手」情報も維持
    flags.merge!(
      'player_hand' => player_hand,
      'cpu_hand' => cpu_hand,
      'result' => result
    )

    # 先行権・バフのターンを進める
    @battle.advance_priority_turn!
    @battle.tick_buffs!

    @battle.flags = flags
    @battle.save!

    outcome = @battle.check_battle_end!

    if @battle.won? || @battle.lost?
      redirect_to result_battle_path(@battle)
    else
      # ← new に戻らず、そのまま show に戻る
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
      else                  '勝負あり'
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
    @enemy_buffs  = @battle.buffs_for(:enemy)
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

    # 無属性カードは「戦闘前だけ使える」制限をかけたい場合
    if card.element_id.nil? && @battle.turns_count.positive?
      redirect_to battle_path(@battle),
                  alert: '無属性カードは戦闘前にしか使えません。'
      return
    end

    # カード効果適用（バフ／ダメージなど）
    CardEffectApplier.apply(battle: @battle, card: card)

    # 使用済みにする
    hand.update!(consumed: true)

    # ログに残したければここで追加しても OK（省略可）

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
