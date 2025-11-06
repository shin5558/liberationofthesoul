class Effect < ApplicationRecord
  has_many :card_effects, dependent: :destroy
  has_many :cards, through: :card_effects

  # 例：attack/heal/buff/debuff/special
  enum kind: { attack: 0, heal: 1, buff: 2, debuff: 3, special: 4 }
  validates :name, presence: true
  validates :priority, :duration_turns, numericality: { only_integer: true }
end
