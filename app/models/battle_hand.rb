class BattleHand < ApplicationRecord
  belongs_to :battle
  belongs_to :card

  # 所有者（プレイヤー or 敵）を多態関連で表現
  belongs_to :owner, polymorphic: true

  enum owner_type: { player: 0, enemy: 1 }, _prefix: :owner
  validates :slot_index, numericality: { only_integer: true }
end
