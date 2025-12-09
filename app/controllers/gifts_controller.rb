# app/controllers/gifts_controller.rb
class GiftsController < ApplicationController
  def show
    @player = Player.find(params[:player_id])

    # ① キャラカード：なければ tmp から自動 attach（開発 or 手動登録用）
    return if @player.gift_card_image.attached?

    @player.attach_gift_card_from_tmp!

    # ② ルナリアの手紙：これは真エンド後、自動生成で attach する想定
    #   （ここでは「足りなければ tmp から読み込む」くらいの開発用にしてもOK）
    # unless @player.gift_letter_image.attached?
    #   @player.attach_gift_letter_from_tmp!
    # end
  end
end
