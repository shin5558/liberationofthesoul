# config/routes.rb
Rails.application.routes.draw do
  root 'home#index'

  # キャラクター作成への導線（new, create は今後使うので先に定義）
  resources :characters, only: %i[new create]
end
