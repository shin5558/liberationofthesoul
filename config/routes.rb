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

  # ★ 追加：A画面が見る「現在モード」API
  get 'screen/mode', to: 'screens#mode'

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
    post :go_gatekeeper
    post :go_general
    get :after_gatekeeper
    get :after_general
    get :warehouse
    get :demonlord_intro
    post :go_demonlord
    get :ending
  end

  # ボイス
  get 'voices/prologue',     to: 'voices#prologue'
  get 'voices/branch1',      to: 'voices#branch1'
  get 'voices/goblin_intro', to: 'voices#goblin_intro'
  get 'voices/thief_intro',  to: 'voices#thief_intro'
end
