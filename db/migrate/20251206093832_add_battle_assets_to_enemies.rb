class AddBattleAssetsToEnemies < ActiveRecord::Migration[7.1]
  def change
    add_column :enemies, :background_asset, :string
    add_column :enemies, :battle_bgm_asset, :string
    add_column :enemies, :stand_image_asset, :string
  end
end
