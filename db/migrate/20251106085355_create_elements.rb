class CreateElements < ActiveRecord::Migration[7.1]
  def change
    create_table :elements do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.timestamps
    end
    add_index :elements, :code, unique: true
  end
end
