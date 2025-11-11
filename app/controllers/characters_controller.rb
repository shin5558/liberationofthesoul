class CharactersController < ApplicationController
  def new
    # Player 作成フォーム用のインスタンス
    @player = Player.new(base_hp: 5) # 見た目上の初期値。DBにdefaultがあるなら省略可
    @elements = Element.order(:id)
  end

  def create
    @player = Player.new(player_params)
    @player.base_hp ||= 5 # 念のための保険。マイグレーションで default: 5 があれば不要
    @elements = Element.order(:id)

    if @player.save
      # TODO: 現状は暫定的にトップへ戻す。後でバトル開始画面へ遷移予定。
      redirect_to root_path, notice: "キャラクター「#{@player.name}」を作成しました。"
    else
      flash.now[:alert] = '作成に失敗しました。入力内容をご確認ください。'
      render :new, status: :unprocessable_entity
    end
  end

  private

  def player_params
    # フォームの scope を :character にする想定
    params.require(:character).permit(:name, :element_id)
  end
end
