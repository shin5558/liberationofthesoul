class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards do |t|
      t.string :name, null: false
      t.references :element, foreign_key: true
      t.integer :hand_type, null: false, default: 0 # 0:g 1:t 2:p
      t.integer :power, null: false, default: 1
      t.integer :rarity, null: false, default: 0
      t.text    :description
      t.timestamps
    end
  end
end
