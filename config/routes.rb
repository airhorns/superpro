Rails.application.routes.draw do
  health_check_routes

  constraints host: Rails.configuration.x.domains.admin do
    mount Trestle::Engine => Trestle.config.path
  end

  if Rails.env.integration_test? || Rails.env.development?
    scope "test_support" do
      post "clean", to: "test_support#clean"
      post "force_login", to: "test_support#force_login"
      post "empty_account", to: "test_support#empty_account"
    end
  end

  constraints host: Rails.configuration.x.domains.app do
    # Auth area configuration where users login and register to the system.
    # Some API is managed by devise and some is is managed by graphql right now.
    devise_for :users, path: "/auth/api", controllers: {
                         sessions: "auth/sessions",
                         registrations: "auth/registrations",
                         confirmations: "auth/confirmations",
                         passwords: "auth/passwords",
                         unlocks: "auth/unlocks",
                       }

    namespace "auth" do
      mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "graphql"
      post "/graphql", to: "graphql#execute"

      get "*path", to: "client_side_app#index"
      root to: "client_side_app#index"
    end

    scope module: :app do
      mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "graphql", as: "app_graphiql"
      post "/graphql", to: "graphql#execute"

      # Forward all the other requests to the edit area client side router
      get "*path", to: "client_side_app#index", as: "app_client_side_app"
      root to: "client_side_app#index", as: "app_root"
    end
  end
end
