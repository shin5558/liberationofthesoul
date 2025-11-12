# app/services/janken_judge_service.rb
class JankenJudgeService
  HANDS = %i[g t p].freeze
  RESULTS = {
    player_win: '勝ち',
    player_lose: '負け',
    draw: 'あいこ'
  }.freeze

  def self.resolve(player_hand, cpu_hand)
    return :invalid unless HANDS.include?(player_hand) && HANDS.include?(cpu_hand)

    case [player_hand, cpu_hand]
    when %i[g t], %i[t p], %i[p g]
      :player_win
    when %i[g p], %i[t g], %i[p t]
      :player_lose
    else
      :draw
    end
  end
end
