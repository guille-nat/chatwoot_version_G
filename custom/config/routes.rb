# Full CoopFlow route tree (design §3.2). Loaded via
# config.paths['config/routes.rb'] << 'custom/config/routes.rb' in
# config/application.rb -- config/routes.rb itself has zero diff.
#
# Controllers arrive incrementally across S2-S7; Rails route recognition does
# not require the controller classes to exist yet.
Rails.application.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :accounts, only: [] do
        scope module: :accounts do
          namespace :coop do
            resources :modules, only: [:index, :update], param: :key
            resources :branches
            resources :staff_roles
            resources :staff_profiles
            resources :producers do
              resource :contact_link, only: [:create, :destroy]
              resources :fields, only: [:index, :create]
              get :export, on: :collection
            end
            resources :fields, only: [:show, :update, :destroy] do
              resources :plots, only: [:index, :create]
            end
            resources :plots, only: [:show, :update, :destroy] do
              resources :crops, only: [:index, :create]
            end
            resources :crops, only: [:show, :update, :destroy]
            resources :conversations, only: [] do
              resource :producer, only: [:show], controller: 'conversations/producer'
            end
            resources :audit_logs, only: [:index]
            resources :event_subscriptions
          end
        end
      end
    end
  end
end
