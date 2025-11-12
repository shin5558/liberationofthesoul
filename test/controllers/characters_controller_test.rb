# test/controllers/characters_controller_test.rb
require 'test_helper'

class CharactersControllerTest < ActionDispatch::IntegrationTest
  test 'GET /characters/new が200' do
    get new_character_url
    assert_response :success
  end

  test 'POST /characters でPlayerが作成される' do
    element = Element.create!(code: 'fire', name: 'Fire')
    assert_difference -> { Player.count }, +1 do
      post characters_url, params: { character: { name: 'Hero', element_id: element.id } }
    end
    assert_redirected_to new_battle_path(player_id: Player.last.id) # 今の遷移仕様に合わせる
  end
end
