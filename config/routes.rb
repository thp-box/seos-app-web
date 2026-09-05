Rails.application.routes.draw do
  root "pages#home"
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, path: "auth", skip: :registrations, controllers: { sessions: "users/sessions", confirmations: "users/confirmations" },
    path_names: { sign_in: "connexion", sign_out: "deconnexion", password: "mot-de-passe", confirmation: "confirmation" }
  devise_scope :user do
    get "auth/inscription", to: "users/registrations#new", as: :new_user_registration
    post "auth/inscription", to: "users/registrations#create", as: :user_registration
    get "compte/identifiants", to: "users/registrations#edit", as: :edit_user_registration
    patch "auth/inscription", to: "users/registrations#update"
    put "auth/inscription", to: "users/registrations#update"
  end

  namespace :account, path: "compte" do
    root "dashboard#show"
    resources :login_sessions, path: "sessions", only: [ :index, :destroy ]
    resource :reauthentication, path: "verification", only: [ :new, :create ]
  end
  namespace :admin do
    root "dashboard#show"
    resources :users, path: "membres", only: :index
    resources :audit_logs, path: "audit", only: :index
  end
  namespace :super_admin do
    root "dashboard#show"
    resources :administrators, path: "administrateurs", only: [ :index, :update ] do
      resources :permission_grants, path: "permissions", only: [ :create, :destroy ]
    end
  end
  scope "organisations/:organization_slug/espace", module: :organizations, as: :organization do
    get "/", to: "dashboard#show", as: :dashboard
    get "/equipe", to: "dashboard#team", as: :team
  end
end
