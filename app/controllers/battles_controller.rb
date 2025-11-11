class BattlesController < ApplicationController
  def new
    # 後でプレイヤー情報や対戦処理をここに入れる
  end

  def create
    # 仮でトップに戻す（後で対戦処理実装）
    redirect_to root_path, notice: 'バトルを開始しました。'
  end
end
