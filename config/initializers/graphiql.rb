# frozen_string_literal: true

module GraphiQL
  module Rails
    class EditorsController < ActionController::Base
      helper_method :graphql_endpoint_path

      def graphql_endpoint_path
        if !params[:graphql_path]
          raise(%(You must include `graphql_path: "/my/endpoint"` when mounting GraphiQL::Rails::Engine))
        end
        if params[:graphql_path].respond_to?(:call)
          params[:graphql_path].call(params)
        else
          params[:graphql_path]
        end
      end
    end
  end
end
