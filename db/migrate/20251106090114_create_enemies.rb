class CreateEnemies < ActiveRecord::Migration[7.1]
  def change
    create_table :enemies do |t|
      t.string :name, null: false
      t.references :element, foreign_key: true
      t.integer :base_hp, null: false, default: 5
      t.boolean :boss, null: false, default: false
      t.json    :flags, null: false
      t.text    :description
      t.timestamps
    end
  end
end
