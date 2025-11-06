class Enemy < ApplicationRecord
  belongs_to :element
  has_many :battles, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :base_hp, numericality: { only_integer: true, greater_than: 0 }
  after_initialize { self.flags ||= {} }
end
