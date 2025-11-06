class CreateEffects < ActiveRecord::Migration[7.1]
  def change
    create_table :effects do |t|
      t.string  :name, null: false
      t.integer :kind, null: false, default: 0        # attack/heal/buff/debuff/special
      t.integer :priority, null: false, default: 0    # special>heal>buff>attack を数値化
      t.text    :formula, null: false                 # JSON文字列や式
      t.integer :duration_turns
      t.timestamps
    end
  end
end
