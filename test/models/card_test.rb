# == Schema Information
#
# Table name: cards
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  hand_type   :integer          default("g"), not null
#  name        :string(255)      not null
#  power       :integer          default(1), not null
#  rarity      :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  element_id  :bigint
#
# Indexes
#
#  index_cards_on_element_id  (element_id)
#
# Foreign Keys
#
#  fk_rails_...  (element_id => elements.id)
#
require "test_helper"

class CardTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
