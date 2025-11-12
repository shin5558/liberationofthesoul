# == Schema Information
#
# Table name: effects
#
#  id             :bigint           not null, primary key
#  duration_turns :integer
#  formula        :text(65535)      not null
#  kind           :integer          default("attack"), not null
#  name           :string(255)      not null
#  priority       :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require "test_helper"

class EffectTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
