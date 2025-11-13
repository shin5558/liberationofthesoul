# == Schema Information
#
# Table name: effects
#
#  id             :bigint           not null, primary key
#  duration_turns :integer
#  formula        :text(65535)      not null
#  kind           :integer          default("damage"), not null
#  name           :string(255)      not null
#  priority       :integer          default(0), not null
#  target         :integer          default("player"), not null
#  value          :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Effect < ApplicationRecord
  # 種類: ダメージ or 回復
  enum kind: { damage: 0, heal: 1 }

  # 対象: プレイヤー or 敵
  enum target: { player: 0, enemy: 1 }

  # 数値チェック（value は整数）
  validates :value, numericality: { only_integer: true }

  # もし name や duration_turns に対して他にもバリデーションを入れてるなら
  # それは残してもOKですが、コンソールで作るときに値を渡す必要があります。
end
