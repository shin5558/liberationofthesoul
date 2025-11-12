class BattlesController < ApplicationController
  def new
    @player = Player.find_by(id: params[:player_id])
    # ここで flash は設定しない
  end

  def create
    # 仮のバトル処理
    @player = Player.find_by(id: params[:player_id])
    @hand = params[:hand] # g, t, p のいずれか

    # TODO: CPUの手をランダムに選び、結果判定（次ステップで実装予定）
    flash[:notice] = "あなたの手: #{@hand} を選びました！"
    redirect_to battle_path(id: 1) # 仮
  end

  def show
    # 仮の表示（Battleモデル作成後に置き換え）
    @battle_result = '勝利！'
  end
end
