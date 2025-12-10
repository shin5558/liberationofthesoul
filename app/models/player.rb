# app/models/player.rb
require 'mini_magick'

class Player < ApplicationRecord
  # ===== 関連 =====
  belongs_to :element, optional: true
  has_many   :battles, dependent: :destroy
  has_one    :story_progress, dependent: :destroy

  # ===== enum =====
  enum gender: { male: 0, female: 1, unknown: 2 }

  # ===== 画像（ActiveStorage）=====
  has_one_attached :avatar_image
  has_one_attached :gift_card_image
  has_one_attached :gift_letter_image
  has_one_attached :gift_letter_pdf
  # ===== バリデーション =====
  validates :name_kana,
            presence: true,
            format: { with: /\A[ァ-ヶー]+\z/, message: 'はカタカナのみで入力してください' }

  validates :name, presence: true, allow_blank: true

  validates :base_hp,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  # ===== JSON 初期化 =====
  after_initialize { self.meta ||= {} }

  # =========================
  # ★ キャラクターカード画像を作って attach
  # =========================
  def generate_gift_card!
    # アバターがないなら何もしない
    return unless avatar_image.attached?

    # 背景（カード台紙）
    bg_path = Rails.root.join('app', 'assets', 'images', 'gifts', 'card_bg.png')
    unless File.exist?(bg_path)
      Rails.logger.warn("[GIFT_CARD] 背景がありません: #{bg_path}")
      return
    end

    # 出力先
    out_dir = Rails.root.join('tmp', 'gifts')
    FileUtils.mkdir_p(out_dir)
    out_path = out_dir.join("player_#{id}_card.png")

    # アバターを一時ファイルに
    avatar_temp = Tempfile.new(["avatar_#{id}", '.png'])
    avatar_temp.binmode
    avatar_temp.write(avatar_image.download)
    avatar_temp.rewind

    bg_img  = MiniMagick::Image.open(bg_path.to_s)
    av_img  = MiniMagick::Image.open(avatar_temp.path)

    av_img.resize '400x400'

    result = bg_img.composite(av_img) do |c|
      c.gravity 'center'
    end

    result.write(out_path.to_s)

    avatar_temp.close!
    avatar_temp.unlink

    gift_card_image.attach(
      io: File.open(out_path),
      filename: "player_#{id}_card.png",
      content_type: 'image/png'
    )

    Rails.logger.info("[GIFT_CARD] attached for player #{id}: #{out_path}")
  end

  # =========================
  # ★ ルナリアの手紙（AI で本文生成 → 画像化）
  # =========================
  def generate_gift_letter!
    user_message = (meta['true_ending_message'] || '').to_s.strip

    player_name =
      name_kana.presence ||
      name.presence ||
      'あなた'

    system_prompt = <<~SYS
      あなたはファンタジー世界の魔姫「ルナリア」として手紙を書く AI です。
      プレイヤーへの感謝と別れ、祈りをこめた日本語の手紙を書いてください。

      制約:
      - 手紙は便箋にそのまま載せる想定
      - 最初は「#{player_name}さんへ」から始める
      - 最後は必ず「ルナリアより」で締める
      - 文体はやさしくて少し切ない感じ
      - 絵文字・顔文字は使わない
      - 全体で 400〜600 文字程度
      - 段落ごとに改行して読みやすくする
    SYS

    user_prompt = <<~USR
      プレイヤー名: #{player_name}
      プレイヤーからの最後のメッセージ: #{user_message.presence || '（メッセージは空欄）'}

      上記のメッセージを受け取ったルナリアとして、
      条件を満たす心のこもった手紙を書いてください。
    USR

    begin
      response = OPENAI_CLIENT.chat(
        parameters: {
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user',   content: user_prompt }
          ],
          temperature: 0.9
        }
      )
      letter_body = response.dig('choices', 0, 'message', 'content').to_s.strip
    rescue StandardError => e
      Rails.logger.error("[GIFT_LETTER_AI] OpenAI error: #{e.class} #{e.message}")
      letter_body = ''
    end

    if letter_body.blank?
      letter_body = <<~FALLBACK
        #{player_name}さんへ

        ここまで一緒に旅をしてくれて、本当にありがとう。
        あなたが選んできたすべての選択が、
        わたしの心を何度も救ってくれました。

        たとえ道が分かれても、
        わたしはいつまでも空の向こうから見守っています。

        ルナリアより
      FALLBACK
    end

    # 便箋
    bg_path = Rails.root.join('app', 'assets', 'images', 'gifts', 'letter_bg.png')
    unless File.exist?(bg_path)
      Rails.logger.warn("[GIFT_LETTER] 背景がありません: #{bg_path}")
      return
    end

    out_dir = Rails.root.join('tmp', 'gifts')
    FileUtils.mkdir_p(out_dir)
    out_path = out_dir.join("player_#{id}_letter.png")

    image = MiniMagick::Image.open(bg_path.to_s)

    draw_text =
      letter_body
      .gsub('\\', '\\\\\\') # バックスラッシュ
      .gsub("'",  "\\\\'")  # シングルクォート
      .gsub("\n", '\\n')    # 改行（ImageMagick 用）

    font_candidates = [
      '/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc',
      '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc',
      '/System/Library/Fonts/ヒラギノ丸ゴ ProN W4.otf'
    ]
    font_path = font_candidates.find { |p| File.exist?(p) }

    Rails.logger.info("[GIFT_LETTER] using font: #{font_path || 'default'}")

    image.combine_options do |c|
      c.gravity   'NorthWest'
      c.pointsize 28
      c.fill      'white'
      c.font font_path if font_path
      c.draw "text 80,180 '#{draw_text}'"
    end

    image.write(out_path.to_s)

    gift_letter_image.attach(
      io: File.open(out_path),
      filename: "player_#{id}_letter.png",
      content_type: 'image/png'
    )

    Rails.logger.info("[GIFT_LETTER] attached for player #{id}: #{out_path}")
  end

  # （必要なら残してOK）
  def attach_gift_card_from_tmp!
    path = Rails.root.join('tmp', 'gifts', "player_#{id}_card.png")
    return unless File.exist?(path)

    gift_card_image.attach(
      io: File.open(path),
      filename: "player_#{id}_card.png",
      content_type: 'image/png'
    )
  end

  def attach_gift_letter_from_tmp!
    path = Rails.root.join('tmp', 'gifts', "player_#{id}_letter.png")
    return unless File.exist?(path)

    gift_letter_image.attach(
      io: File.open(path),
      filename: "player_#{id}_letter.png",
      content_type: 'image/png'
    )
  end
end
