# == Schema Information
#
# Table name: battle_hands
#
#  id         :bigint           not null, primary key
#  consumed   :boolean          default(FALSE), not null
#  owner_type :integer          default("player"), not null
#  slot_index :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  battle_id  :bigint           not null
#  card_id    :bigint           not null
#  owner_id   :bigint           not null
#
# Indexes
#
#  idx_bh_owner_slot                (battle_id,owner_type,owner_id,slot_index) UNIQUE
#  index_battle_hands_on_battle_id  (battle_id)
#  index_battle_hands_on_card_id    (card_id)
#
# Foreign Keys
#
#  fk_rails_...  (battle_id => battles.id)
#  fk_rails_...  (card_id => cards.id)
#
class BattleHand < ApplicationRecord
  belongs_to :battle
  belongs_to :card

  enum owner_type: { player: 0, enemy: 1 }, _prefix: :owner

  # （おまけ）実際のキャラを取りたいとき用の helper
  def owner
    case owner_type.to_sym
    when :player then battle.player
    when :enemy  then battle.enemy
    end
  end

  validates :slot_index, numericality: { only_integer: true }
end
