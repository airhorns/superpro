# frozen_string_literal: true

# Pared down, JSON responder version of the invitations controller from devise_invitable
# Devise powers the Superpro auth API, but not the actual views, so this has to be pretty customized
class Auth::InvitationsController < DeviseController
  prepend_before_action :require_no_authentication, only: %i[edit update]
  before_action :configure_permitted_parameters, if: :devise_controller?

  clear_respond_to
  respond_to :json

  # GET /resource/invitation/accept?invitation_token=abcdef
  def edit
    unless params[:invitation_token] && (self.resource = resource_class.find_by_invitation_token(params[:invitation_token], true)) # rubocop:disable Rails/DynamicFindBy
      return render json: { success: false, user: nil }
    end

    set_minimum_password_length
    resource.invitation_token = params[:invitation_token]
    render json: { success: true, user: user_as_json }
  end

  # PUT /resource/invitation
  def update
    raw_invitation_token = update_resource_params[:invitation_token]
    self.resource = accept_resource
    invitation_accepted = resource.errors.empty?

    if invitation_accepted
      if resource.class.allow_insecure_sign_in_after_accept
        sign_in(resource_name, resource)
        location = after_accept_path_for(resource)
      else
        location = new_session_path(resource_name)
      end

      render json: { success: true, user: user_as_json, redirect_url: location }
    else
      resource.invitation_token = raw_invitation_token
      render status: :unprocessable_entity, json: { success: false, user: user_as_json, errors: Types::MutationErrorType.format_errors_object(resource.errors, camelize: false) }
    end
  end

  protected

  def accept_resource
    resource_class.accept_invitation!(update_resource_params)
  end

  def update_resource_params
    devise_parameter_sanitizer.sanitize(:accept_invitation)
  end

  def user_as_json
    { full_name: resource.full_name, email: resource.email }
  end

  def translation_scope
    "devise.invitations"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:accept_invitation, keys: %i[full_name mutation_client_id])
  end
end
