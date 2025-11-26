Rails.application.routes.draw do
  # トップページ & /home の両方がキャラ作成
  root 'characters#new'
  get 'home', to: 'characters#new'

  resources :characters, only: %i[new create]

  resources :battles, only: %i[new create show] do
    member do
      post :use_battle_card
      get  :result
    end
  end

  resource :story, only: [] do
    get :prologue
    get :branch1_choice
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

    # ▼ キャラ作成後の NPC 会話 & 属性決定
    get  :npc_intro      # 会話画面表示
    post :npc_talk       # プレイヤーの発言を送信（AI返答もここでやる形ならこれだけでOK）
    get :decide_element # ← もし今使っていなければ、あとで消してもOK
    post :npc_reply      # ← コントローラで使ってなければ消してOK
    post :npc_finish     # 会話終了 → 要約 & 画像生成
  end
end
