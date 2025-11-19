# README

🧙‍♂️ ゲームの流れ（じゃんけん〜バトル）

① キャラクター作成
	•	名前を入力
	•	属性を選択
	•	「キャラクター作成」を押す
→ 自動でバトル画面へ遷移します

⸻

② バトル開始（/battles/new）
	•	無属性カードがあれば 戦闘前のみ使用可能
	•	グー / チョキ / パー のいずれかを選択してターン開始

⸻

③ じゃんけんの結果

プレイヤー勝利　敵 HP -1
敵の勝利　プレイヤー HP -1
あいこ　プレイヤー HP +1 （最大まで） + 補助効果優先処理

④ バフ・特殊効果の処理
	•	補助効果（攻撃力・防御力UP/DOWN）
	•	先行権（イニシアチブ）
	•	無属性カード効果
	•	あいこ時の優先度反映

⑤ HP が 0 になると決着
	•	プレイヤー HP = 0 → 敗北
	•	敵 HP = 0 → 勝利

リザルト画面に遷移し、
	•	勝敗
	•	経過ターン
	•	各ターンのログ
を確認できます。



## ⚙️ 開発環境
- Ruby 3.x  
- Rails 7.1.6  
- MySQL 8.x  
- Bundler 2.x  

---

## 🧩 データベース設計

### elements テーブル
| Column | Type   | Options                   |
|--------|--------|---------------------------|
| code   | string | null: false, unique: true |
| name   | string | null: false               |

---

### players テーブル
| Column     | Type       | Options                 |
|------------|------------|-------------------------|
| name       | string     | null: false             |
| element_id | references | foreign_key: true       |
| base_hp    | integer    | null: false, default: 5 |
| meta       | json       | null: false             |

---

### enemies テーブル
| Column      | Type       | Options                 |
|-------------|------------|-------------------------|
| name        | string     | null: false             |
| element_id  | references | foreign_key: true       |
| base_hp     | integer    | null: false, default: 5 |
| boss        | boolean    | default: false          |
| flags       | json       | null: false             |
| description | text       |                         |

---

### cards テーブル
| Column      | Type       | Options           |
|-------------|------------|-------------------|
| name        | string     | null: false       |
| element_id  | references | foreign_key: true |
| hand_type   | integer    | null: false       |
| power       | integer    | null: false       |
| rarity      | integer    | null: false       |
| description | text       |                   |

---

### effects テーブル
| Column  | Type    | Options     |
|---------|---------|-------------|
| name    | string  | null: false |
| kind    | integer | null: false |
| value   | integer |             |
| formula | string  |             |

---

### card_effects テーブル
| Column    | Type.      | Options                        |
|-----------|------------|--------------------------------|
| card_id   | references | null: false, foreign_key: true |
| effect_id | references | null: false, foreign_key: true |

---

### battles テーブル
| Column      | Type       | Options                        |
|-------------|------------|--------------------------------|
| player_id   | references | null: false, foreign_key: true |
| enemy_id    | references | null: false, foreign_key: true |
| status      | integer    | null: false, default: 0        |
| turns_count | integer    | null: false, default: 0        |
| flags       | json       | null: false                    |
| started_at  | datetime   |                                |
| ended_at    | datetime   |                                |

---

### battle_turns テーブル
| Column           | Type       | Options                        |
|------------------|------------|--------------------------------|
| battle_id        | references | null: false, foreign_key: true |
| turn_no          | integer    | null: false                    |
| player_hand_type | integer    | null: false                    |
| enemy_hand_type  | integer    | null: false                    |
| first_attacker   | integer    | null: false                    |
| outcome          | integer    | null: false                    |
| resolved_at      | datetime   |                                |
---

### battle_actions テーブル
| Column         | Type       | Options                        |
|----------------|------------|--------------------------------|
| battle_turn_id | references | null: false, foreign_key: true |
| card_id        | references | foreign_key: true              |
| actor          | integer    | null: false                    |
| target         | integer    | null: false                    |
| damage         | integer    |                                |
| result         | string     |                                |

---

### npc_characters テーブル
| Column     | Type       | Options           |
|------------|------------|-------------------|
| name       | string     | null: false       |
| element_id | references | foreign_key: true |
| role       | string     |                   |

---

### npc_lines テーブル
| Column           | Type       | Options                        |
|------------------|------------|--------------------------------|
| npc_character_id | references | null: false, foreign_key: true |
| effect_id        | references | foreign_key: true              |
| content          | text       | null: false                    |
| trigger          | string     |                                |

---

## 🔗 リレーション概要
- Element  
  ↳ has_many :players, :enemies, :cards  
- Player, Enemy  
  ↳ belongs_to :element  
  ↳ has_many :battles  
- Battle  
  ↳ has_many :battle_turns  
- Card  
  ↳ has_many :effects, through: :card_effects  
- NPCCharacter  
  ↳ has_many :npc_lines  
