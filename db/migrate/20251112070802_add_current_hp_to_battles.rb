# db/migrate/XXXXXXXXXXXX_add_current_hp_to_battles.rb
class AddCurrentHpToBattles < ActiveRecord::Migration[7.1]
  def change
    add_column :battles, :player_hp, :integer, null: false, default: 5
    add_column :battles, :enemy_hp,  :integer, null: false, default: 5
  end
end
