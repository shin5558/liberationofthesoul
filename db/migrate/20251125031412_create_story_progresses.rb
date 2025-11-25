class CreateStoryProgresses < ActiveRecord::Migration[7.1]
  def change
    create_table :story_progresses do |t|
      t.references :player, null: false, foreign_key: true
      t.string :current_step, null: false, default: 'prologue'
      t.json :flags, null: false # ← default: {} を消した
      t.timestamps
    end
  end
end
