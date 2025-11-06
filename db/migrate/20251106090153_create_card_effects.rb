class CreateCardEffects < ActiveRecord::Migration[7.1]
  def change
    create_table :card_effects do |t|
      t.references :card,   null: false, foreign_key: true
      t.references :effect, null: false, foreign_key: true
      t.float    :magnitude, default: 1.0
      t.integer  :order_in_card, null: false, default: 0
    end
    add_index :card_effects, %i[card_id effect_id], unique: true
  end
end
