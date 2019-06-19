class ApplicationController < ActionController::Base
  before_action :set_raven_context
  after_action :track_server_side_page_view

  private

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(exception)
    logger.error exception.message
    logger.error exception.backtrace.join("\n")

    render json: { error: { message: exception.message, backtrace: exception.backtrace }, data: {} }, status: :internal_server_error
  end

  def trusted_dev_request?
    (Rails.env.development? || Rails.env.integration_test?) && request.headers["HTTP_X_TRUSTED_DEV_CLIENT"].present?
  end

  def set_raven_context
    if current_user.present?
      Raven.user_context(user_id: current_user.id, email: current_user.email)
    end
    if respond_to?(:current_account) && current_account.present?
      Raven.tags_context(account_id: current_account.id, account_name: current_account.name)
    end
    Raven.tags_context(client_session_id: client_session_id)
  end

  def track_server_side_page_view
    if current_user.present?
      Analytics.track(
        user_id: current_user.id,
        event: "Request Made",
        properties: {
          account_id: respond_to?(:current_account) && current_account.id,
          request_id: request.request_id,
          client_session_id: client_session_id,
        },
      )
    end
  end

  def client_session_id
    request.headers["X-Client-Session-Id"]
  end

  def require_no_signed_in_user
    if current_user.present?
      render status: :forbidden, json: { error: "Already signed in as a user, this action is forbidden" }
    end
  end
end
