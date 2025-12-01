# app/controllers/voices_controller.rb
class VoicesController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  # VOICEVOX サーバー（必要なら 127.0.0.1:50021 を変えてね）
  STYLEBERT_HOST = ENV.fetch('STYLEBERT_HOST', 'http://127.0.0.1:5000')

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
      '俺たちは、もぐら盗賊団だ。……お前さん、その妖精を置いていきな。そうしたら、お前さんだけは見逃してやる。'
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

  # ==== ゴブリン戦後 ====
  AFTER_GOBLIN_LINES = {
    'fairy_1' => lambda { |name|
      'やったぁ――！ ゴブリンを倒したよ！'
    },
    'fairy_2' => lambda { |name|
      "#{name}、お疲れ様。戦いで疲れたでしょ、ちょっと回復しておくね。"
    },
    'narrator_1' => lambda { |name|
      'リュミエルがそっと手を差し伸べると、柔らかな光が舞い上がり、あなたの身体を包み込む。重かった身体が、少しずつ軽くなっていく。'
    },
    'fairy_3' => lambda { |name|
      'あっ、ほら。馬車の中、何か光ってるよ……！'
    },
    'narrator_2' => lambda { |name|
      '倒れた馬車の荷台には、淡く光を放つ一枚のカードが転がっていた。まるで、持ち主を待っていたかのように。'
    },
    'fairy_4' => lambda { |name|
      'じゃーん！ 無属性カードだよ。誰でも使える便利なカードだから、きっと役に立つはず！'
    },
    'narrator_3' => lambda { |name|
      'あなたはカードを受け取り、そっとデッキにしまった。心なしか、指先に温かな力が宿ったように感じる。'
    },
    'fairy_5' => lambda { |name|
      'よし、ひと段落ついたね。でも、道はまだ続いてる……この先には、門番の砦があるはずだよ。'
    },
    'narrator_4' => lambda { |name|
      '街道の先には、風に揺れる木々と、遠くにかすかに見える石造りの影が見える。そこは、この国の運命を左右する分かれ道のひとつだった。'
    },
    'fairy_6' => lambda { |name|
      "ここから先は、どう進むかを決めなきゃいけないみたい。#{name}、準備はいい？"
    }
  }.freeze

  # ==== 盗賊戦後 ====
  AFTER_THIEF_LINES = {
    'narrator_1' => lambda { |name|
      '盗賊たちが地面に倒れ込み、森の中にあった緊張がすっと解けていく。さっきまで響いていた怒号も、今はただ、静かな風の音にかき消されていた。'
    },
    'fairy_1' => lambda { |name|
      'やったー！ もぐらどもを、まとめてやっつけたよ！'
    },
    'narrator_2' => lambda { |name|
      'リュミエルがくるりと一回転すると、淡い光の粉が周囲にふわりと舞い散る。縄で縛られていた女性も、ようやくその場の空気が変わったことに気づいたようだった。'
    },
    'woman_1' => lambda { |name|
      'あ、あの……助けてくださって、本当にありがとうございます……！'
    },
    'fairy_2' => lambda { |name|
      '――あ、そういえばいたね。すっかり忘れてたよ。'
    },
    'narrator_3' => lambda { |name|
      'あまりに遠慮のないその一言に、女性は思わず肩を落とした。'
    },
    'woman_2' => lambda { |name|
      'うう……慣れてますから、いいですけど…。それよりも、お礼にこちらを受け取ってください。'
    },
    'narrator_4' => lambda { |name|
      '女性が差し出したのは、淡い光を帯びた一枚のカードだった。手にした瞬間、指先に小さな鼓動のような力が伝わってくる。'
    },
    'woman_3' => lambda { |name|
      '旅の途中で拾った、不思議なカードなんです。わたしよりも、あなたたちのほうがきっと上手く使えると思って…。'
    },
    'fairy_3' => lambda { |name|
      'わあ、ありがとう！ 無属性カードだね。誰でも使える、便利なやつだよ。'
    },
    'narrator_5' => lambda { |name|
      'カードは、あなたのデッキの中に自然と溶け込むように納まっていく。新たな一手を手に入れたという実感が、心を少しだけ軽くした。'
    },
    'woman_4' => lambda { |name|
      'わたしは、一度家に戻ります。本当にありがとうございました。それでは、失礼します。'
    },
    'narrator_6' => lambda { |name|
      '女性は何度も振り返りながら頭を下げると、森の出口のほうへと小走りに去っていった。'
    },
    'fairy_4' => lambda { |name|
      'バイバーイ！ ……ふう、なんとか一件落着だね。'
    },
    'narrator_7' => lambda { |name|
      '残されたのは、静けさと、倒れた盗賊たち、そして新しく手に入れたカードだけ。森の奥から吹き抜けた風が、あなたたちの背中をそっと押す。こうして、もぐら盗賊団との一件は幕を閉じ、次の物語へと歩みを進めていく――。'
    }
  }.freeze

  BRANCH2_LINES = {
    'fairy_1' => lambda { |name|
      'ついたね、ここが魔王国の城下町だよ。'
    },
    'fairy_2' => lambda { |name|
      '今ここにいる魔族たちは、戦いが得意ではないみたいだね。'
    },
    'fairy_3' => lambda { |name|
      '戦える魔族たちは、城に集められてるみたい。'
    },
    'unknown_1' => lambda { |name|
      '――そこの方、妖精と共にいる方。'
    },
    'fairy_4' => lambda { |name|
      'だれ！？'
    },
    'narrator_1' => lambda { |name|
      'フード付きのローブで全身を隠した者が、路地の陰からこちらへ声をかけてきた。' \
      'その姿は、光の届かない闇に溶け込んでいて、顔の表情まではうかがえない。'
    },
    'unknown_2' => lambda { |name|
      '魔王を倒したいなら、私たちと協力しませんか？'
    },
    'fairy_5' => lambda { |name|
      '協力したいなら、まずは姿を見せてよ。'
    },
    'fairy_6' => lambda { |name|
      'あなたみたいな、姿を見せない怪しい魔族とは、協力なんて無理だよ。'
    },
    'unknown_3' => lambda { |name|
      '今ここで姿を晒すのは難しいので……こちらに来ていただけますか？'
    },
    'narrator_2' => lambda { |name|
      'ここで、あなたはどうするかを決めなければならない。' \
      'この怪しい誘いを退け、そのまま魔王城へ向かうか。' \
      'それとも、危険を承知で、この人物の話に乗ってみるか――。'
    }
  }.freeze

  GATEKEEPER_INTRO_LINES = {
    'narrator_1' => lambda { |name|
      '魔王城へと続く大通りを抜けると、視界の先に巨大な城門がそびえ立つ。' \
      '鋭い棘のついた鉄柵が、ここから先は簡単には通さないと主張している。'
    },

    'gatekeeper_1' => lambda { |name|
      'そこの人間、止まれ！'
    },

    'fairy_1' => lambda { |name|
      'なに、邪魔するの？'
    },

    'gatekeeper_2' => lambda { |name|
      'ああ、そういう仕事なんでな。'
    },

    'fairy_2' => lambda { |name|
      'いいの？ こんなことしてて。' \
      '魔王を止めないと、あなたもどうなるかわからないんだよ？'
    },

    'gatekeeper_3' => lambda { |name|
      '俺は仕事をするだけだ。'
    },

    'fairy_3' => lambda { |name|
      'この堅物には、話は通じないみたい…。' \
      "倒そう、#{name}！"
    },

    'narrator_2' => lambda { |name|
      '門番は槍を構え、城門の前に立ちはだかる。' \
      'ここを越えなければ、魔王城には辿り着けない――最初の関門の戦いが、今始まろうとしていた。'
    }
  }.freeze

  PRINCESS_MEETING_LINES = {
    'narrator_1' => lambda { |name|
      '路地裏の奥へと案内され、周囲を見渡すと、人通りはほとんどなくなっていた。' \
      '城下町の喧騒も遠く、ここだけが切り離された小さな空間のように静まり返っている。'
    },

    'mystery_1' => lambda { |name|
      '……ここなら大丈夫でしょう。'
    },

    'narrator_2' => lambda { |name|
      'そう言うと、フード付きのローブの人物は、ゆっくりとフードを下ろした。' \
      'そこから現れたのは、どこか気品を漂わせた、若い魔族の女性の顔だった。'
    },

    'princess_1' => lambda { |name|
      'わたしは魔王の娘よ。皆からは『魔姫』と呼ばれているわ。'
    },

    'fairy_1' => lambda { |name|
      'ま、魔王の娘！？ なんでそんな人が、こんなところにいるの？'
    },

    'princess_2' => lambda { |name|
      'それは――あの魔王を止めるためよ。そのために、わたしは反乱軍を立ち上げたの。'
    },

    'narrator_3' => lambda { |name|
      '魔姫が指を鳴らすと、路地の影から、数人の魔族たちが姿を現した。' \
      '彼らの瞳は、恐れではなく、どこか決意に満ちた光を帯びている。'
    },

    'princess_3' => lambda { |name|
      '魔王軍を止めることだけなら、わたしたちだけでも、きっとなんとかなるでしょう。' \
      'でも――肝心の魔王本人にまで、わたしたちの力が届くかどうかは分からない。'
    },

    'princess_4' => lambda { |name|
      'だから、あなたに手を貸してほしいの。外の世界から来た、あなたの力を。'
    },

    'fairy_2' => lambda { |name|
      'ふーん……。でも、魔王の娘と組むなんて、普通に考えたらすっごく怪しい話だよね。'
    },

    'narrator_4' => lambda { |name|
      '魔姫は一瞬だけ目を伏せ、そして真っ直ぐこちらを見つめ返してきた。' \
      'その視線には、打算だけではない、揺るぎない覚悟のようなものが宿っている。'
    },

    'princess_5' => lambda { |name|
      '信じろとは言わないわ。それでも、目的は同じはず――' \
      'この世界を、魔王の暴走から救うということ。'
    },

    'fairy_3' => lambda { |name|
      "どうする、#{name}？目的が同じなら手を組むのもアリかもしれないけど……" \
      '魔族（ひと）に手を貸すの、いやだっていう気持ちも分かるよ。'
    },

    'narrator_5' => lambda { |name|
      'ここでの選択が、この先の道を大きく変えていく。' \
      '反乱軍と共に秘密の通路から攻め込むか、それとも正面から正々堂々と挑むか――。'
    }
  }.freeze

  GENERAL_INTRO_LINES = {
    # --- 地下通路へ向かう ---
    'narrator_1' => lambda { |name|
      '魔姫の提案を受け入れ、あなたたちは城下町の一角にある古びた建物の裏手へと向かった。' \
      '普段は誰も近寄らないのか、ひっそりとしたその場所には、重そうな鉄扉がひとつだけ、ぽつんと残されている。'
    },

    'princess_1' => lambda { |name|
      'ここよ。王族だけが知っている、魔王城へと繋がる秘密の通路。'
    },

    'fairy_1' => lambda { |name|
      'えっ、そんな大事なこと、私たちに教えちゃっていいの？'
    },

    'princess_2' => lambda { |name|
      '今は非常時よ。あの魔王を止められる可能性があるなら、手段を選んでいる余裕なんてないわ。'
    },

    'narrator_2' => lambda { |name|
      '魔姫が手をかざすと、鉄扉に刻まれた魔法陣が淡く光り、重い音を立てて扉が開いていく。' \
      'その奥には、ひんやりとした空気の漂う石造りの階段が、闇の中へと続いていた。'
    },

    'fairy_2' => lambda { |name|
      'うわぁ……ほんとに“裏道”って感じだね。でも、これなら正面から突っ込むよりは、まだマシかも。'
    },

    'princess_3' => lambda { |name|
      'ここから先は、あまり大きな声は出さないで。通路の一部は、城の兵舎や見張りの近くを通るから。'
    },

    # --- 地下通路の中 ---
    'narrator_3' => lambda { |name|
      '石段を降り、長い地下通路を進んでいく。足音を殺して進む中、壁に等間隔で設置された魔導灯の灯りだけが、薄暗い道を照らしていた。' \
      'やがて、通路は少しずつ広がり、天井の高い広間のような場所へと続いていく。'
    },

    'fairy_3' => lambda { |name|
      'ねぇ、魔姫。こういう秘密の通路って、罠とかないよね……？'
    },

    'princess_4' => lambda { |name|
      '……ゼロとは言い切れないけれど、少なくとも、ここは昔から王族の避難路として使われていた場所よ。' \
      '罠があっても、私が対処するわ。'
    },

    'narrator_4' => lambda { |name|
      'そう言って魔姫が進む先、地下通路はふっと開け、丸い広間のような空間へと出た。' \
      '壁には古い紋章が刻まれ、中央には、まるで儀式でも行われたかのような円形の模様が描かれている。'
    },

    # --- 将軍の登場 ---
    'general_1' => lambda { |name|
      'わっはっはっは……待っていたぞ。'
    },

    'narrator_5' => lambda { |name|
      '低く響く笑い声とともに、広間の奥の柱の影から、一人の男が姿を現れる。' \
      '厚い鎧に身を包み、鋭い目つきでこちらを見据えるその姿は、ただの兵士ではないと一目で分かった。'
    },

    'princess_5' => lambda { |name|
      '……あなたは、将軍……！？ なぜここにいるの。'
    },

    'general_2' => lambda { |name|
      '城下に“怪しげな者”が現れたと報告を受けてな。' \
      '部下に調べさせれば、“妖精と共にいる姫様を見た”という者がいると言うではないか。'
    },

    'narrator_6' => lambda { |name|
      '将軍の視線が、魔姫とあなたたちの姿をゆっくりとなぞる。' \
      'その目には、忠義とも執念ともつかない、重い覚悟が宿っていた。'
    },

    'general_3' => lambda { |name|
      '城にはすでに戻ってきていたようだが――甘かったな、姫様。' \
      '王の許しなく、この通路を使い、外の者と手を組むとは。'
    },

    'princess_6' => lambda { |name|
      '……分かってるわ。でも、あのまま何もしなければ、この国も、世界も滅びるだけよ。'
    },

    'general_4' => lambda { |name|
      'たとえそうだとしても、余計な真似をする者を放っておくわけにはいかん。' \
      'それが、この身に課せられた“役目”だ。'
    },

    'fairy_4' => lambda { |name|
      'はぁ……話、ぜんっぜん通じないタイプの人だね。' \
      'こういうの、だいたい戦うしかないんだよね。'
    },

    'princess_7' => lambda { |name|
      '見つかってしまったからには――もう、後戻りはできないわ。' \
      "お願い、#{name}。あなたの力を、わたしに貸して。"
    },

    'narrator_7' => lambda { |name|
      '将軍は大きな武器を構え、ゆっくりと踏み込んでくる。地下広間の空気が、一瞬で張り詰めた。' \
      'ここから――魔王城への道を賭けた、将軍との戦いが始まる。'
    }
  }.freeze

  GATEKEEPER_FROM_PRINCESS_LINES = {
    # 魔姫との別れ
    'narrator_1' => lambda { |name|
      'あなたが迷いながらも首を横に振ると、魔姫の瞳が、ほんの少しだけ揺れた。'
    },

    'princess_1' => lambda { |name|
      '……そう。残念だわ。手を貸してくれたら、きっと心強かったのだけれど。'
    },

    'fairy_1' => lambda { |name|
      "ごめんね、魔姫。でも、#{name} の気持ちも、分かってあげてほしいの。" \
      'いきなり“魔王の娘と組もう”って言われても、簡単には決められないよ。'
    },

    'princess_2' => lambda { |name|
      '分かっているわ。わたしだって、立場を逆にされたら、同じように迷うでしょうしね。'
    },

    'narrator_2' => lambda { |name|
      '魔姫はふっと寂しそうに微笑むと、くるりと背を向けた。'
    },

    'princess_3' => lambda { |name|
      'それじゃあ、お互いに――できる場所で戦いましょう。' \
      'あなたたちは、あなたたちのやり方で。わたしは、わたしのやり方で。'
    },

    'narrator_3' => lambda { |name|
      'そう言い残し、魔姫と反乱軍の一行は路地裏の奥へと姿を消していく。' \
      '残されたのは、静まり返った通りと、胸の奥に残る小さなざわめきだけだった。'
    },

    # 門前への移動
    'fairy_2' => lambda { |name|
      '……行っちゃったね。でも、立ち止まってる時間もないし――' \
      "行こう、#{name}。門の方へ！"
    },

    'narrator_4' => lambda { |name|
      'あなたたちは城下町の大通りへ戻り、魔王城へと続く巨大な門の前へとたどり着く。' \
      '高くそびえる城壁と、重厚な門扉が、まるで侵入者を拒むように立ちはだかっていた。'
    },

    # 門番との対峙
    'gatekeeper_1' => lambda { |name|
      '……そこの人間、止まれ！'
    },

    'narrator_5' => lambda { |name|
      '厳つい鎧に身を包んだ門番が、槍を地面に突き立てながら一歩前へと進み出る。' \
      'その目には、敵意というよりも、“職務”としての固い意志が宿っていた。'
    },

    'fairy_3' => lambda { |name|
      'なに、邪魔するの？私たち、ただ遊びに来たわけじゃないんだけど。'
    },

    'gatekeeper_2' => lambda { |name|
      'ああ。そういう“決まり”なんでな。正体の知れない者を、ここから先へは通せん。'
    },

    'fairy_4' => lambda { |name|
      'いいの？そんなことしてて。魔王を止めないと、あなたもどうなるか分からないんだよ？'
    },

    'gatekeeper_3' => lambda { |name|
      'それでも、だ。俺は“門を守る者”としてここに立っている。' \
      'その役目を捨てるくらいなら、ここで朽ちるほうがマシだ。'
    },

    'narrator_6' => lambda { |name|
      'まっすぐで、不器用なほど真っ直ぐな言葉。それでも、このまま通してくれる気はなさそうだ。'
    },

    'fairy_5' => lambda { |name|
      'はぁ……この堅物には、話を通すだけムダみたいだね。' \
      "仕方ないなぁ。ねぇ、#{name}――倒してでも、進むしかないよ。"
    },

    'narrator_7' => lambda { |name|
      '門番は槍を構え、静かに構えを低くする。その姿勢には一切の迷いがなく、' \
      'あなたたちの覚悟を試しているようにも見えた。' \
      'こうして、魔王城の門を守る門番との戦いが幕を開ける――。'
    }
  }.freeze

  # ===== アクション =====

  def prologue
    speak_from_hash(PROLOGUE_LINES)
  end

  def branch1
    speak_from_hash(BRANCH1_LINES)
  end

  def goblin_intro
    speak_from_hash(GOBLIN_INTRO_LINES)
  end

  def thief_intro
    speak_from_hash(THIEF_INTRO_LINES)
  end

  def after_goblin
    speak_from_hash(AFTER_GOBLIN_LINES)
  end

  def after_thief
    speak_from_hash(AFTER_THIEF_LINES)
  end

  def branch2
    speak_from_hash(BRANCH2_LINES)
  end

  def gatekeeper_intro
    speak_from_hash(GATEKEEPER_INTRO_LINES)
  end

  def princess_meeting
    speak_from_hash(PRINCESS_MEETING_LINES)
  end

  def general_intro
    speak_from_hash(GENERAL_INTRO_LINES)
  end

  def gatekeeper_from_princess
    speak_from_hash(GATEKEEPER_FROM_PRINCESS_LINES)
  end

  private

  def speak_from_hash(lines_hash)
    key = params[:line].to_s

    player = current_player

    name = player&.name_kana.presence || 'あなた'

    builder = lines_hash[key]
    text    = builder ? builder.call(name) : '……。'

    voice_opts = speaker_for(key)
    wav        = synthesize(text, voice_opts)

    send_data wav, type: 'audio/wav', disposition: 'inline'
  end

  def speaker_for(key)
    base = {
      model_name: 'amitaro', # エディタで使っていたモデル
      language: 'JP',
      style: 'Neutral',
      style_weight: 1.0
    }

    case key
    when /\Afairy/
      base.merge(speaker_name: 'あみたろ') # 妖精
    when /\Agoblin/
      base.merge(speaker_name: 'あみたろ') # ゴブリン（別声が欲しければここで変える）
    when /\Athief/
      base.merge(speaker_name: 'あみたろ') # 盗賊
    when /\Awoman/
      base.merge(speaker_name: 'あみたろ') # 女性NPC
    when /\Aprincess/
      base.merge(speaker_name: 'あみたろ') # 魔姫
    when /\Amystery/
      base.merge(speaker_name: 'あみたろ') # 謎の人物
    when /\Agatekeeper/
      base.merge(speaker_name: 'あみたろ') # 門番
    when /\Ageneral/
      base.merge(speaker_name: 'あみたろ') # 将軍
    else
      base.merge(speaker_name: 'あみたろ') # ナレーション
    end
  end

  def synthesize(text, speaker)
    # speaker は今のところ使わないけど、既存の呼び出しと合わせて引数だけ残しておく

    uri = URI("#{STYLEBERT_HOST}/voice")

    params = {
      text: text,
      model_name: 'amitaro', # server_editor で試したモデル名
      speaker_name: 'あみたろ', # docs の speaker_name と同じ
      style: 'Neutral',
      language: 'JP',
      auto_split: true,
      split_interval: 0.5
      # 必要なら style_weight や length もここに追加できる
    }

    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)
    raise "Style-Bert TTS failed: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    res.body # audio/wav のバイナリ
  end
end
