class ApplicationController < ActionController::Base
  before_action :set_raven_context

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
    Raven.user_context(user_id: current_user.try(:id))
  end
end
