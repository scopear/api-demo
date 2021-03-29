Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: 'public#index'

  get '/demo' => 'public#demo', as: :demo
  post '/save_configuration' => 'public#save_configuration', as: :save_configuration
  post '/reset_configuration' => 'public#reset_configuration', as: :reset_configuration

  resources :webhooks, only: [] do
    collection do
      get :recent
      post :receive
    end
  end

  resources :scenario_sessions, only: [:create]
end
