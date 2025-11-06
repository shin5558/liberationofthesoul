class CreateBattleActions < ActiveRecord::Migration[7.1]
  def change
    create_table :battle_actions do |t|
      t.references :battle_turn, null: false, foreign_key: true
      t.integer :actor_type, null: false, default: 0 # 0:player 1:enemy
      t.bigint  :actor_id,   null: false
      t.references :card,    foreign_key: true
      t.references :effect,  foreign_key: true
      t.integer :priority_value, null: false, default: 0
      t.integer :damage
      t.integer :heal
      t.text    :notes
      t.timestamps
    end
    add_index :battle_actions, %i[battle_turn_id priority_value], name: :idx_ba_turn_priority
  end
end
