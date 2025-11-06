class CreateBattles < ActiveRecord::Migration[7.1]
  def change
    create_table :battles do |t|
      t.references :player, null: false, foreign_key: true
      t.references :enemy,  null: false, foreign_key: true
      t.integer :status, null: false, default: 0 # ongoing/won/lost/aborted
      t.integer :turns_count, null: false, default: 0
      t.json    :flags, null: false
      t.datetime :started_at
      t.datetime :ended_at
      t.timestamps
    end
  end
end
