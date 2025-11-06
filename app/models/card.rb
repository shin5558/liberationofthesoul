class Card < ApplicationRecord
  belongs_to :element
  has_many :card_effects, dependent: :destroy
  has_many :effects, through: :card_effects

  enum hand_type: { g: 0, t: 1, p: 2 } # グー/チョキ/パー
  validates :name, presence: true
  validates :power, :rarity, numericality: { only_integer: true }
end
