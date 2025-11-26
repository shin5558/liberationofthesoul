class NpcTalkService
  # talk_logs: [{ "speaker" => "player"/"npc", "content" => "..." }, ...]
  def self.reply(player:, talk_logs:)
    new(player, talk_logs).reply
  end

  def initialize(player, talk_logs)
    @player = player
    @talk_logs = talk_logs
  end

  def reply
    # ここで OpenAI 等を呼び出して NPC の返答を作る
    # 例: system プロンプト + 過去ログ + 今回のプレイヤー発言

    # ==== 擬似コード ====
    # client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    # messages = build_messages
    # res = client.chat(parameters: { model: "gpt-4.1-mini", messages: messages })
    # res.dig("choices", 0, "message", "content")
    # ====================

    # ここでは仮の固定返答（あとでAPI接続に差し替え）
    "なるほど、#{@player.name_kana} はそう考えるんだね。もう少し聞かせてくれる？"
  end

  private

  def build_messages
    system_msg = {
      role: 'system',
      content: 'あなたはファンタジーRPGに登場する優しい案内役NPCです。プレイヤーの性格や雰囲気を知るために、3〜5回ほど会話をします。'
    }

    chat_msgs = @talk_logs.map do |log|
      if log['speaker'] == 'player'
        { role: 'user', content: log['content'] }
      else
        { role: 'assistant', content: log['content'] }
      end
    end

    [system_msg, *chat_msgs]
  end
end
