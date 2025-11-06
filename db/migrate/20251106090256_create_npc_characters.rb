class CreateNpcCharacters < ActiveRecord::Migration[7.1]
  def change
    create_table :npc_characters do |t|
      t.string :name, null: false
      t.string :role
      t.references :element, foreign_key: true
      t.timestamps
    end
  end
end
