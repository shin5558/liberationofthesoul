class CharacterImageGenerator
  def self.call(player:, talk_logs:)
    new(player, talk_logs).call
  end

  def initialize(player, talk_logs)
    @player = player
    @talk_logs = talk_logs
  end

  # 戻り値: 画像URL（保存に応じて書き換え）
  def call
    prompt = build_prompt

    # ==== 擬似 OpenAI 画像生成 ====
    # client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    # img_res = client.images.generate(
    #   model: "gpt-image-1",
    #   prompt: prompt,
    #   size: "1024x1024"
    # )
    # image_b64 = img_res.dig("data", 0, "b64_json")
    # # ここで Base64 をファイルに保存して URL を返す or S3 にアップロードして URL を返す
    # image_url
    # ===============================

    # 今はダミーURLを返す（あとで本物の保存処理に差し替え）
    '/images/dummy_player_avatar.png'
  end

  private

  def build_prompt
    element_name = @player.element&.name || 'Neutral'
    gender = @player.gender
    personality = @player.personality_summary.to_s

    <<~PROMPT
      Create a full-body anime-style JRPG character illustration.

      Name: #{@player.name_kana}
      Gender: #{gender}
      Element: #{element_name}
      Personality: #{personality}

      Visual style:
      - High-quality Japanese RPG character art
      - Clear lines, cel shading
      - Reflect the element visually:
        * Fire: red/orange, flame motifs
        * Water: blue, fluid motifs
        * Wind: green, light clothing
        * Earth: brown, sturdy armor
        * Light: white/gold, holy aura
        * Dark: purple/black, mysterious aura

      No text in the image.
    PROMPT
  end
end
