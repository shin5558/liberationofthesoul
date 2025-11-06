class Element < ApplicationRecord
  has_many :players,  dependent: :restrict_with_exception
  has_many :enemies,  dependent: :restrict_with_exception
  has_many :cards,    dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
