Rails.application.routes.draw do
  root "pages#home"
  get "pages/:slug", to: "site#show", as: :site_page
  get "preferences-confidentialite/recu", to: "privacy_preferences#receipt", as: :privacy_receipt
  resource :privacy_preferences, path: "preferences-confidentialite", only: [ :show, :create ]
  resources :associations, param: :slug, only: [ :index, :show ]
  resources :volunteer_missions, path: "voyage-solidaire", param: :slug, only: [ :index, :show ]
  resources :partnerships, path: "partenaires", param: :slug, only: [ :index, :show ]
  get "organisations/invitation", to: "organization_invitations#show", as: :organization_invitation
  post "organisations/invitation", to: "organization_invitations#create"
  get "points-services", to: "points#show", as: :points_explanation
  get "confiance", to: "trust#show", as: :trust_explanation
  get "up" => "rails/health#show", as: :rails_health_check

  get "temoignages", to: "testimonials#index", as: :testimonials
  get "chaines/invitation", to: "chain_invitations#show", as: :chain_invitation
  post "chaines/invitation", to: "chain_invitations#create"
  post "stripe/webhook", to: "payment_webhooks#create"

  resources :listings, path: "annonces", param: :slug, only: [ :index, :show ]
  get "membres/:public_slug", to: "profiles#show", as: :profile
  get "medias/:id", to: "media#show", as: :media
  get "journal", to: "contents#index", as: :journal
  get "journal/:slug", to: "contents#show", defaults: { kind: "article" }, as: :article
  get "legal/:slug", to: "contents#show", defaults: { kind: "legal" }, as: :legal
  get "decouvrir/:slug", to: "contents#show", defaults: { kind: "page" }, as: :explanation
  get "contact", to: "contact_requests#new", as: :contact
  post "contact", to: "contact_requests#create"
  get "sitemap.xml", to: "seo#sitemap", defaults: { format: "xml" }, as: :sitemap
  get "robots.txt", to: "seo#robots", defaults: { format: "text" }

  devise_for :users, path: "auth", skip: :registrations, controllers: { sessions: "users/sessions", confirmations: "users/confirmations", omniauth_callbacks: "users/omniauth_callbacks" },
    path_names: { sign_in: "connexion", sign_out: "deconnexion", password: "mot-de-passe", confirmation: "confirmation" }
  devise_scope :user do
    get "auth/inscription", to: "users/registrations#new", as: :new_user_registration
    post "auth/inscription", to: "users/registrations#create", as: :user_registration
    get "compte/identifiants", to: "users/registrations#edit", as: :edit_user_registration
    patch "auth/inscription", to: "users/registrations#update"
    put "auth/inscription", to: "users/registrations#update"
  end

  namespace :account, path: "compte" do
    resource :privacy, path: "confidentialite", controller: "privacy", only: [ :show, :create ] do
      get :download
    end
    resources :organizations, path: "organisations", param: :slug, only: [ :index, :show, :create, :update ]
    resources :mission_applications, path: "candidatures", only: [ :index, :show, :create, :update ]
    resource :testimonials, path: "temoignages", controller: "testimonials", only: [ :show, :create ]
    resource :community, path: "engagement", controller: "community", only: [ :show, :create ]
    resources :chains, path: "chaines", only: [ :index, :show, :create, :update ]
    constraints ->(_request) { FeatureFlag.support_enabled? } do
      resource :support, path: "soutien", controller: "support", only: [ :show, :create ]
    end
    resource :points, path: "points", only: [ :show, :create ]
    resource :trust, path: "confiance", controller: "trust", only: [ :show, :create ]
    root "dashboard#show"
    resource :profile, path: "profil", only: [ :edit, :update ]
    resources :listings, path: "annonces", only: [ :index, :new, :create, :edit, :update ] do
      patch :transition, on: :member
    end
    resources :service_requests, path: "echanges", only: [ :index, :create, :show, :update ] do
      resources :messages, only: :create
      resources :reviews, only: :create
    end
    resources :reviews, only: [ :index, :update ]
    resources :notifications, only: [ :index, :update ] do
      patch :preferences, on: :collection
    end
    resources :favorites, path: "favoris", only: [ :index, :create, :destroy ]
    resources :comments, path: "commentaires", only: [ :create, :destroy ]
    resources :reports, path: "signalements", only: [ :new, :create ]
    resources :user_blocks, path: "blocages", only: [ :create, :destroy ]
    resources :login_sessions, path: "sessions", only: [ :index, :destroy ]
    resource :reauthentication, path: "verification", only: [ :new, :create ]
  end
  namespace :admin do
    resources :operations, only: [ :index, :create ] do
      match :user, via: [ :get, :post ], on: :member
    end
    resources :site, only: [ :index, :create, :edit, :update ] do
      get :visual, on: :member, to: "visual_studio#show"
      post :visual_preview, on: :member, to: "visual_studio#preview"
      post :visual_save, on: :member, to: "visual_studio#save"
      get :kit, on: :member
      get :new_page, on: :collection
      get :review, on: :member
      post :publish, on: :member
    end
    resources :studio, only: [ :index, :create ] do
      get :preview, on: :member
    end
    resources :privacy, path: "confidentialite", only: [ :index, :create ]
    resources :network, path: "organisations", only: [ :index, :create ]
    resources :community, path: "engagement", only: [ :index, :create ]
    resources :financial_support, path: "soutien", only: [ :index, :create ]
    resources :points, path: "points", only: [ :index, :create ]
    resources :trust, path: "confiance", only: [ :index, :create ] do
      get :risks, on: :collection
    end
    resources :workbench, path: "gestion/:kind", only: [ :index, :new, :create, :show, :update ] do
      post :reveal, on: :member
    end
    root "dashboard#show"
    resources :users, path: "membres", only: :index
    resources :audit_logs, path: "audit", only: :index
  end
  namespace :super_admin do
    resource :map_setting, path: "carte", only: [ :edit, :update ]
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
