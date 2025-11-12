# == Schema Information
#
# Table name: elements
#
#  id         :bigint           not null, primary key
#  code       :string(255)      not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_elements_on_code  (code) UNIQUE
#
class Element < ApplicationRecord
  has_many :players,  dependent: :restrict_with_exception
  has_many :enemies,  dependent: :restrict_with_exception
  has_many :cards,    dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
