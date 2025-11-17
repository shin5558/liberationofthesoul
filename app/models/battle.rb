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

  # ★ ここに「戦闘終了チェック」を追加
  # 戻り値 :ongoing / :win / :lose
  def check_battle_end!
    if player_hp <= 0
      self.status = :lost
      self.flags  = (flags || {}).merge('result' => 'lose')
      save!
      :lose
    elsif enemy_hp <= 0
      self.status = :won
      self.flags  = (flags || {}).merge('result' => 'win')
      save!
      :win
    else
      :ongoing
    end
  end

  # =========================
  # ここからバフ／デバフ関連
  # =========================

  # flags に保存しているバフ情報を取得
  # side: :player / :enemy
  def buffs_for(side)
    (flags || {}).dig('buffs', side.to_s) || {}
  end

  # バフを追加（攻撃／防御／速度など）
  # side   : :player or :enemy
  # stat   : :attack / :defense / :speed など
  # amount : +1, -1 などの補正値
  # duration_turns : 何ターン残すか
  def add_buff!(side:, stat:, amount:, duration_turns:)
    f = (flags || {}).deep_dup
    f['buffs'] ||= {}
    f['buffs'][side.to_s] ||= {}

    current = f['buffs'][side.to_s][stat.to_s] || { 'value' => 0, 'turns' => 0 }
    current['value'] += amount
    current['turns']  = [current['turns'], duration_turns.to_i].max

    f['buffs'][side.to_s][stat.to_s] = current
    self.flags = f
  end

  # ターン終了時などに呼んで「残りターン」を1減らす
  # 0 以下になったバフは消す
  def tick_buffs!
    f = (flags || {}).deep_dup
    buffs = f['buffs'] || {}

    buffs.each do |_side, stats|
      stats.each do |_stat, buff|
        buff['turns'] = buff['turns'].to_i - 1
      end
      stats.delete_if { |_stat, buff| buff['turns'] <= 0 }
    end

    buffs.delete_if { |_side, stats| stats.blank? }
    f['buffs'] = buffs
    self.flags = f
  end

  # 攻撃力・防御力などを「バフ込み」で計算したいときに使う helper（例）
  # base には元のダメージ量などを渡す想定
  def effective_attack_power(side, base)
    buffs = buffs_for(side)
    atk_buff = (buffs.dig('attack', 'value') || 0).to_i
    [base + atk_buff, 0].max
  end

  def effective_defense(side, base)
    buffs = buffs_for(side)
    def_buff = (buffs.dig('defense', 'value') || 0).to_i
    [base + def_buff, 0].max
  end

  # ----- ここから追加: 先行権（イニシアチブ）関連 -----

  # 現在の先行側を返す : "player" / "enemy" / nil
  def current_priority_side
    (flags || {}).dig('priority', 'side')
  end

  # 先行権を付与する
  # side: :player / :enemy
  # duration_turns: 何ターン有効にするか
  def grant_priority!(side:, duration_turns: 1)
    self.flags ||= {}
    self.flags['priority'] ||= {}
    self.flags['priority']['side']  = side.to_s
    self.flags['priority']['turns'] = duration_turns.to_i
  end

  # ターン経過時に残りターンを1減らして、0になったら先行権を削除
  def advance_priority_turn!
    pri = (flags || {})['priority']
    return unless pri

    pri['turns'] = pri['turns'].to_i - 1
    if pri['turns'] <= 0
      flags.delete('priority')
    else
      flags['priority'] = pri
    end
  end

  # ----- ここまで追加 -----

  private

  def init_hp_on_create
    self.player_hp ||= player_max_hp
    self.enemy_hp ||= enemy_max_hp
    self.turns_count ||= 0
    self.status ||= :ongoing
  end
end
