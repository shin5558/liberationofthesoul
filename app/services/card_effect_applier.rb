# app/services/card_effect_applier.rb
class CardEffectApplier
  def self.apply(battle:, card:)
    new(battle, card).apply
  end

  def initialize(battle, card)
    @battle = battle
    @card   = card
  end

  def apply
    # position 順にすべての効果を適用
    @card.card_effects.includes(:effect).order(:position).each do |ce|
      effect = ce.effect
      next unless effect

      apply_one_effect(effect)
    end

    # 適用履歴を flags に残す
    @battle.flags ||= {}
    (@battle.flags['cards'] ||= []) << @card.id
    @battle.save!

    @battle
  end

  private

  def apply_one_effect(effect)
    kind   = effect.kind.to_sym     # :damage / :heal / ...
    target = effect.target.to_sym   # :player / :enemy / ...

    case kind
    when :damage
      apply_damage(target, effect.value)
    when :heal
      apply_heal(target, effect.value)
    else
      # まだ対応していない kind はスキップ
    end
  end

  def apply_damage(target, value)
    case target
    when :enemy
      @battle.damage_enemy!(value)
    when :player
      @battle.damage_player!(value)
    end
  end

  def apply_heal(target, value)
    case target
    when :enemy
      @battle.heal_enemy!(value)
    when :player
      @battle.heal_player!(value)
    end
  end
end
