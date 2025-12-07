# == Schema Information
#
# Table name: enemies
#
#  id                :bigint           not null, primary key
#  background_asset  :string(255)
#  base_hp           :integer          default(5), not null
#  battle_bgm_asset  :string(255)
#  boss              :boolean          default(FALSE), not null
#  code              :string(255)
#  description       :text(65535)
#  flags             :json             not null
#  name              :string(255)      not null
#  stand_image_asset :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  element_id        :bigint
#
# Indexes
#
#  index_enemies_on_code        (code) UNIQUE
#  index_enemies_on_element_id  (element_id)
#
# Foreign Keys
#
#  fk_rails_...  (element_id => elements.id)
#
class Enemy < ApplicationRecord
  belongs_to :element
  has_many :battles, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :base_hp, numericality: { only_integer: true, greater_than: 0 }
  after_initialize { self.flags ||= {} }

  # =========================
  # ここから追加: 背景 / BGM 用 helper
  # =========================

  # 戦闘画面の背景用 CSS クラス名
  # 例: code = "goblin" → "battle-bg-goblin"
  def battle_bg_class
    return 'battle-bg-default' if code.blank?

    "battle-bg-#{code}"
  end

  # BGM のアセットパス
  # 例: app/assets/audios/bgm_goblin.mp3 → "bgm/bgm_goblin.mp3"
  def battle_bgm_asset
    return 'bgm/bgm_default.mp3' if code.blank?

    "bgm/bgm_#{code}.mp3"
  end
end
