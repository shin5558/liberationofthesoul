# app/services/gifts/character_card_generator.rb
module Gifts
  class CharacterCardGenerator
    def initialize(player)
      @player = player
    end

    def call
      # ここで画像合成して io に入れる
      # io = StringIO.new( ... )

      @player.gift_card_image.attach(
        io: io,
        filename: "player_#{@player.id}_card.png",
        content_type: 'image/png'
      )
    end
  end
end
