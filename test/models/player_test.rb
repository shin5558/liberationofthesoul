# == Schema Information
#
# Table name: players
#
#  id                  :bigint           not null, primary key
#  avatar_image_url    :string(255)
#  base_hp             :integer          default(5), not null
#  gender              :integer          default("male"), not null
#  meta                :json             not null
#  name                :string(255)      not null
#  name_kana           :string(255)
#  personality_summary :text(65535)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  element_id          :bigint
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
