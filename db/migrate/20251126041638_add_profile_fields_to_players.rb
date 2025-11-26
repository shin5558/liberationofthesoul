class AddProfileFieldsToPlayers < ActiveRecord::Migration[7.1]
  def change
    # すでにあるカラムはスキップするようにしておく

    add_column :players, :name_kana, :string unless column_exists?(:players, :name_kana)

    add_column :players, :gender, :integer, null: false, default: 0 unless column_exists?(:players, :gender)

    add_column :players, :personality_summary, :text unless column_exists?(:players, :personality_summary)

    return if column_exists?(:players, :avatar_image_url)

    add_column :players, :avatar_image_url, :string

    # element_id はすでにある前提なので、ここでは触らない
  end
end
