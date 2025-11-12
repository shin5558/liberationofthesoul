class BattlesController < ApplicationController
  def new
    @player = Player.find_by(id: params[:player_id])
    # ここで flash は設定しない
  end

  def create
    # 仮でトップに戻す（後で対戦処理実装）
    redirect_to root_path
  end
end
