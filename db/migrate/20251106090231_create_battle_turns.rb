class CreateBattleTurns < ActiveRecord::Migration[7.1]
  def change
    create_table :battle_turns do |t|
      t.references :battle, null: false, foreign_key: true
      t.integer :turn_no, null: false
      t.integer :player_hand_type, null: false        # 0:g 1:t 2:p
      t.integer :enemy_hand_type,  null: false        # 0:g 1:t 2:p
      t.integer :first_attacker, null: false, default: 0  # 0:player 1:enemy 2:none
      t.integer :outcome, null: false, default: 0         # 0:player_win 1:enemy_win 2:draw
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :battle_turns, %i[battle_id turn_no], unique: true
  end
end
