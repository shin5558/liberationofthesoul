# app/services/turn_resolver_service.rb
#
# あいこ（draw）のときに、どの効果から処理するかを決めるサービス
# 優先度: 特殊 > 回復 > 補助 > 攻撃
class TurnResolverService
  # 小さいほど先に処理される
  DRAW_PRIORITY = {
    special: 0, # 先行権・必殺技など
    heal: 1, # 回復
    support: 2, # バフ／デバフ
    attack: 3 # ふつうの攻撃
  }.freeze

  # kind 別の分類
  SPECIAL_KINDS = %w[
    grant_priority
    # ここに将来 special_xxx みたいな必殺技系を足していける
  ].freeze

  HEAL_KINDS = %w[
    heal
  ].freeze

  SUPPORT_KINDS = %w[
    buff_attack
    buff_defense
    buff_speed
    debuff_attack
    debuff_defense
    debuff_speed
  ].freeze

  ATTACK_KINDS = %w[
    damage
  ].freeze

  # 引き分け時に、Effect の配列を「適用順」にソートする
  #
  # @param effects [Array<Effect>]
  # @return [Array<Effect>] ソート済み
  def self.sort_effects_for_draw(effects)
    effects.sort_by do |effect|
      [
        priority_group(effect), # 特殊/回復/補助/攻撃 の優先度
        target_priority(effect), # プレイヤー優先
        effect.priority || 0,        # 同じグループ内で priority が小さい方を先に
        effect.id || 0               # それでも同じなら ID で安定ソート
      ]
    end
  end

  # 1つの Effect がどのグループ（special/heal/support/attack）かを返す
  def self.priority_group(effect)
    kind_str = effect.kind.to_s

    if SPECIAL_KINDS.include?(kind_str)
      DRAW_PRIORITY[:special]
    elsif HEAL_KINDS.include?(kind_str)
      DRAW_PRIORITY[:heal]
    elsif SUPPORT_KINDS.include?(kind_str)
      DRAW_PRIORITY[:support]
    elsif ATTACK_KINDS.include?(kind_str)
      DRAW_PRIORITY[:attack]
    else
      # 未知の kind はいちばん後ろに回す
      DRAW_PRIORITY[:attack]
    end
  end

  # 同じkind内での優先度（プレイヤーを優先）
  def self.target_priority(effect)
    # プレイヤー側をより先に処理したいので数値は小さくする
    case effect.target.to_s
    when 'player'
      0
    when 'enemy'
      1
    else
      2
    end
  end
end
