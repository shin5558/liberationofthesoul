# == Schema Information
#
# Table name: elements
#
#  id         :bigint           not null, primary key
#  code       :string(255)      not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_elements_on_code  (code) UNIQUE
#
require "test_helper"

class ElementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
