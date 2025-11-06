class CreateNpcLines < ActiveRecord::Migration[7.1]
  def change
    create_table :npc_lines do |t|
      t.references :npc_character, null: false, foreign_key: true
      t.integer :context, null: false, default: 0 # intro/rule/hint/win/lose/draw/system
      t.text    :text, null: false
      t.references :effect, foreign_key: true
      t.timestamps
    end
  end
end
