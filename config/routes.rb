Rails.application.routes.draw do
  root 'home#index'

  resources :characters, only: %i[new create]

  resources :battles, only: %i[new create show] do
    member do
      post :use_battle_card   # /battles/:id/use_battle_card
      get  :result            # /battles/:id/result
    end
  end
end
