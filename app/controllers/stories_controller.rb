class StoriesController < ApplicationController
  require 'base64'
  require 'stringio'

  # いまは view_screen だけ特別扱い
  before_action :require_player!, except: %i[view_screen]
  before_action :set_player_and_progress, except: %i[view_screen]

  # ===== A画面（スクリーン用）=====
  # ===== A画面（スクリーン用）=====
  # ===== A画面（スクリーン用）=====
  def view_screen
    mode = session[:screen_mode] || 'title'
    @mode = mode.to_sym
  end

  # =========================
  # NPC会話 1: 画面表示（B画面用）
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

    # 4. キャラ画像生成（ActiveStorage に保存）
    attach_avatar_image(@player, personality)

    # 5. プロローグへ遷移
    @story_progress.update!(current_step: 'character_summary')
    # A画面には「ストーリーモードだよ」と伝えるだけ
    session[:screen_mode] = 'story'

    redirect_to character_summary_story_path, notice: 'キャラクターが完成しました！'
  end

  # =========================
  # キャラ作成結果（B画面）
  # =========================
  def character_summary
    session[:screen_mode] = 'summary' # ← A を光＋キャラ画面へ
    # ビュー側は今まで通り character_summary.html.erb を表示
  end

  def prologue
    session[:screen_mode] = 'story' # ← A を街の画面へ
    # 進行状況も prologue にしておく（A画面で背景を選ぶのに使う）
    @progress.update!(current_step: 'prologue') if @progress
  end

  # =========================
  # 1つ目の分岐（B画面）
  # =========================
  def branch1_choice
    session[:screen_mode] = 'story'
  end

  # ★ 追加：ゴブリン戦の前のストーリー画面
  def goblin_intro
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'goblin_intro')
    # view: app/views/stories/goblin_intro.html.erb を表示
  end

  # ★ 追加：盗賊戦の前のストーリー画面
  def thief_intro
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'thief_intro')
    # view: app/views/stories/thief_intro.html.erb を表示
  end

  # ▼ ここを書き換える
  def go_goblin
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'goblin_intro')
    redirect_to goblin_intro_story_path
  end

  def go_thief
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'thief_intro')
    redirect_to thief_intro_story_path
  end

  def after_goblin
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'after_goblin')
  end

  def after_thief
    session[:screen_mode] = 'story'
    flags = @progress.flags_hash
    flags['helped_victim'] = true
    @progress.update!(current_step: 'after_thief', flags: flags)
  end

  def branch2_choice
    session[:screen_mode] = 'story'
  end

  def go_gatekeeper
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'gatekeeper_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'gatekeeper')
  end

  def go_general
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'general_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'general')
  end

  def after_gatekeeper
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'warehouse')
  end

  def after_general
    session[:screen_mode] = 'story'
    flags = @progress.flags_hash
    flags['defeated_general'] = true
    @progress.update!(current_step: 'warehouse', flags: flags)
  end

  def warehouse
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'demonlord_intro')
  end

  def demonlord_intro
    session[:screen_mode] = 'story'
  end

  def go_demonlord
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'demonlord_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'demonlord')
  end

  def ending
    session[:screen_mode] = 'story'
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

  # =========================
  # private メソッド
  # =========================
  private

  # /screen 以外は必ずプレイヤーが必要
  def require_player!
    return if session[:player_id] && Player.exists?(session[:player_id])

    redirect_to new_character_path, alert: '先にキャラ作成を行ってください。'
  end

  # B画面用（通常のストーリー進行）
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

  # A画面用（/screen）：プレイヤーがいれば読み込むだけ
  def set_player_and_progress_for_view
    return unless session[:player_id]

    @player = Player.find_by(id: session[:player_id])
    return unless @player

    # ★ A画面では「読むだけ」。なければ作らない
    @story_progress = StoryProgress.find_by(player: @player)
    @progress       = @story_progress
  end

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

      %w[fire water wind earth light dark neutral].include?(code) ? code : 'neutral'
    rescue StandardError => e
      Rails.logger.error("[DECIDE_ELEMENT_CODE] OpenAI error: #{e.class} #{e.message}")
      'neutral'
    end
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
      if e.respond_to?(:response) && e.response
        Rails.logger.error("[AVATAR_IMAGE] 画像生成エラー: #{e.class} #{e.message} body: #{e.response.body}")
      else
        Rails.logger.error("[AVATAR_IMAGE] 画像生成エラー: #{e.class} #{e.message}")
      end
    end
  end
end
