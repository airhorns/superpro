class Auth::SessionsController < Devise::SessionsController
  clear_respond_to
  respond_to :json

  def create
    self.resource = warden.authenticate!({ scope: resource_name, recall: "#{controller_path}#failure" })
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    render json: { success: true, redirect_url: after_sign_in_path_for(resource) }
  end

  def failure
    warden.custom_failure!
    render json: { success: false, message: "Your username and/or password was incorrect. Please try again." }, status: :unauthorized
  end

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    render json: { success: true, redirect_url: after_sign_out_path_for(resource) }
  end

  def after_sign_out_path_for(_resource)
    "/"
  end
end
