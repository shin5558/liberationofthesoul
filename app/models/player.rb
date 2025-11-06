class Player < ApplicationRecord
  belongs_to :element
  has_many :battles, dependent: :destroy

  validates :name, presence: true
  validates :base_hp, numericality: { only_integer: true, greater_than: 0 }

  # JSON を空にしたい時は after_initialize で補う（任意）
  after_initialize { self.meta ||= {} }
end
