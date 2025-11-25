Rails.application.routes.draw do
  # トップページ & /home の両方がプロローグ
  root 'stories#prologue'
  get 'home', to: 'stories#prologue'

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
  end
end
