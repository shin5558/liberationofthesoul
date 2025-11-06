class NpcCharacter < ApplicationRecord
  belongs_to :element
  has_many :npc_lines, dependent: :destroy

  validates :name, :role, presence: true
end
