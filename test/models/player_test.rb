# == Schema Information
#
# Table name: players
#
#  id         :bigint           not null, primary key
#  base_hp    :integer          default(5), not null
#  meta       :json             not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  element_id :bigint
#
# Indexes
#
#  index_players_on_element_id  (element_id)
#
# Foreign Keys
#
#  fk_rails_...  (element_id => elements.id)
#
require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
