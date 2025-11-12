# == Schema Information
#
# Table name: npc_characters
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  role       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  element_id :bigint
#
# Indexes
#
#  index_npc_characters_on_element_id  (element_id)
#
# Foreign Keys
#
#  fk_rails_...  (element_id => elements.id)
#
class NpcCharacter < ApplicationRecord
  belongs_to :element
  has_many :npc_lines, dependent: :destroy

  validates :name, :role, presence: true
end
