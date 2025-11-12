# == Schema Information
#
# Table name: npc_lines
#
#  id               :bigint           not null, primary key
#  context          :integer          default("intro"), not null
#  text             :text(65535)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  effect_id        :bigint
#  npc_character_id :bigint           not null
#
# Indexes
#
#  index_npc_lines_on_effect_id         (effect_id)
#  index_npc_lines_on_npc_character_id  (npc_character_id)
#
# Foreign Keys
#
#  fk_rails_...  (effect_id => effects.id)
#  fk_rails_...  (npc_character_id => npc_characters.id)
#
require "test_helper"

class NpcLineTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
