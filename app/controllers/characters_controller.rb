class CharactersController < ApplicationController
  def new
    # Player 作成フォーム用のインスタンス
    @player = Player.new
    @elements = Element.all
  end

  def create
    @player = Player.new(player_params)
    @player.base_hp = 5 # 初期HPを固定値でセット
    @player.meta = {} # 空のJSONデータ（将来の拡張用）

    if @player.save # ここで中間ページに渡す遷移先を用意
      @redirect_url = new_battle_path(player_id: @player.id)
      render :created, status: :ok
    else
      flash.now[:alert] = '作成に失敗しました。入力内容をご確認ください。'
      @elements = Element.all
      render :new, status: :unprocessable_entity
    end
  end

  private

  def player_params
    params.require(:player).permit(:name, :element_id)
  end
end
