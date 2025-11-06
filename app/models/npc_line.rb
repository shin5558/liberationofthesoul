class NpcLine < ApplicationRecord
  belongs_to :npc_character
  belongs_to :effect, optional: true

  enum context: { intro: 0, rule: 1, hint: 2, win: 3, lose: 4, draw: 5, system: 6 }
  validates :text, presence: true
end
