class CreateBattleHands < ActiveRecord::Migration[7.1]
  def change
    create_table :battle_hands do |t|
      t.references :battle, null: false, foreign_key: true
      t.integer :owner_type, null: false, default: 0 # 0:player 1:enemy
      t.bigint  :owner_id, null: false
      t.references :card, null: false, foreign_key: true
      t.integer :slot_index, null: false, default: 0
      t.boolean :consumed, null: false, default: false
      t.timestamps
    end
    add_index :battle_hands, %i[battle_id owner_type owner_id slot_index], unique: true, name: :idx_bh_owner_slot
  end
end
