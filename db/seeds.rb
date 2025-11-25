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
neutral = Element.find_by!(code: 'neutral')

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
# Effects（攻撃 / 回復 / バフ / 先行権）
# ==============================

# 既存のダメージ用 Effect（名前はそのまま再利用）
atk = Effect.find_or_create_by!(name: 'DealDamage') do |eff|
  eff.kind           = :damage # enum
  eff.target         = :enemy
  eff.value          = 2
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

# ==============================
# Cards
# ==============================

# 既存の「Flame Punch」カード
punch = Card.find_or_create_by!(name: 'Flame Punch') do |c|
  c.element     = fire
  c.hand_type   = :g # 0
  c.power       = 2
  c.rarity      = 1
  c.description = '火のパンチ'
end

# 回復カード
heal_card = Card.find_or_create_by!(name: 'Water Heal') do |c|
  c.element     = water
  c.hand_type   = :p
  c.power       = 0
  c.rarity      = 1
  c.description = '自分を1回復する水のカード'
end

# 攻撃バフカード
buff_card = Card.find_or_create_by!(name: 'Rising Power') do |c|
  c.element     = wind
  c.hand_type   = :t
  c.power       = 0
  c.rarity      = 2
  c.description = 'このターンの攻撃力が1上がる'
end

# 無属性カード（戦闘前用）
neutral_card = Card.find_or_create_by!(name: 'Neutral Demo Card') do |c|
  c.element     = nil # ★ 無属性
  c.hand_type   = :g
  c.power       = 0
  c.rarity      = 1
  c.description = '戦闘前に使えるデモ用カード'
end

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

# Flame Punch → ダメージ
attach_effect(punch, atk, position: 1, magnitude: 2.0)

# Water Heal → 自分を1回復
attach_effect(heal_card, heal_self, position: 1)

# Rising Power → 攻撃+1(1T)
attach_effect(buff_card, buff_atk_1t, position: 1)

# Neutral Demo Card → 先行権 1T
attach_effect(neutral_card, grant_priority_1t, position: 1)

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
    element_id: 7, # Neutral
    description: '街道沿いに現れる小柄なゴブリン'
  },
  {
    name: 'Thief',
    code: 'thief',
    base_hp: 5,
    boss: false,
    element_id: 7, # Neutral
    description: '旅人を襲う悪名高い盗賊'
  },
  {
    name: 'Gatekeeper',
    code: 'gatekeeper',
    base_hp: 5,
    boss: false,
    element_id: 4, # Earth
    description: '城門を守る屈強な門番'
  },
  {
    name: 'General',
    code: 'general',
    base_hp: 5,
    boss: false,
    element_id: 1, # Fire
    description: '王国最強と名高い将軍（真エンディング条件2）'
  },
  {
    name: 'Demon Lord',
    code: 'demonlord',
    base_hp: 5,
    boss: true,
    element_id: 6, # Dark
    description: '魔王。全ての戦いの頂点に立つ存在'
  }
]

story_enemies.each do |attrs|
  enemy = Enemy.find_or_initialize_by(code: attrs[:code])
  enemy.name        = attrs[:name]
  enemy.base_hp     = attrs[:base_hp]
  enemy.boss        = attrs[:boss]
  enemy.element_id  = attrs[:element_id]
  enemy.description = attrs[:description]
  enemy.flags     ||= {}
  enemy.save!
  puts "✓ #{enemy.name} (#{enemy.code}) registered/updated"
end

puts '=== Story Enemies Done ==='
