class BattleAction < ApplicationRecord
  belongs_to :battle_turn
  belongs_to :card,   optional: true
  belongs_to :effect, optional: true

  # 行為者（プレイヤー/敵）を多態的に
  belongs_to :actor, polymorphic: true

  enum actor_type: { player: 0, enemy: 1 }, _prefix: :actor
  validates :priority_value, numericality: { only_integer: true }
end
