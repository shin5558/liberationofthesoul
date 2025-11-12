# == Schema Information
#
# Table name: battles
#
#  id          :bigint           not null, primary key
#  ended_at    :datetime
#  enemy_hp    :integer          default(5), not null
#  flags       :json             not null
#  player_hp   :integer          default(5), not null
#  started_at  :datetime
#  status      :integer          default("ongoing"), not null
#  turns_count :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  enemy_id    :bigint           not null
#  player_id   :bigint           not null
#
# Indexes
#
#  index_battles_on_enemy_id   (enemy_id)
#  index_battles_on_player_id  (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (enemy_id => enemies.id)
#  fk_rails_...  (player_id => players.id)
#
require "test_helper"

class BattleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
