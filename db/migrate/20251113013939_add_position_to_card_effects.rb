class AddPositionToCardEffects < ActiveRecord::Migration[7.1]
  def change
    add_column :card_effects, :position, :integer
  end
end
