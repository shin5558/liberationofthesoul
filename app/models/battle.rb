class Battle < ApplicationRecord
  belongs_to :player
  belongs_to :enemy
  has_many :battle_turns, dependent: :destroy
  has_many :battle_hands, dependent: :destroy

  enum status: { ongoing: 0, won: 1, lost: 2, aborted: 3 }
  validates :turns_count, numericality: { only_integer: true }

  after_initialize { self.flags ||= {} }
end
