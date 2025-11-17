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
    when :buff_attack, :buff_defense, :buff_speed,
         :debuff_attack, :debuff_defense, :debuff_speed
      apply_buff_like(effect)
    else
      Rails.logger.warn "[CardEffectApplier] Unknown effect kind: #{effect.kind}"
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
      # 敵の回復は無効化
      Rails.logger.info("[CardEffectApplier] Skipped enemy heal (value=#{value})")
    when :player
      @battle.heal_player!(value)
    end
  end

  # === 追加: バフ／デバフ系処理 ===
  def apply_buff_like(effect)
    side =
      case effect.target.to_sym
      when :player then :player
      when :enemy  then :enemy
      else              :player
      end

    stat =
      case effect.kind.to_sym
      when :buff_attack, :debuff_attack then :attack
      when :buff_defense, :debuff_defense then :defense
      when :buff_speed, :debuff_speed then :speed
      else
        :attack
      end

    amount = effect.value.to_i
    amount = -amount if effect.kind.to_s.start_with?('debuff_')

    duration = effect.duration_turns.to_i
    duration = 1 if duration <= 0

    @battle.add_buff!(side: side, stat: stat, amount: amount, duration_turns: duration)
  end
end
