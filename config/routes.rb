Rails.application.routes.draw do
  # ===== B：タイトル（操作側）=====
  root 'titles#show'

  get 'start_game', to: 'titles#start_game', as: :start_game
  get 'reset', to: 'titles#reset', as: :reset

  # ===== A：スクリーン用（表示側）=====
  get 'screen/title', to: 'screens#title', as: :screen_title
  get 'screen/character', to: 'screens#character', as: :screen_character
  get 'screen/summary',   to: 'screens#summary',   as: :screen_summary # ★追加
  get 'screen/battle', to: 'screens#battle', as: :screen_battle
  get 'screen/prologue', to: 'screens#prologue', as: :screen_prologue
  get 'screen/ending_true', to: 'screens#ending_true', as: :screen_ending_true
  # ★ 追加：A画面が見る「現在モード」API
  get 'screen/mode', to: 'screens#mode'
  get '/screen/state', to: 'screens#state', as: :screen_state
  # ===== キャラクター =====
  resources :characters, only: %i[new create]

  # A：ストーリー用スクリーン
  get 'screen/story', to: 'screens#story', as: :screen_story

  # ===== バトル（2画面＋通常ルート）=====
  resources :battles, only: %i[new create show] do
    member do
      get :view_screen
      get :control_screen
      post :use_battle_card
      get  :result
    end
  end

  # ===== ストーリー（2画面＋既存ルート）=====
  resource :story, only: [] do
    get :view_screen      # A画面：立ち絵＋背景
    get :control_screen   # B画面：セリフ＋選択肢
    get  :npc_intro
    post :npc_talk
    get  :decide_element
    post :npc_reply
    post :npc_finish
    get :character_summary # ← キャラ作成結果の画面
    get :prologue
    get :branch1_choice
    get  :goblin_intro
    get  :thief_intro
    post :go_goblin
    post :go_thief
    get :after_goblin
    get :after_thief
    get :branch2_choice
    # 分岐2（城下のA/B）
    get  :gatekeeper_intro          # 2-A用：門番導入
    get  :princess_meeting          # 2-B用：魔姫イベント
    post :go_gatekeeper             # 2-A：門番ルートへ
    post :go_princess               # 2-B：魔姫ルートへ
    # 分岐3（魔姫ルート内のA/B）
    get  :gatekeeper_from_princess  # 3-B専用：魔姫と別れた後の門番導入
    get  :general_intro             # 3-A専用：将軍導入
    post :go_general_from_princess      # 3-A：目的が同じなら手を貸す
    post :go_gatekeeper_from_princess   # 3-B：魔族には手を貸せない
    get :after_gatekeeper
    get :after_general
    get :warehouse_gate      # 門番ルートの倉庫
    get :warehouse_general   # 将軍ルートの倉庫
    get :demonlord_intro
    get :ending
    # ★ 追加：真エンド3段階
    get :ending_true_step1
    get :ending_true_message
    get :ending_true_after
    get :game_over
  end

  # ボイス
  get 'voices/prologue',     to: 'voices#prologue'
  get 'voices/branch1',      to: 'voices#branch1'
  get 'voices/goblin_intro', to: 'voices#goblin_intro'
  get 'voices/thief_intro',  to: 'voices#thief_intro'
  get 'voices/after_goblin', to: 'voices#after_goblin'
  get 'voices/after_thief', to: 'voices#after_thief'
  get 'voices/branch2', to: 'voices#branch2'
  get 'voices/gatekeeper_intro', to: 'voices#gatekeeper_intro'
  get 'voices/princess_meeting', to: 'voices#princess_meeting'
  get 'voices/general_intro', to: 'voices#general_intro'
  get 'voices/gatekeeper_from_princess', to: 'voices#gatekeeper_from_princess'
  get 'voices/after_gatekeeper', to: 'voices#after_gatekeeper'
  get 'voices/after_general', to: 'voices#after_general'
  get 'voices/warehouse_gate', to: 'voices#warehouse_gate'
  get 'voices/warehouse_general', to: 'voices#warehouse_general'
  get 'voices/demonlord_intro', to: 'voices#demonlord_intro'
  get 'voices/ending_bad', to: 'voices#ending_bad'
  get 'voices/ending_normal', to: 'voices#ending_normal'
  get 'voices/ending_true', to: 'voices#ending_true'
end
