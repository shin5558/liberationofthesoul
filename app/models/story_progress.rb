# == Schema Information
#
# Table name: story_progresses
#
#  id           :bigint           not null, primary key
#  current_step :string(255)      default("prologue"), not null
#  flags        :json             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  player_id    :bigint           not null
#
# Indexes
#
#  index_story_progresses_on_player_id  (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#

class StoryProgress < ApplicationRecord
  belongs_to :player

  after_initialize do
    self.flags ||= {} # ← JSON default の代わりになる
  end

  # 例: ステップをenum的に管理したかったらここで
  STEPS = %w[
    :character_summary,
    :prologue,
    :branch1_choice,
    :goblin_intro,
    :thief_intro,
    :after_goblin,
    :after_thief,
    :gatekeeper_intro,
    :princess_meeting,
    :gatekeeper_from_princess,
    :general_intro,
    :after_gatekeeper,
    :after_general,
    :warehouse_gate,
    :warehouse_general,
    :demonlord_intro,
    :ending_bad,
    :ending_normal,
    :ending_true
  ].freeze

  def flags_hash
    (flags || {}).with_indifferent_access
  end

  def set_flag(key, value = true)
    f = flags_hash
    f[key] = value
    update!(flags: f)
  end
end
