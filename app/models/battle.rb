# == Schema Information
#
# Table name: battles
#
#  id          :bigint           not null, primary key
#  ended_at    :datetime
#  enemy_hp    :integer          default(5), not null
#  flags       :json             not null
#  player_hp   :integer          default(5), not null
#  started_at  :datetime
#  status      :integer          default("ongoing"), not null
#  turns_count :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  enemy_id    :bigint           not null
#  player_id   :bigint           not null
#
# Indexes
#
#  index_battles_on_enemy_id   (enemy_id)
#  index_battles_on_player_id  (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (enemy_id => enemies.id)
#  fk_rails_...  (player_id => players.id)
#
class Battle < ApplicationRecord
  belongs_to :player
  belongs_to :enemy
  has_many :battle_turns, dependent: :destroy
  has_many :battle_hands, dependent: :destroy

  enum status: { ongoing: 0, won: 1, lost: 2, aborted: 3 }
  validates :turns_count, numericality: { only_integer: true }

  after_initialize { self.flags ||= {} }

  def init_hp_if_needed!
    self.player_hp = player.base_hp if player_hp.blank?
    self.enemy_hp  = enemy.base_hp  if enemy_hp.blank?
  end

  def apply_damage!(result_symbol, dmg = 1)
    case result_symbol
    when :player_win
      self.enemy_hp -= dmg
      self.status = :won if enemy_hp <= 0
    when :cpu_win
      self.player_hp -= dmg
      self.status = :lost if player_hp <= 0
    when :draw
      # no hp change
    end
  end
end
