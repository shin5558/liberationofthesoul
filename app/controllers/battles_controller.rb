class BattlesController < ApplicationController
  def new
    @player = Player.find_by(id: params[:player_id])
    # ここで flash は設定しない
  end

  def create
    # 仮のバトル処理
    @player = Player.find_by(id: params[:player_id])

    # TODO: 本実装では Battle モデルを保存予定
    # 今は仮の結果をセット
    flash[:notice] = 'バトルが開始されました！'
    redirect_to battle_path(id: 1) # 仮で show に飛ばす（まだDB未接続）
  end

  def show
    # 仮の表示（Battleモデル作成後に置き換え）
    @battle_result = '勝利！'
  end
end
