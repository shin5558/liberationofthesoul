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

    cpu_hand = %w[g t p].sample

    # ★ 判定（サービス呼び出し）
    result = JankenJudgeService.resolve(player_hand, cpu_hand)
    # :player_win / :cpu_win / :draw が返る想定

    # :player_win / :cpu_win / :draw → Battle.enum(:status) へ変換
    status_map = {
      player_win: :won,
      cpu_win: :lost,
      draw: :ongoing
    }
    battle_status = status_map.fetch(result)

    @battle = Battle.create!(
      player: @player,
      enemy: Enemy.first,
      status: battle_status,
      turns_count: 1,
      flags: { player_hand: player_hand, cpu_hand: cpu_hand, result: result }
    )

    redirect_to battle_path(@battle, hand: player_hand)
  end

  def show
    @battle = Battle.find_by(id: params[:id])
    unless @battle
      redirect_to new_battle_path(player_id: session[:player_id]),
                  alert: 'バトルが見つかりません。もう一度はじめてください。'
      return
    end

    # URL hand があれば優先、なければ flags から
    @hand        = params[:hand].presence || @battle.flags&.dig('player_hand')
    @cpu_hand    = @battle.flags&.dig('cpu_hand') || 't'

    @hand_label     = HAND_LABELS[@hand]     || '未設定'
    @cpu_hand_label = HAND_LABELS[@cpu_hand] || '未設定'

    # 画面で勝敗テキストを使いたいときに参照できるよう残す
    @result = @battle.flags&.dig('result') # :player_win / :cpu_win / :draw

    # ★ 結果文言
    @result_text =
      case @result&.to_sym
      when :player_win then 'あなたの勝ち！'
      when :cpu_win    then 'あなたの負け…'
      when :draw       then '引き分けです。'
      else                  '判定不能'
      end
  end
end
