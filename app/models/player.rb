require 'mini_magick'

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
  has_one_attached :gift_card_image        # 追加：キャラクターカード画像
  has_one_attached :gift_letter_image      # 追加：ルナリアの手紙画像
  has_one_attached :gift_letter_pdf
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

  # =========================
  # ★ キャラクターカード画像を作って attach
  # =========================
  def generate_gift_letter!
    # ① プレイヤーが送った「最後のメッセージ」
    user_message = (meta['true_ending_message'] || '').to_s.strip

    player_name =
      name_kana.presence ||
      name.presence ||
      'あなた'

    # ② OpenAI に投げるプロンプトを組み立て
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

    # ③ OpenAI に問い合わせて手紙本文を生成
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

      # 失敗したときの予備テキスト
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

    # 念のため空ならフォールバック
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

    # ③.5 ここで改行と「\\n」問題を正規化してから、
    #      文字数で折り返しする
    normalized_body = normalize_letter_body(letter_body)
    wrapped_body    = wrap_letter_text(normalized_body, 18) # ← 1行18文字くらいで折り返し

    # ④ 便箋背景
    bg_path = Rails.root.join('app', 'assets', 'images', 'gifts', 'letter_bg.png')
    unless File.exist?(bg_path)
      Rails.logger.warn("[GIFT_LETTER] 背景がありません: #{bg_path}")
      return
    end

    # ⑤ 出力先
    out_dir = Rails.root.join('tmp', 'gifts')
    FileUtils.mkdir_p(out_dir)
    out_path = out_dir.join("player_#{id}_letter.png")

    image = MiniMagick::Image.open(bg_path.to_s)

    # 改行とクォートを escape（ImageMagick 用）
    draw_text =
      wrapped_body
      .gsub('\\', '\\\\\\') # バックスラッシュ
      .gsub("'",  "\\\\'")  # シングルクォート
      .gsub("\n", '\\n')    # 改行 → \n（ここは最後）

    # macOS の日本語フォント候補
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

  # =========================
  # 補助：自動改行関数
  # =========================
  def wrap_text(text, width = 20)
    text.split("\n").map do |line|
      line.scan(/.{1,#{width}}/)
    end.join("\n")
  end

  def generate_gift_letter_pdf!
    # 画像がまだ無ければ先につくる
    generate_gift_letter! unless gift_letter_image.attached?

    require 'prawn'

    out_dir = Rails.root.join('tmp', 'gifts')
    FileUtils.mkdir_p(out_dir)
    out_path = out_dir.join("player_#{id}_letter.pdf")

    Prawn::Document.generate(out_path.to_s) do |pdf|
      begin
        pdf.font_families.update('GenYoMin' => {
                                   normal: '/System/Library/Fonts/ヒラギノ明朝 ProN.ttc'
                                 })
      rescue StandardError
        nil
      end

      begin
        pdf.font('GenYoMin')
      rescue StandardError
        nil
      end

      pdf.text 'ルナリアからの手紙', size: 22
      pdf.move_down 20

      text = meta['true_ending_message'].presence || 'ここまで一緒に旅をしてくれてありがとう。'
      pdf.text text, size: 14
      pdf.move_down 20

      pdf.text 'ルナリアより', size: 16, align: :right
    end

    # ActiveStorage に PDF を attach したいなら、
    # もし gift_letter_pdf みたいな別の attachment を用意していればそこに attach。
    # 今はとりあえずファイルだけ作っておいて、
    # /gifts/:player_id ビューから `link_to` で直接ダウンロードする、でもOK。
  end

  # =========================
  # （必要なら残す）tmp からカードを attach するだけ版
  # =========================
  def attach_gift_card_from_tmp!
    path = Rails.root.join('tmp', 'gifts', "player_#{id}_card.png")

    unless File.exist?(path)
      Rails.logger.warn("[GIFT_CARD] not found: #{path}")
      return
    end

    gift_card_image.attach(
      io: File.open(path),
      filename: "player_#{id}_card.png",
      content_type: 'image/png'
    )
  end

  # =========================
  # ルナリアの手紙画像を tmp から attach
  # （手紙はあとで generate_xxx! 版を作ってもOK）
  # =========================
  def attach_gift_letter_from_tmp!
    path = Rails.root.join('tmp', 'gifts', "player_#{id}_letter.png")

    unless File.exist?(path)
      Rails.logger.warn("[GIFT_LETTER] not found: #{path}")
      return
    end

    gift_letter_image.attach(
      io: File.open(path),
      filename: "player_#{id}_letter.png",
      content_type: 'image/png'
    )
  end
end

private

# GPT の返事に混ざる改行コードを正規化
def normalize_letter_body(text)
  t = text.to_s

  # \r\n, \r を \n にそろえる
  t = t.gsub(/\r\n?/, "\n")
  # 文字としての "\n" も改行に変換
  t = t.gsub('\\n', "\n")

  t.strip
end

# 全角ベースでだいたい max_chars ごとに改行を入れる
def wrap_letter_text(text, max_chars = 18)
  lines = []

  text.to_s.each_line do |raw_line|
    line = raw_line.chomp
    buf  = ''

    line.chars.each do |ch|
      if buf.length >= max_chars
        lines << buf
        buf = ''
      end
      buf << ch
    end

    lines << buf unless buf.empty?
  end

  lines.join("\n")
end
