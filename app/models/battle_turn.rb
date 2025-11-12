# == Schema Information
#
# Table name: battle_turns
#
#  id               :bigint           not null, primary key
#  enemy_hand_type  :integer          not null
#  first_attacker   :integer          default("player"), not null
#  outcome          :integer          default("player_win"), not null
#  player_hand_type :integer          not null
#  resolved_at      :datetime
#  turn_no          :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  battle_id        :bigint           not null
#
# Indexes
#
#  index_battle_turns_on_battle_id              (battle_id)
#  index_battle_turns_on_battle_id_and_turn_no  (battle_id,turn_no) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (battle_id => battles.id)
#
class BattleTurn < ApplicationRecord
  belongs_to :battle
  has_many :battle_actions, dependent: :destroy

  enum player_hand_type: { g: 0, t: 1, p: 2 }, _prefix: :player
  enum enemy_hand_type:  { g: 0, t: 1, p: 2 }, _prefix: :enemy
  enum first_attacker:   { player: 0, enemy: 1, zone: 2 }
  enum outcome:          { player_win: 0, enemy_win: 1, draw: 2 }
end
