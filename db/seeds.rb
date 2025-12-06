# ==============================
# Elements
# ==============================
%w[fire water wind earth light dark neutral].each do |c|
  Element.find_or_create_by!(code: c) do |e|
    e.name = c.capitalize
  end
end

fire    = Element.find_by!(code: 'fire')
water   = Element.find_by!(code: 'water')
wind    = Element.find_by!(code: 'wind')
earth   = Element.find_by!(code: 'earth')
light   = Element.find_by!(code: 'light')
dark    = Element.find_by!(code: 'dark')
neutral = Element.find_by!(code: 'neutral')

# ==============================
# 不要カード削除（4枚以外は消す）
# ==============================
keep_names = ['Wind Storm', 'Water Heal', 'Rising Power', 'Earth Wall']
Card.where.not(name: keep_names).destroy_all

# ==============================
# Player & Enemies
# ==============================
hero = Player.find_or_create_by!(name: 'Hero') do |p|
  p.element = fire
  p.base_hp = 5
  p.meta    = {}
end

slime = Enemy.find_or_create_by!(name: 'Slime') do |e|
  e.element     = water
  e.base_hp     = 5
  e.boss        = false
  e.flags       = {}
  e.description = 'test enemy'
end

goblin = Enemy.find_or_create_by!(name: 'Goblin') do |e|
  e.element     = earth
  e.base_hp     = 7
  e.boss        = false
  e.flags       = {}
  e.description = '物理攻撃が得意なゴブリン'
end

dragon_pup = Enemy.find_or_create_by!(name: 'Dragon Pup') do |e|
  e.element     = fire
  e.base_hp     = 10
  e.boss        = true
  e.flags       = {}
  e.description = '小さなドラゴンだが HP が高い'
end

# ==============================
# Effects（攻撃 / 回復 / バフ / 先行権 / 攻撃無効）
# ==============================

# ダメージ
atk = Effect.find_or_create_by!(name: 'DealDamage') do |eff|
  eff.kind           = :damage       # enum
  eff.target         = :enemy
  eff.value          = 1             # 基本ダメージ（formulaで上書きしてもOK）
  eff.priority       = 0
  eff.formula        = 'damage = power * magnitude'
  eff.duration_turns = 0
end

# 自分を1回復
heal_self = Effect.find_or_create_by!(name: 'HealSelf') do |eff|
  eff.kind           = :heal
  eff.target         = :player
  eff.value          = 1
  eff.priority       = 0
  eff.formula        = 'value'
  eff.duration_turns = 0
end

# 攻撃力 +1（1ターン）
buff_atk_1t = Effect.find_or_create_by!(name: 'BuffAttack1T') do |eff|
  eff.kind           = :buff_attack
  eff.target         = :player
  eff.value          = 1
  eff.priority       = 0
  eff.formula        = 'value'
  eff.duration_turns = 1
end

# 先行権 1ターン付与
grant_priority_1t = Effect.find_or_create_by!(name: 'GrantPriority1T') do |eff|
  eff.kind           = :grant_priority
  eff.target         = :player
  eff.value          = 0
  eff.priority       = 0
  eff.formula        = 'value'
  eff.duration_turns = 1
end

# 敵の攻撃を1ターンに1回だけ無効にする（土の壁）
earth_wall_effect = Effect.find_or_create_by!(name: 'EarthWallBlock1T') do |eff|
  eff.kind           = :block_attack   # ★ Effect.kind の enum に :block_attack を追加しておくこと
  eff.target         = :player         # 自分への攻撃を守る
  eff.value          = 1               # 無効化できる攻撃回数
  eff.priority       = 0
  eff.formula        = 'block_attack'  # 実際のロジック側で判定に使うラベル的な文字列
  eff.duration_turns = 1               # 1ターン有効
end

# ==============================
# Cards（4枚だけを seed で保証）
# ==============================

# Wind Storm：敵に1ダメージ
wind_storm = Card.find_or_initialize_by(name: 'Wind Storm')
wind_storm.update!(
  element: wind,
  hand_type: :g,
  power: 1, # damage = power * magnitude なので 1ダメージ
  rarity: 1,
  description: '風の力で敵に1ダメージを与える'
)

# Water Heal：自分のHPを1回復
water_heal = Card.find_or_initialize_by(name: 'Water Heal')
water_heal.update!(
  element: water,
  hand_type: :p,
  power: 0,
  rarity: 1,
  description: '自分のHPを1回復する水のカード'
)

# Rising Power：このターン攻撃+1
rising_power = Card.find_or_initialize_by(name: 'Rising Power')
rising_power.update!(
  element: wind,
  hand_type: :t,
  power: 0,
  rarity: 2,
  description: 'このターンの攻撃力が1上がる'
)

# Earth Wall：このターン、敵の攻撃を1回無効
earth_wall_card = Card.find_or_initialize_by(name: 'Earth Wall')
earth_wall_card.update!(
  element: earth,
  hand_type: :g, # 好きな手でOK。ここではグーにしておく
  power: 0,
  rarity: 2,
  description: 'このターン、敵の攻撃を1回無効にする土の防御カード'
)

# ==============================
# CardEffects（カードに効果を紐付け）
# ==============================

def attach_effect(card, effect, position: 1, magnitude: 1.0)
  CardEffect.find_or_create_by!(card: card, effect: effect) do |ce|
    ce.magnitude     = magnitude
    ce.order_in_card = 0
    ce.position      = position
  end
end

# Wind Storm → DealDamage（1ダメージ）
attach_effect(wind_storm, atk, position: 1, magnitude: 1.0)

# Water Heal → 自分を1回復
attach_effect(water_heal, heal_self, position: 1)

# Rising Power → 攻撃+1(1T)
attach_effect(rising_power, buff_atk_1t, position: 1)

# Earth Wall → 敵の攻撃を1回ブロック
attach_effect(earth_wall_card, earth_wall_effect, position: 1, magnitude: 1.0)

puts 'Seed done.'
puts "Elements: #{Element.count}, Enemies: #{Enemy.count}, Cards: #{Card.count}, Effects: #{Effect.count}, CardEffects: #{CardEffect.count}"

# ============================
# 故事シナリオ用 敵データ登録
# ============================

puts '=== Registering Story Enemies ==='

story_enemies = [
  {
    name: 'Goblin',
    code: 'goblin',
    base_hp: 5,
    boss: false,
    element: neutral,
    description: '街道沿いに現れる小柄なゴブリン'
  },
  {
    name: 'Thief',
    code: 'thief',
    base_hp: 5,
    boss: false,
    element: neutral,
    description: '旅人を襲う悪名高い盗賊'
  },
  {
    name: 'Gatekeeper',
    code: 'gatekeeper',
    base_hp: 5,
    boss: false,
    element: earth,
    description: '城門を守る屈強な門番'
  },
  {
    name: 'General',
    code: 'general',
    base_hp: 5,
    boss: false,
    element: fire,
    description: '王国最強と名高い将軍（真エンディング条件2）'
  },
  {
    name: 'Demon Lord',
    code: 'demonlord',
    base_hp: 5,
    boss: true,
    element: dark,
    description: '魔王。全ての戦いの頂点に立つ存在'
  }
]

story_enemies.each do |attrs|
  enemy = Enemy.find_or_initialize_by(code: attrs[:code])
  enemy.name        = attrs[:name]
  enemy.base_hp     = attrs[:base_hp]
  enemy.boss        = attrs[:boss]
  enemy.element     = attrs[:element]
  enemy.description = attrs[:description]
  enemy.flags     ||= {}
  enemy.save!
  puts "✓ #{enemy.name} (#{enemy.code}) registered/updated"
end

puts '=== Story Enemies Done ==='
