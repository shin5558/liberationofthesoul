# config/routes.rb
Rails.application.routes.draw do
  # get 'battles/new'
  # get 'battles/create'
  root 'home#index'

  # キャラクター作成への導線（new, create は今後使うので先に定義）
  resources :characters, only: %i[new create]
  # resources :battles, only: %i[new create show]
  resources :battles, only: %i[new create show] do
    member do
      post :use_neutral_card # ★ここに追加！
      get :result # /battles/:id/result → battles#result
    end
  end
end
