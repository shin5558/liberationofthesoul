# == Schema Information
#
# Table name: battle_turns
#
#  id               :bigint           not null, primary key
#  enemy_hand_type  :integer          not null
#  first_attacker   :integer          default("player"), not null
#  outcome          :integer          default("player_win"), not null
#  player_hand_type :integer          not null
#  resolved_at      :datetime
#  turn_no          :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  battle_id        :bigint           not null
#
# Indexes
#
#  index_battle_turns_on_battle_id              (battle_id)
#  index_battle_turns_on_battle_id_and_turn_no  (battle_id,turn_no) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (battle_id => battles.id)
#
require "test_helper"

class BattleTurnTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
