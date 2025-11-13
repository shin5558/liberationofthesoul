class AddKindTargetValueToEffects < ActiveRecord::Migration[7.1]
  def change
    # すでにカラムがある場合はスキップするようにする
    add_column :effects, :kind,   :integer, null: false, default: 0 unless column_exists?(:effects, :kind)
    add_column :effects, :target, :integer, null: false, default: 0 unless column_exists?(:effects, :target)
    add_column :effects, :value,  :integer, null: false, default: 0 unless column_exists?(:effects, :value)
  end
end
