Rails.application.routes.draw do
  match "/users/auth/saml/callback",
  to: "sessions#saml",
  via: :post,
  as: :saml_callback

  get "/session/new",
    to: "sessions#new",
    as: :new_session

  delete "/session",
    to: "sessions#destroy",
    as: :session

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "bound_withs#new"

  post "bound_withs/create_with_selected_holding",
    to: "bound_withs#create_with_selected_holding",
    as: :create_with_selected_holding

  post "bound_withs",
    to: "bound_withs#create",
    as: :bound_withs


  get "bound_withs/success",
    to: "bound_withs#success",
    as: :bound_with_success

  get "help", to: "pages#help", as: :help

  resources :marc_records, only: :show do
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
