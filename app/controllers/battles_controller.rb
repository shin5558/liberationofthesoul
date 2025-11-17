class BattlesController < ApplicationController
  HAND_LABELS = { 'g' => 'グー', 't' => 'チョキ', 'p' => 'パー' }.freeze

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
        # HP 初期化は Battle の before_validation で base_hp から自動
      )

      # ★ 無属性カードをランダムで1枚配布（この時点では battle は new record じゃないのでOK）
      @battle.assign_random_neutral_card!
      @battle.save!
    end

    # ★ 戦闘前（turns_count == 0）のときだけ、まだ未使用の無属性カードを探す
    @neutral_hand =
      if @battle.turns_count.zero?
        @battle.battle_hands
               .joins(:card)
               .where(
                 owner_type: 'player', # enum の中身が "player" なので文字列でOK
                 consumed: false,
                 cards: { element_id: nil }
               )
               .first
      end
  end

  # 戦闘前に無属性カードを使う（M4-06）
  def use_neutral_card
    @battle = Battle.find_by(id: params[:id]) or begin
      redirect_to new_battle_path(player_id: session[:player_id]),
                  alert: 'バトルが見つかりません。'
      return
    end

    # ★ 開戦後（turns_count > 0）は使用不可
    if @battle.turns_count.positive?
      redirect_to battle_path(@battle), alert: 'カードは戦闘前にしか使えません。'
      return
    end

    # まだ未使用の無属性カードの手札を1枚探す
    hand = @battle.battle_hands
                  .joins(:card)
                  .where(
                    id: params[:hand_id],
                    owner_type: 'player',
                    owner_id: @battle.player_id,
                    consumed: false,
                    cards: { element_id: nil }
                  )
                  .first

    unless hand
      redirect_to new_battle_path(player_id: @battle.player_id),
                  alert: '使用できるカードがありません。'
      return
    end

    card = hand.card

    # ★ カード効果を適用（M3-06 / M4-01 / M4-02 で作ったやつ）
    CardEffectApplier.apply(battle: @battle, card: card)

    # ★ 使用済みにする
    hand.update!(consumed: true)

    # （お好み）ログにも残したければ flags["logs"] に追加
    flags = (@battle.flags || {}).deep_dup
    logs  = flags['logs'] || []
    logs << {
      'turn' => 0, # 戦闘前なので 0 としておく
      'mode' => 'pre_card',
      'card_id' => card.id,
      'card_name' => card.name,
      'player_hp' => @battle.player_hp,
      'enemy_hp' => @battle.enemy_hp
    }
    flags['logs'] = logs
    @battle.flags = flags
    @battle.save!

    redirect_to new_battle_path(player_id: @battle.player_id),
                notice: 'カードを使用しました。'
  end

  def create
    pid = params[:player_id].presence || session[:player_id]
    @player = Player.find_by(id: pid)
    return redirect_to new_character_path, alert: '先にキャラクターを作成してください。' unless @player

    # 進行中バトルを掴む（明示指定があれば優先）
    @battle = Battle.find_by(id: params[:battle_id], player: @player) ||
              Battle.find_by(player: @player, status: :ongoing)
    return redirect_to new_battle_path(player_id: @player.id), alert: 'バトルが見つかりません。' unless @battle

    player_hand = params[:hand].presence
    unless HAND_LABELS.key?(player_hand)
      return redirect_to new_battle_path(player_id: @player.id),
                         alert: '手の指定が不正です。'
    end

    cpu_hand = %w[g t p].sample
    result   = JankenJudgeService.resolve(player_hand, cpu_hand) # :player_win / :cpu_win / :draw

    # --- HP反映 ---
    case result
    when :player_win
      @battle.damage_enemy!(1)       # 敵HP -1（0で勝利）
    when :cpu_win
      @battle.damage_player!(1)      # 自HP -1（0で敗北）
    when :draw
      # ひとまずの処理：双方 +1 回復（上限まで）
      @battle.heal_player!(1)
    end

    # ターン数と履歴フラグを更新
    @battle.turns_count += 1
    # ==== ここから「ログ」追記 ====
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
      'first_actor' => @battle.current_priority_side || 'player' # デフォルトはplayer
    }

    flags['logs'] = logs

    # 「最後の一手」情報も維持
    flags.merge!(
      'player_hand' => player_hand,
      'cpu_hand' => cpu_hand,
      'result' => result
    )

    # ★ ここで先行権ターンを1進める
    @battle.advance_priority_turn!

    @battle.flags = flags
    # ===== ログここまで ======

    @battle.save!

    outcome = @battle.check_battle_end!

    if @battle.won? || @battle.lost?
      # HPが0 → 戦闘終了 → リザルト画面へ
      redirect_to result_battle_path(@battle)
    else
      # まだどちらもHP残っている → 通常のバトル画面（show）へ
      redirect_to battle_path(@battle)
    end
  end

  def show
    @battle = Battle.find_by(id: params[:id]) or
      return redirect_to new_battle_path(player_id: session[:player_id]), alert: 'バトルが見つかりません。'

    # 直近の結果表示用
    @hand        = @battle.flags&.dig('player_hand')
    @cpu_hand    = @battle.flags&.dig('cpu_hand')
    @result      = @battle.flags&.dig('result')

    @hand_label     = HAND_LABELS[@hand]     || '未設定'
    @cpu_hand_label = HAND_LABELS[@cpu_hand] || '未設定'

    @result_text =
      case @result&.to_sym
      when :player_win then 'あなたの勝ち！'
      when :cpu_win    then 'あなたの負け…'
      when :draw       then '引き分け（+1回復）'
      else                  '勝負あり'
      end
  end

  # ===============================
  # ここから新規：リザルト画面
  # ===============================
  def result
    @battle = Battle.find_by(id: params[:id]) or
      return redirect_to(
        new_battle_path(player_id: session[:player_id]),
        alert: 'バトルが見つかりません。'
      )

    # まだ ongoing なら通常の show へ戻す
    return redirect_to(battle_path(@battle)) if @battle.ongoing?

    logs = (@battle.flags || {})['logs'] || []

    @turns_count = @battle.turns_count
    @win_count   = logs.count { |log| log['result'] == 'player_win' }
    @lose_count  = logs.count { |log| log['result'] == 'cpu_win' }
    @draw_count  = logs.count { |log| log['result'] == 'draw' }
  end

  private

  # 無属性カードを1枚ランダム付与
  def assign_random_neutral_card(battle)
    neutral_scope = Card.where(element_id: nil)
    return if neutral_scope.blank?

    card = neutral_scope.sample # Ruby側でランダム選択

    battle.battle_hands.create!(
      card: card,
      owner_type: 'player',
      owner_id: battle.player_id
    )
  end
end
