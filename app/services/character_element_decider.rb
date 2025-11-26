class CharacterElementDecider
  ELEMENT_CODES = %w[Fire Water Wind Earth Light Dark Neutral].freeze

  def self.call(player:, talk_logs:)
    new(player, talk_logs).call
  end

  def initialize(player, talk_logs)
    @player = player
    @talk_logs = talk_logs
  end

  def call
    # プレイヤーの発言だけ抜く
    player_text = @talk_logs
                  .select { |l| l['speaker'] == 'player' }
                  .map { |l| l['content'] }
                  .join("\n")

    # ==== 擬似 OpenAI 呼び出し ====
    # client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    # prompt = build_prompt(player_text)
    # res = client.chat(...)
    # element_code = ... # "Fire" など
    # personality_text = ... # "情熱的で前向き" など
    # ============================

    # ここでは仮のロジック（あとでAIに差し替え）
    element_code =
      if player_text.include?('熱') || player_text.include?('燃')
        'Fire'
      elsif player_text.include?('落ち着') || player_text.include?('冷静')
        'Water'
      else
        'Neutral'
      end

    personality_text = 'プレイヤーの会話から推定した性格の説明（あとでAIで生成）'

    { element_code: element_code, personality_text: personality_text }
  end

  private

  def build_prompt(player_text)
    <<~PROMPT
      以下は、RPGプレイヤー「#{@player.name_kana}」の発言ログです。

      #{player_text}

      1. このプレイヤーのイメージに最も近い属性を、次から1つだけ選んでください:
         Fire, Water, Wind, Earth, Light, Dark, Neutral

      2. プレイヤーの性格や雰囲気を、50文字程度の日本語で説明してください。

      出力は必ず JSON で:
      {"element_code": "Fire", "personality": "〜〜〜"}
    PROMPT
  end
end
