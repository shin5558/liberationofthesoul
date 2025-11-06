class BattleTurn < ApplicationRecord
  belongs_to :battle
  has_many :battle_actions, dependent: :destroy

  enum player_hand_type: { g: 0, t: 1, p: 2 }, _prefix: :player
  enum enemy_hand_type:  { g: 0, t: 1, p: 2 }, _prefix: :enemy
  enum first_attacker:   { player: 0, enemy: 1, zone: 2 }
  enum outcome:          { player_win: 0, enemy_win: 1, draw: 2 }
end
