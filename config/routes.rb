require "que/web"

Rails.application.routes.draw do
  health_check_routes

  constraints host: Rails.configuration.x.domains.admin do
    constraints AdminAuthConstraint.new do
      mount Que::Web, at: "/que"
      mount Flipper::UI.app(Flipper) => "/flipper"
    end

    mount Trestle::Engine => Trestle.config.path
  end

  if Rails.env.integration_test? || Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"

    scope "test_support" do
      post "clean", to: "test_support#clean"
      post "force_login", to: "test_support#force_login"
      post "empty_account", to: "test_support#empty_account"
    end
  end

  constraints host: Rails.configuration.x.domains.app do
    # Auth area configuration where users login and register to the system.
    # Some API is managed by devise and some is is managed by graphql right now.
    devise_for :users, path: "/auth/api", skip: ["registration"], controllers: {
                         sessions: "auth/sessions",
                         invitations: "auth/invitations",
                         confirmations: "auth/confirmations",
                         passwords: "auth/passwords",
                         unlocks: "auth/unlocks",
                       }

    namespace "auth" do
      scope "api" do
        post "sign_up", to: "sign_ups#sign_up"
      end

      mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "graphql"
      post "/graphql", to: "graphql#execute"

      get "/accept_invite", to: "client_side_app#index", as: :accept_invitation
      get "*path", to: "client_side_app#index"
      root to: "client_side_app#index"
    end

    namespace "connections" do
      post "/plaid/webhooks", to: "plaid_webhooks#process", as: :plaid_webhook
    end

    scope module: :app do
      get "/connection_auth/:provider/callback", to: "connection_sessions#create"

      mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "graphql", as: "app_graphiql"
      post "/graphql", to: "graphql#execute"

      # Forward all the other requests to the edit area client side router
      get "*path", to: "client_side_app#index", as: "app_client_side_app"
      root to: "client_side_app#index", as: "app_root"
    end
  end
end
