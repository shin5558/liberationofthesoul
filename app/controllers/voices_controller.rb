# app/controllers/voices_controller.rb
class VoicesController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  # VOICEVOX サーバー（必要なら 127.0.0.1:50021 を変えてね）
  VOICEVOX_HOST = ENV.fetch('VOICEVOX_HOST', 'http://127.0.0.1:50021')

  skip_forgery_protection

  # ==== プロローグ ====
  PROLOGUE_LINES = {
    'narrator_1' => lambda { |name|
      '闇がゆっくりと世界を覆いはじめた頃―― 山と森に囲まれた小さな王国で、一人の冒険者が静かに目を覚ます。'
    },
    'narrator_2' => lambda { |name|
      "その名は#{name}。 まだ自分の運命も、この国に迫る脅威の正体も知らないまま…。"
    },
    'fairy_1' => lambda { |name|
      "……あ、やっと起きた。ふふ、ずっと待ってたんだよ。わたしはリュミエル。これから#{name}のそばで案内役をする妖精です。"
    },
    'fairy_2' => lambda { |name|
      "怖がらなくて大丈夫。世界が少し暗くなっていても、#{name}と一緒なら、きっと光を取り戻せるから。"
    }
  }.freeze

  # ==== 分岐1（branch1_choice） ====
  BRANCH1_LINES = {
    'narrator_1' => lambda { |name|
      '森の入口へと続く街道。その先で、何かが横たわっている。近づくにつれ、それが横倒しになった馬車と、その周囲をうろつく小さな影だと分かってくる。'
    },
    'fairy_1' => lambda { |name|
      '……先の方に倒れた馬車と、その近くにゴブリンが三匹いるよ。'
    },
    'narrator_2' => lambda { |name|
      '耳をすませると、風の流れとは違う、不自然な音が混じっている気がする。'
    },
    'voice_1' => lambda { |name|
      '……たすけて……！'
    },
    'fairy_2' => lambda { |name|
      '今のは……、悲鳴……？'
    },
    'narrator_3' => lambda { |name|
      '道の先では、今にも馬車をあさろうとするゴブリンたち。一方で、森の奥からは、確かに誰かの助けを求める声が聞こえた気がする。'
    },
    'fairy_3' => lambda { |name|
      '道の先には、馬車とゴブリン。でも、森の方からも誰かの声が聞こえたよ……。どうする？'
    }
  }.freeze

  # ==== ゴブリン戦導入（goblin_intro） ====
  GOBLIN_INTRO_LINES = {
    'narrator_1' => lambda { |name|
      'あなたは、まず目の前の脅威に集中することにした。森の奥の声は気になるが、倒れた馬車とゴブリンたちを放置しておくわけにもいかない。'
    },
    'fairy_1' => lambda { |name|
      '分かった。まずはこのゴブリンたちから片付けよう。あの馬車の人たちが無事かどうか、気になるしね。'
    },
    'narrator_2' => lambda { |name|
      '足音を殺し、ゴブリンたちとの距離を少しずつ詰めていく。しかし、やがて彼らもこちらの存在に気づき、ぎょろりとした目を向けてきた。'
    },
    'goblin_1' => lambda { |name|
      'ゲリャッ、ゲリャッ！！'
    },
    'fairy_2' => lambda { |name|
      '流石にここまで近づいたら、気づいたみたい。気をつけてね、あの子たち、集団で来ると結構やっかいだから。'
    },
    'narrator_3' => lambda { |name|
      'ゴブリンたちは歯をむき出しにしながら武器を振り上げ、一斉に飛びかかってくる。ここから――最初の本格的な戦いが始まる。'
    }
  }.freeze

  # ==== 盗賊戦導入（thief_intro） ====
  THIEF_INTRO_LINES = {
    'narrator_1' => lambda { |name|
      'あなたは、森の奥から聞こえた悲鳴を見過ごすことができなかった。倒れた馬車とゴブリンたちは気になるものの、人の叫び声はもっと危険な兆しに思えた。'
    },
    'fairy_1' => lambda { |name|
      '悲鳴の方に行くんだね……分かった、一緒に行こう。急ごう、誰かが本当に助けを求めているかもしれない。'
    },
    'narrator_2' => lambda { |name|
      '枝をかき分け、声の聞こえた方向へと進んでいく。やがて木々が途切れ、少しひらけた場所に出たそのとき――。'
    },
    'narrator_3' => lambda { |name|
      'そこには、縄で縛られて地面に座り込む一人の女性と、その周囲を取り囲む三人の男たちの姿があった。'
    },
    'thief_1' => lambda { |name|
      'ん？ なんだぁ、おまえは。'
    },
    'fairy_2' => lambda { |name|
      'そっちこそ何者よ。縛られた人を囲んで……いい趣味してないわね。'
    },
    'thief_leader_1' => lambda { |name|
      '俺たちは、土竜盗賊団だ。……お前さん、その妖精を置いていきな。そうしたら、お前さんだけは見逃してやる。'
    },
    'fairy_3' => lambda { |name|
      '嫌に決まっているでしょ！ わたしは、この人と一緒に行くって決めたんだから！'
    },
    'thief_leader_2' => lambda { |name|
      '……チッ。惜しいことをする。しょうがねぇ、お前らも売り物にしてやるよ！'
    },
    'narrator_4' => lambda { |name|
      '盗賊たちが一斉に武器を構え、にやりと笑う。森の静寂は破られ、張り詰めた空気の中で、決戦の時を告げる鼓動だけが響いていた。'
    }
  }.freeze

  # ===== アクション =====

  def prologue
    speak_from_hash(PROLOGUE_LINES)
  end

  # ※ JS の URL を /voices/branch1 にしているならこのまま
  #   /voices/branch1_choice にしたいなら、メソッド名も routes も合わせて変える
  def branch1
    speak_from_hash(BRANCH1_LINES)
  end

  def goblin_intro
    speak_from_hash(GOBLIN_INTRO_LINES)
  end

  def thief_intro
    speak_from_hash(THIEF_INTRO_LINES)
  end

  private

  def speak_from_hash(lines_hash)
    key    = params[:line].to_s
    player = Player.find_by(id: session[:player_id])
    name   = player&.name_kana.presence || 'あなた'

    builder = lines_hash[key]
    text    = builder ? builder.call(name) : '……。'

    speaker_id = speaker_for(key)
    wav        = synthesize(text, speaker_id)

    send_data wav, type: 'audio/wav', disposition: 'inline'
  rescue StandardError => e
    Rails.logger.error("[VOICEVOX] speak_from_hash error: #{e.class} #{e.message}")
    head :internal_server_error
  end

  # 役ごとに声色を変える
  def speaker_for(key)
    case key
    when /\Afairy/
      3   # 妖精リュミエル
    when /\Agoblin/
      8   # ゴブリン
    when /\Athief/
      5   # 盗賊
    else
      1   # ナレーション / その他
    end
  end

  # ==== ここが VOICEVOX への生 HTTP 部分 ====
  def synthesize(text, speaker)
    # 1. audio_query
    uri_query = URI("#{VOICEVOX_HOST}/audio_query")
    uri_query.query = URI.encode_www_form(text: text, speaker: speaker)

    res1 = Net::HTTP.post(uri_query, '')
    raise "audio_query failed: #{res1.code} #{res1.body}" unless res1.is_a?(Net::HTTPSuccess)

    query_json = res1.body

    # 2. synthesis
    uri_synth = URI("#{VOICEVOX_HOST}/synthesis")
    uri_synth.query = URI.encode_www_form(speaker: speaker)

    res2 = Net::HTTP.post(uri_synth, query_json, 'Content-Type' => 'application/json')
    raise "synthesis failed: #{res2.code} #{res2.body}" unless res2.is_a?(Net::HTTPSuccess)

    res2.body # WAV バイナリ
  end
end
