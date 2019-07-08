class Auth::SignUpsController < ApplicationController
  respond_to :json
  prepend_before_action :require_no_signed_in_user, only: [:sign_up]

  def sign_up
    user, account, errors = Identity::SignUp.new.create_user_and_account(params.require(:sign_up).permit(
      user: [:email, :full_name, :password, :password_confirmation, :mutation_client_id],
      account: [:name, :mutation_client_id],
    ))

    success = user.present?
    if success
      sign_in(:user, user)
    end

    render status: success ? :created : :unprocessable_entity,
           json: {
             success: success,
             errors: Types::MutationErrorType.format_errors_object(errors, camelize: false),
             redirect_url: success ? app_root_path(params: { account_id: account.id }) : nil,
           }
  end
end
