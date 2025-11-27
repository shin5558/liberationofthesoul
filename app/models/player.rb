# == Schema Information
#
# Table name: players
#
#  id                  :bigint           not null, primary key
#  avatar_image_url    :string(255)
#  base_hp             :integer          default(5), not null
#  gender              :integer          default("male"), not null
#  meta                :json             not null
#  name                :string(255)      not null
#  name_kana           :string(255)
#  personality_summary :text(65535)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  element_id          :bigint
#
# Indexes
#
#  index_players_on_element_id  (element_id)
#
# Foreign Keys
#
#  fk_rails_...  (element_id => elements.id)
#
class Player < ApplicationRecord
  # ===== 関連 =====
  belongs_to :element, optional: true          # ← もともとの belongs_to を optional: true に
  has_many   :battles, dependent: :destroy     # ← もともとの関連を維持
  has_one    :story_progress, dependent: :destroy # ← さっき作ったストーリー進行

  # ===== enum =====
  # 性別：男・女・不明
  enum gender: { male: 0, female: 1, unknown: 2 }

  # 画像（ActiveStorage）
  has_one_attached :avatar_image

  # ===== バリデーション =====

  # カタカナ名前（新仕様）
  validates :name_kana,
            presence: true,
            format: { with: /\A[ァ-ヶー]+\z/, message: 'はカタカナのみで入力してください' }

  # 以前の :name の必須チェックは一旦外しておく
  # （フォームで name を入力していないため）
  # validates :name, presence: true

  # HP はこれまでどおり整数・正の数
  validates :name, presence: true, allow_blank: true # name_kana をメインに見てるのでゆるくしてもOK
  validates :base_hp,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  # element は必須ではなくしたのでバリデーションも外す
  # validates :element, presence: true

  # ===== JSON初期化 =====
  # meta カラムがある前提（いままでどおり）
  after_initialize { self.meta ||= {} }
end
