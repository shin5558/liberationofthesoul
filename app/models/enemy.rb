# == Schema Information
#
# Table name: enemies
#
#  id          :bigint           not null, primary key
#  base_hp     :integer          default(5), not null
#  boss        :boolean          default(FALSE), not null
#  code        :string(255)
#  description :text(65535)
#  flags       :json             not null
#  name        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  element_id  :bigint
#
# Indexes
#
#  index_enemies_on_code        (code) UNIQUE
#  index_enemies_on_element_id  (element_id)
#
# Foreign Keys
#
#  fk_rails_...  (element_id => elements.id)
#
class Enemy < ApplicationRecord
  belongs_to :element
  has_many :battles, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :base_hp, numericality: { only_integer: true, greater_than: 0 }
  after_initialize { self.flags ||= {} }
end
