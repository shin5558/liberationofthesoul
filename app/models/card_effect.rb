class CardEffect < ApplicationRecord
  belongs_to :card
  belongs_to :effect

  validates :magnitude, numericality: true
  validates :order_in_card, numericality: { only_integer: true }
end
