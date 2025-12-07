# == Schema Information
#
# Table name: enemies
#
#  id                :bigint           not null, primary key
#  background_asset  :string(255)
#  base_hp           :integer          default(5), not null
#  battle_bgm_asset  :string(255)
#  boss              :boolean          default(FALSE), not null
#  code              :string(255)
#  description       :text(65535)
#  flags             :json             not null
#  name              :string(255)      not null
#  stand_image_asset :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  element_id        :bigint
#
# Indexes
#
#  index_enemies_on_code        (code) UNIQUE
#  index_enemies_on_element_id  (element_id)
#
# Foreign Keys
#
#  fk_rails_...  (element_id => elements.id)
#
require "test_helper"

class EnemyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
