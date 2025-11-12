class Battle < ApplicationRecord
  belongs_to :player
  belongs_to :enemy
  has_many :battle_turns, dependent: :destroy
  has_many :battle_hands, dependent: :destroy

  enum status: { ongoing: 0, won: 1, lost: 2, aborted: 3 }
  validates :turns_count, numericality: { only_integer: true }

  after_initialize { self.flags ||= {} }
  before_validation :init_hp_on_create, on: :create

  DAMAGE_AMOUNT = 1
  HEAL_AMOUNT   = 1

  # 最大HPは各キャラの base_hp を参照（なければ 5）
  def player_max_hp
    player&.base_hp.presence || 5
  end

  def enemy_max_hp
    enemy&.base_hp.presence || 5
  end

  # --- 回復 ---
  def heal_player!(amount = HEAL_AMOUNT)
    self.player_hp = [player_hp + amount, player_max_hp].min
  end

  # def heal_enemy!(amount = HEAL_AMOUNT)
  #   self.enemy_hp = [enemy_hp + amount, enemy_max_hp].min
  # end

  # --- ダメージ ---
  def damage_player!(amount = DAMAGE_AMOUNT)
    self.player_hp = [player_hp - amount, 0].max
    self.status = :lost if player_hp <= 0
  end

  def damage_enemy!(amount = DAMAGE_AMOUNT)
    self.enemy_hp = [enemy_hp - amount, 0].max
    self.status = :won if enemy_hp <= 0
  end

  private

  def init_hp_on_create
    self.player_hp ||= player_max_hp
    self.enemy_hp ||= enemy_max_hp
    self.turns_count ||= 0
    self.status ||= :ongoing
  end
end
