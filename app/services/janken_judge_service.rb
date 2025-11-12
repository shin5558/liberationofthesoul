# frozen_string_literal: true

class JankenJudgeService
  HANDS = %i[g t p].freeze # g=グー, t=チョキ, p=パー

  # 戻り値: :player_win | :cpu_win | :draw
  def self.resolve(player_hand, cpu_hand)
    p = normalize(player_hand)
    c = normalize(cpu_hand)

    validate!(p, c)

    return :draw if p == c

    case [p, c]
    when %i[g t], %i[t p], %i[p g]
      :player_win
    else
      :cpu_win
    end
  end

  def self.normalize(hand)
    return nil if hand.nil?

    h = hand.is_a?(String) ? hand.strip.downcase : hand
    h.to_sym
  end
  private_class_method :normalize

  def self.validate!(*hands)
    hands.each do |h|
      raise ArgumentError, "invalid hand: #{h.inspect}" unless HANDS.include?(h)
    end
  end
  private_class_method :validate!
end
