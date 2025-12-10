class StoriesController < ApplicationController
  require 'base64'
  require 'stringio'

  before_action :disable_turbo

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
    flags = @progress.flags || {}
    @talk_logs = flags['talk_logs'] || []

    last_npc = @talk_logs.reverse.find { |log| log['role'] == 'assistant' }

    @npc_message =
      if last_npc
        last_npc['content']
      else
        "はじめまして、#{@player.name_kana}。これから何問か質問をするね。気楽に答えてほしい。
        あなたを一言で表すと？"
      end
  end

  # =========================
  # NPC会話 2: 発言送信（POST）
  # =========================
  def npc_talk
    flags = (@progress.flags || {}).deep_dup
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
    @progress.update!(flags: flags)

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
    flags = @progress.flags || {}
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

    # ★ ここでカードも自動生成（全員対象）
    @player.generate_gift_card!

    # 5. プロローグへ遷移
    # 5. プロローグへ遷移
    (@progress || @story_progress).update!(current_step: 'character_summary')
    session[:current_step] = 'character_summary' # ★ ここを追加
    # A画面には「ストーリーモードだよ」と伝えるだけ
    session[:screen_mode] = 'story'

    redirect_to character_summary_story_path, notice: 'キャラクターが完成しました！'
  end

  # =========================
  # キャラ作成結果（B画面）
  # =========================
  def character_summary
    session[:screen_mode] = 'summary'
    session[:current_step] = 'character_summary' # ← A を光＋キャラ画面へ
    # ビュー側は今まで通り character_summary.html.erb を表示
  end

  def prologue
    session[:screen_mode]  = 'story'
    session[:current_step] = 'prologue'
    @progress.update!(current_step: 'prologue')
  end

  def branch1_choice
    session[:screen_mode]  = 'story'
    session[:current_step] = 'branch1_choice'
    @progress.update!(current_step: 'branch1_choice')
  end

  # ★ 追加：ゴブリン戦の前のストーリー画面
  def goblin_intro
    session[:screen_mode] = 'story'
    session[:current_step] = 'goblin_intro'
    @progress.update!(current_step: 'goblin_intro')
    # view: app/views/stories/goblin_intro.html.erb を表示
  end

  # ★ 追加：盗賊戦の前のストーリー画面
  def thief_intro
    session[:screen_mode] = 'story'
    session[:current_step] = 'thief_intro'
    @progress.update!(current_step: 'thief_intro')
    # view: app/views/stories/thief_intro.html.erb を表示
  end

  # ▼ ここを書き換える
  def go_goblin
    session[:screen_mode] = 'story'
    session[:current_step] = 'goblin_intro'
    @progress.update!(current_step: 'goblin_intro')
    redirect_to goblin_intro_story_path
  end

  def go_thief
    session[:screen_mode] = 'story'
    session[:current_step] = 'thief_intro'
    @progress.update!(current_step: 'thief_intro')
    redirect_to thief_intro_story_path
  end

  def after_goblin
    session[:screen_mode] = 'story'
    session[:current_step] = 'after_goblin'
    @progress.update!(current_step: 'after_goblin')
  end

  def after_thief
    session[:screen_mode] = 'story'
    flags = @progress.flags_hash
    flags['helped_victim'] = true
    @progress.update!(current_step: 'after_thief', flags: flags)
    session[:current_step] = 'after_thief'
  end

  def branch2_choice
    session[:screen_mode] = 'story'
    session[:current_step] = 'branch2_choice'
    @progress.update!(current_step: 'branch2_choice')
  end

  def go_gatekeeper
    session[:screen_mode] = 'story'
    session[:current_step] = 'gatekeeper_intro'
    @progress.update!(current_step: 'gatekeeper_intro')
    redirect_to gatekeeper_intro_story_path
  end

  def go_princess
    session[:screen_mode] = 'story'
    session[:current_step] = 'princess_meeting'
    @progress.update!(current_step: 'princess_meeting')
    redirect_to princess_meeting_story_path
  end

  def go_general_from_princess
    session[:screen_mode] = 'story'
    session[:current_step] = 'general_intro'
    @progress.update!(current_step: 'general_intro')
    redirect_to general_intro_story_path
  end

  def go_gatekeeper_from_princess
    session[:screen_mode] = 'story'
    session[:current_step] = 'gatekeeper_from_princess'
    @progress.update!(current_step: 'gatekeeper_from_princess')
    redirect_to gatekeeper_from_princess_story_path
  end

  # --- 画面表示系（GET） ---

  def gatekeeper_intro
    session[:current_step] = 'gatekeeper_intro'
    session[:screen_mode] = 'story'
    @progress.update!(current_step: 'gatekeeper_intro')
  end

  def princess_meeting
    session[:screen_mode] = 'story'
    session[:current_step] = 'princess_meeting'
    @progress.update!(current_step: 'princess_meeting')
  end

  def gatekeeper_from_princess
    session[:screen_mode] = 'story'
    session[:current_step] = 'gatekeeper_from_princess'
    @progress.update!(current_step: 'gatekeeper_from_princess')
  end

  def general_intro
    session[:screen_mode] = 'story'
    session[:current_step] = 'general_intro'
    @progress.update!(current_step: 'general_intro')
  end

  def after_gatekeeper
    session[:screen_mode] = 'story'

    flags = @progress.flags_hash
    flags['warehouse_route'] = 'gatekeeper' # ★ここで「門番ルート」を記録

    return unless @progress

    @progress.update!(
      current_step: 'after_gatekeeper',
      flags: flags
    )
    session[:current_step] = 'after_gatekeeper'
  end

  def after_general
    session[:screen_mode] = 'story'

    flags = @progress.flags_hash
    flags['defeated_general'] = true        # 既存フラグ
    flags['warehouse_route']  = 'general'   # ★ここで「将軍ルート」を記録

    return unless @progress

    @progress.update!(
      current_step: 'after_general',
      flags: flags
    )
    session[:current_step] = 'after_general'
  end

  # ✅ 門番ルート専用の倉庫画面
  def warehouse_gate
    session[:screen_mode] = 'story'
    session[:current_step] = 'warehouse_gate'
    @progress.update!(current_step: 'warehouse_gate')
    # → app/views/stories/warehouse_gate.html.erb が表示される
  end

  # ✅ 将軍ルート専用の倉庫画面
  def warehouse_general
    session[:screen_mode] = 'story'
    session[:current_step] = 'warehouse_general'
    @progress.update!(current_step: 'warehouse_general')
    # → app/views/stories/warehouse_general.html.erb が表示される
  end

  def demonlord_intro
    session[:screen_mode] = 'story'
    session[:current_step] = 'demonlord_intro'
    @progress.update!(current_step: 'demonlord_intro')
  end

  def ending
    session[:screen_mode] = 'story'
    flags = @progress.flags_hash

    # ★ no_game_over がキーとして存在しないときは true 扱いにする
    no_game_over =
      if flags.key?('no_game_over')
        flags['no_game_over']
      else
        true
      end

    @true_end =
      flags['helped_victim'] &&
      flags['defeated_general'] &&
      no_game_over

    if @true_end
      session[:current_step] = 'ending_true_step1'
      @progress.update!(current_step: 'ending_true_step1')
      render :ending_true_step1
    else
      session[:current_step] = 'ending_normal'
      @progress.update!(current_step: 'ending_normal')
      render :ending_normal
    end
  end

  def game_over
    session[:screen_mode] = 'story'
    session[:current_step] = 'ending_bad'
    # 必要なら進行度を残しておく
    @progress.update!(current_step: 'ending_bad')

    # ビュー app/views/stories/ending_bad.html.erb を表示
    render :ending_bad
  end

  def ending_true_step1
    session[:screen_mode] = 'story'
    session[:current_step] = 'ending_true_step1'
    @progress.update!(current_step: 'ending_true_step1')
    # 特にフラグ更新はなし。魔王撃破〜魔姫の願い
  end

  def ending_true_message
    session[:screen_mode] = 'story'
    session[:current_step] = 'ending_true_message'
    @progress.update!(current_step: 'ending_true_message')
    # ここで「最後の言葉」を入力する画面
  end

  def submit_ending_true_message
    @player = Player.find(session[:player_id])

    # フォームから飛んでくる name="message"
    message = params[:message].to_s

    # ① 保存（meta にしまっておく）
    meta = @player.meta || {}
    meta['true_ending_message'] = message
    @player.meta = meta
    @player.save!

    # ② 手紙画像を生成（便箋＋テキスト）
    @player.generate_gift_letter!

    # ③ 第三幕（ルナリア旅立ち）へ
    redirect_to ending_true_after_story_path
  end

  def ending_true_after
    session[:screen_mode] = 'story'
    session[:current_step] = 'ending_true_after'
    @progress.update!(current_step: 'ending_true_after')
    # 魔姫が旅立ち、エンディングテーマが流れる画面
    @player.attach_gift_card_from_tmp!       # 全員にカード
    @player.attach_gift_letter_from_tmp!     # 真エンド専用
  end

  # =========================
  # private メソッド
  # =========================
  private

  def disable_turbo
    request.format = :html
  end

  # /screen 以外は必ずプレイヤーが必要
  def require_player!
    return if session[:player_id] && Player.exists?(session[:player_id])

    redirect_to new_character_path, alert: '先にキャラ作成を行ってください。'
  end

  # B画面用（通常のストーリー進行）
  def set_player_and_progress
    @player = Player.find(session[:player_id])

    @progress =
      StoryProgress.find_or_create_by!(player: @player) do |sp|
        sp.current_step = 'npc_talk'
        sp.flags        = {
          'talk_logs' => [],
          'no_game_over' => true # ★ ここで初期値 true
        }
      end
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

  def generate_letter_text(player, last_message)
    prompt = <<~PROMPT
      あなたは「魔姫ルナリア」です。
      プレイヤー（#{player.name_kana}）は真エンドに到達し、
      最後に以下の言葉をあなたへ送りました。

      ----
      #{last_message}
      ----

      これを受けて、
      ルナリアが「別れの手紙」を書くつもりで、
      優しく、胸に残る文体で、
      180〜250文字程度の日本語で手紙を書いてください。

      文中には必ず「#{player.name_kana}さん」と名前を入れ、
      語尾は丁寧すぎず、気持ちのこもった表現にしてください。
    PROMPT

    res = OPENAI_CLIENT.chat(
      parameters: {
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: 'あなたはファンタジー世界の魔姫ルナリアとして手紙を書くAIです。' },
          { role: 'user', content: prompt }
        ]
      }
    )

    res.dig('choices', 0, 'message', 'content').to_s
  end
end
