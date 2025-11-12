# == Schema Information
#
# Table name: battle_actions
#
#  id             :bigint           not null, primary key
#  actor_type     :integer          default("player"), not null
#  damage         :integer
#  heal           :integer
#  notes          :text(65535)
#  priority_value :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  actor_id       :bigint           not null
#  battle_turn_id :bigint           not null
#  card_id        :bigint
#  effect_id      :bigint
#
# Indexes
#
#  idx_ba_turn_priority                    (battle_turn_id,priority_value)
#  index_battle_actions_on_battle_turn_id  (battle_turn_id)
#  index_battle_actions_on_card_id         (card_id)
#  index_battle_actions_on_effect_id       (effect_id)
#
# Foreign Keys
#
#  fk_rails_...  (battle_turn_id => battle_turns.id)
#  fk_rails_...  (card_id => cards.id)
#  fk_rails_...  (effect_id => effects.id)
#
require "test_helper"

class BattleActionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
