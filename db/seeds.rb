%w[fire water wind earth light dark neutral].each do |c|
  Element.find_or_create_by!(code: c, name: c.capitalize)
end

fire  = Element.find_by!(code: 'fire')
water = Element.find_by!(code: 'water')

hero  = Player.find_or_create_by!(name: 'Hero') do |p|
  p.element = fire
  p.base_hp = 5
  p.meta = {}
end
slime = Enemy.find_or_create_by!(name: 'Slime') do |e|
  e.element = water
  e.base_hp = 5
  e.boss = false
  e.flags = {}
  e.description = 'test enemy'
end

punch = Card.find_or_create_by!(name: 'Flame Punch', element: fire, hand_type: 0, power: 2, rarity: 1,
                                description: '火のパンチ')
atk = Effect.find_or_create_by!(name: 'DealDamage', kind: 0, priority: 0, formula: 'damage = power * magnitude',
                                duration_turns: 0)
CardEffect.find_or_create_by!(card: punch, effect: atk) do |ce|
  ce.magnitude = 2.0
  ce.order_in_card = 0
end
