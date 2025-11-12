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
class NpcLine < ApplicationRecord
  belongs_to :npc_character
  belongs_to :effect, optional: true

  enum context: { intro: 0, rule: 1, hint: 2, win: 3, lose: 4, draw: 5, system: 6 }
  validates :text, presence: true
end
