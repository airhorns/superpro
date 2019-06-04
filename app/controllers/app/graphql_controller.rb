class App::GraphQLController < AppAreaController
  skip_before_action :verify_authenticity_token, if: :trusted_dev_request?
  skip_before_action :authenticate_user!, if: :trusted_dev_request?
  prepend_before_action :set_fake_env, if: :trusted_dev_request?

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user,
      current_account: current_account,
    }
    result = FlurishAppSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue => e
    raise e unless Rails.env.development?
    handle_error_in_development e
  end

  # Dev only helper for Apollo and gql-gen to be able to get the schema
  def set_fake_env
    if !current_user
      @current_user = Account.first.permissioned_users.first
    end

    if params[:app_id].blank?
      @current_account = Account.first
    end
  end
end
