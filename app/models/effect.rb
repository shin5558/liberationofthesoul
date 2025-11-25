# == Schema Information
#
# Table name: effects
#
#  id             :bigint           not null, primary key
#  duration_turns :integer
#  formula        :text(65535)      not null
#  kind           :integer          default("heal"), not null
#  name           :string(255)      not null
#  priority       :integer          default(0), not null
#  target         :integer          default("player"), not null
#  value          :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Effect < ApplicationRecord
  enum kind: {
    heal: 0, # HP回復
    damage: 1, # HPダメージ
    buff_attack: 2, # 攻撃バフ
    buff_defense: 3, # 防御バフ
    buff_speed: 4, # 速度バフ
    debuff_attack: 5, # 攻撃デバフ
    debuff_defense: 6, # 防御デバフ
    debuff_speed: 7, # 速度デバフ
    grant_priority: 8 # ★ これを追加
  }

  enum target: {
    player: 0,
    enemy: 1
  }

  # 数値チェック（value は整数）
  validates :value, numericality: { only_integer: true }

  # もし name や duration_turns に対して他にもバリデーションを入れてるなら
  # それは残してもOKですが、コンソールで作るときに値を渡す必要があります。
end
