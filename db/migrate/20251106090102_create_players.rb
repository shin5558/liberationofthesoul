class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.references :element, foreign_key: true
      t.integer :base_hp, null: false, default: 5
      t.json    :meta, null: false
      t.timestamps
    end
  end
end
