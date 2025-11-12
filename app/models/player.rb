# == Schema Information
#
# Table name: players
#
#  id         :bigint           not null, primary key
#  base_hp    :integer          default(5), not null
#  meta       :json             not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  element_id :bigint
#
# Indexes
#
#  index_players_on_element_id  (element_id)
#
# Foreign Keys
#
#  fk_rails_...  (element_id => elements.id)
#
class Player < ApplicationRecord
  belongs_to :element
  has_many :battles, dependent: :destroy

  validates :name, presence: true
  validates :element, presence: true # 念のため明示
  validates :base_hp, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # JSON を空にしたい時は after_initialize で補う（任意）
  after_initialize { self.meta ||= {} }
end
