class AddCodeToEnemies < ActiveRecord::Migration[7.1]
  def change
    add_column :enemies, :code, :string
    add_index  :enemies, :code, unique: true
  end
end
