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
    return if @battle

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
      'enemy_hp' => @battle.enemy_hp
    }

    flags['logs'] = logs

    # 「最後の一手」情報も維持
    flags.merge!(
      'player_hand' => player_hand,
      'cpu_hand' => cpu_hand,
      'result' => result
    )

    @battle.flags = flags
    # ===== ログここまで ======

    @battle.save!

    outcome = @battle.check_battle_end!

    redirect_to battle_path(@battle), notice: outcome == :ongoing ? nil : 'バトル終了！'
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
end
