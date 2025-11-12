class BattlesController < ApplicationController
  def new
    @player = Player.find_by(id: params[:player_id])
    # ここで flash は設定しない
  end

  def create
    # 仮のバトル処理
    @player = Player.find_by(id: params[:player_id])
    @hand = params[:hand] # g, t, p のいずれか

    # 仮のCPU手（本実装ではランダム化予定）
    cpu_hand = %w[g t p].sample
    # TODO: CPUの手をランダムに選び、結果判定（次ステップで実装予定）
    flash[:notice] = "あなたの手: #{@hand} を選びました！"
    redirect_to battle_path(id: 1, player_hand: @hand, cpu_hand: cpu_hand)
  end

  def show
    @player_hand = params[:player_hand]
    @cpu_hand = params[:cpu_hand]
  end
end
