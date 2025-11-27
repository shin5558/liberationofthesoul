class StoriesController < ApplicationController
  before_action :require_player!
  before_action :set_player_and_progress
  require 'base64'
  require 'stringio'
  # =========================
  # NPC会話 1: 画面表示
  # =========================
  def npc_intro
    flags = @story_progress.flags || {}
    @talk_logs = flags['talk_logs'] || []

    last_npc = @talk_logs.reverse.find { |log| log['role'] == 'assistant' }

    @npc_message =
      if last_npc
        last_npc['content']
      else
        "はじめまして、#{@player.name_kana}。これから何問か質問をするね。気楽に答えてほしい。"
      end
  end

  # =========================
  # NPC会話 2: 発言送信（POST）
  # =========================
  def npc_talk
    flags     = (@story_progress.flags || {}).deep_dup
    talk_logs = flags['talk_logs'] || []

    player_message = params[:player_message].to_s.strip
    if player_message.blank?
      redirect_to npc_intro_story_path, alert: '何か話してみてください。'
      return
    end

    talk_logs << { 'role' => 'user', 'content' => player_message }

    system_prompt = <<~SYS
      あなたは物語世界の案内役NPCです。
      プレイヤーの名前は「#{@player.name_kana}」です。会話では必ず名前を呼びかけながら優しく話してください。
      ロールプレイはファンタジー世界の住人として行い、
      「ゲームの説明」よりも「その人の性格がにじみ出るような雑談」を重視してください。

      禁止事項:
      - プレイヤーの性格診断結果を直接言わない（例: あなたは○○タイプです）
      - システムやAPIの話をしない
    SYS

    messages = [{ role: 'system', content: system_prompt }]
    talk_logs.each do |log|
      messages << { role: log['role'], content: log['content'] }
    end

    begin
      response = OPENAI_CLIENT.chat(
        parameters: {
          model: 'gpt-4o-mini',
          messages: messages,
          temperature: 0.8
        }
      )
      npc_reply = response.dig('choices', 0, 'message', 'content').to_s.strip
    rescue StandardError => e
      Rails.logger.error("[NPC_TALK] OpenAI error: #{e.class} #{e.message}")
      npc_reply = 'ごめんね、ちょっと体調が悪くてうまく話せないみたい…。もう一度話しかけてくれる？'
    end

    talk_logs << { 'role' => 'assistant', 'content' => npc_reply }

    flags['talk_logs'] = talk_logs
    @story_progress.update!(flags: flags)

    player_talk_count = talk_logs.count { |l| l['role'] == 'user' }

    if params[:finish] == '1' || player_talk_count >= 3
      redirect_to decide_element_story_path
    else
      redirect_to npc_intro_story_path
    end
  end

  # =========================
  # 属性決定 & キャラ画像生成
  # =========================
  def decide_element
    flags     = @story_progress.flags || {}
    talk_logs = flags['talk_logs'] || []

    # 1. 会話ログを1つのテキストにまとめる
    dialogue_text = talk_logs.map { |l| "#{l['role']}: #{l['content']}" }.join("\n")

    # 2. 性格要約を生成
    personality = summarize_personality(@player, dialogue_text)

    # 3. 属性コードを LLM で決める（fire / water / wind / earth / light / dark / neutral）
    element_code = decide_element_code(@player, dialogue_text)

    # elements テーブルに code カラムが無くても、
    # name が "Fire" などなら name 検索で拾えるようにしておく
    element =
      Element.find_by(code: element_code) ||
      Element.find_by(name: element_code.capitalize)

    @player.update!(
      personality_summary: personality,
      element: element
    )

    # 4. キャラ画像生成（URLを avatar_image_url に保存）
    attach_avatar_image(@player, personality)

    # 5. プロローグへ遷移
    @story_progress.update!(current_step: 'prologue')

    redirect_to prologue_story_path, notice: 'キャラクターが完成しました！'
  end

  # =========================
  # プロローグ〜その後の分岐
  # =========================
  def prologue
    # ここでは current_step は動かさない（初回はキャラ作成時にセット済み）
  end

  def branch1_choice; end

  def go_goblin
    @progress.update!(current_step: 'goblin_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'goblin')
  end

  def go_thief
    @progress.update!(current_step: 'thief_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'thief')
  end

  def after_goblin
    @progress.update!(current_step: 'after_goblin')
  end

  def after_thief
    flags = @progress.flags_hash
    flags['helped_victim'] = true
    @progress.update!(current_step: 'after_thief', flags: flags)
  end

  def branch2_choice; end

  def go_gatekeeper
    @progress.update!(current_step: 'gatekeeper_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'gatekeeper')
  end

  def go_general
    @progress.update!(current_step: 'general_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'general')
  end

  def after_gatekeeper
    @progress.update!(current_step: 'warehouse')
  end

  def after_general
    flags = @progress.flags_hash
    flags['defeated_general'] = true
    @progress.update!(current_step: 'warehouse', flags: flags)
  end

  def warehouse
    @progress.update!(current_step: 'demonlord_intro')
  end

  def demonlord_intro; end

  def go_demonlord
    @progress.update!(current_step: 'demonlord_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'demonlord')
  end

  def ending
    flags = @progress.flags_hash
    @true_end =
      flags['helped_victim'] &&
      flags['defeated_general'] &&
      flags['no_game_over']

    if @true_end
      render :ending_true
    else
      render :ending_normal
    end
  end

  private

  # === 会話ログから属性コードを決める ===
  def decide_element_code(player, dialogue_text)
    prompt = <<~PROMPT
      以下は、ファンタジー世界で NPC とプレイヤー（#{player.name_kana}）が会話したログです。
      このプレイヤーの雰囲気や話し方から、
      次の中から1つだけ、もっとも近い属性コードを選んでください。

      候補:
      - fire
      - water
      - wind
      - earth
      - light
      - dark
      - neutral

      出力は、属性コード1語だけにしてください（例: fire）。

      会話ログ:
      #{dialogue_text}
    PROMPT

    begin
      res = OPENAI_CLIENT.chat(
        parameters: {
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: 'あなたはRPGの属性診断の専門家です。' },
            { role: 'user', content: prompt }
          ],
          temperature: 0.3
        }
      )

      code = res.dig('choices', 0, 'message', 'content').to_s.strip.downcase

      # 想定外の文字が来たら neutral にフォールバック
      %w[fire water wind earth light dark neutral].include?(code) ? code : 'neutral'
    rescue StandardError => e
      Rails.logger.error("[DECIDE_ELEMENT_CODE] OpenAI error: #{e.class} #{e.message}")
      'neutral'
    end
  end

  def require_player!
    return if session[:player_id] && Player.exists?(session[:player_id])

    redirect_to new_character_path, alert: '先にキャラ作成を行ってください。'
  end

  def set_player_and_progress
    @player = Player.find(session[:player_id])

    @story_progress =
      StoryProgress.find_or_create_by!(player: @player) do |sp|
        sp.current_step = 'npc_talk'
        sp.flags        = { 'talk_logs' => [] }
      end

    # 既存コード互換用
    @progress = @story_progress
  end

  def summarize_personality(player, dialogue_text)
    prompt = <<~PROMPT
      以下は、ファンタジー世界で NPC とプレイヤー（#{player.name_kana}）が会話したログです。
      このログから、プレイヤーの性格・雰囲気・話し方の特徴を優しく短くまとめてください。
      箇条書きではなく、2〜3文の日本語の文章で、三人称（「〜な人です」）で書いてください。

      #{dialogue_text}
    PROMPT

    begin
      response = OPENAI_CLIENT.chat(
        parameters: {
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: 'あなたは性格要約の専門家です。' },
            { role: 'user', content: prompt }
          ],
          temperature: 0.7
        }
      )
      response.dig('choices', 0, 'message', 'content').to_s.strip
    rescue StandardError => e
      Rails.logger.error("[PERSONALITY_SUMMARY] OpenAI error: #{e.class} #{e.message}")
      '穏やかで、優しさのある人物です。'
    end
  end

  # === 要約からキャラ画像を生成して URL を保存する ===
  # === 要約からキャラ画像を生成して ActiveStorage に保存 ===
  # === 要約からキャラ画像を生成して ActiveStorage に保存する ===
  def attach_avatar_image(player, personality_summary)
    gender_prompt =
      case player.gender
      when 'male'   then 'young male adventurer'
      when 'female' then 'young female adventurer'
      else               'androgynous young adventurer'
      end

    image_prompt = <<~IMG
      anime style fantasy character illustration,
      #{gender_prompt},
      full body, entire body visible from head to toe,
      standing pose, facing front,
      centered in the frame with generous margins,
      medium-distance framing, character should occupy about 70% of the canvas height,
      clear space above the head and below the feet,
      no cropping of head or feet,

      transparent background, PNG with alpha channel,
      no background, no scenery, no floor, no environment,
      no background shadows, clean silhouette,

      high detail, soft lighting,
      Personality: #{personality_summary}
      No text, no logo.
    IMG

    begin
      image_response = OPENAI_CLIENT.images.generate(
        parameters: {
          model: 'gpt-image-1',
          prompt: image_prompt,
          size: '1024x1536'
        }
      )

      b64 = image_response.dig('data', 0, 'b64_json')

      unless b64.present?
        Rails.logger.error("[AVATAR_IMAGE] b64_json が返ってきません: #{image_response.inspect}")
        return
      end

      binary = Base64.decode64(b64)
      io     = StringIO.new(binary)

      player.avatar_image.attach(
        io: io,
        filename: "player_#{player.id}_avatar.png",
        content_type: 'image/png'
      )
    rescue StandardError => e
      # ここでボディも出してあげると原因がはっきりする
      if e.respond_to?(:response) && e.response
        Rails.logger.error("[AVATAR_IMAGE] 画像生成エラー: #{e.class} #{e.message} body: #{e.response.body}")
      else
        Rails.logger.error("[AVATAR_IMAGE] 画像生成エラー: #{e.class} #{e.message}")
      end
    end
  end
end
