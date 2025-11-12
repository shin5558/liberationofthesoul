require 'test_helper'

class BattlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = Player.first || Player.create!(name: 'Hero',
                                             element: Element.first || Element.create!(code: 'fire', name: 'Fire'), base_hp: 5, meta: {})
    @enemy  = Enemy.first  || Enemy.create!(name: 'Slime', element: Element.first, base_hp: 5, boss: false, flags: {},
                                            description: 'test')
  end

  test 'GET /battles/new が 200' do
    get new_battle_url(player_id: @player.id)
    assert_response :success
  end

  test 'POST /battles で作成→show にリダイレクト' do
    post battles_url, params: { player_id: @player.id, hand: 'g' }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select 'body', /あなたの手|結果|バトル/ # ざっくり表示確認
  end
end
