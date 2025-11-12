# frozen_string_literal: true

require 'test_helper'

class JankenJudgeServiceTest < ActiveSupport::TestCase
  # 期待する戻り値：
  # :player_win, :cpu_win, :draw
  #
  # 前提：
  # JankenJudgeService.resolve(player_hand, cpu_hand)

  def test_g_beats_t
    assert_equal :player_win, JankenJudgeService.resolve(:g, :t)
    assert_equal :cpu_win,    JankenJudgeService.resolve(:t, :g)
  end

  def test_t_beats_p
    assert_equal :player_win, JankenJudgeService.resolve(:t, :p)
    assert_equal :cpu_win,    JankenJudgeService.resolve(:p, :t)
  end

  def test_p_beats_g
    assert_equal :player_win, JankenJudgeService.resolve(:p, :g)
    assert_equal :cpu_win,    JankenJudgeService.resolve(:g, :p)
  end

  def test_draw_patterns
    assert_equal :draw, JankenJudgeService.resolve(:g, :g)
    assert_equal :draw, JankenJudgeService.resolve(:t, :t)
    assert_equal :draw, JankenJudgeService.resolve(:p, :p)
  end

  def test_symbol_and_string_inputs
    # 文字列でも解釈できる仕様にしている場合のみ（そうでなければ削除）
    assert_equal :player_win, JankenJudgeService.resolve('g', 't')
  end

  def test_invalid_inputs
    # 不正入力時の挙動は実装に合わせて調整
    # 例) ArgumentError を投げる仕様にする
    assert_raises(ArgumentError) { JankenJudgeService.resolve(:x, :g) }
    assert_raises(ArgumentError) { JankenJudgeService.resolve(:g, :x) }
    assert_raises(ArgumentError) { JankenJudgeService.resolve(nil, :g) }
  end
end
