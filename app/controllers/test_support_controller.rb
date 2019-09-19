# frozen_string_literal: true

class TestSupportController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def force_login
    user = User.find_by!(email: params[:email])
    sign_in(:user, user)
    render json: user.to_json
  end

  def clean
    Superpro::Application.load_tasks
    Rake::Task["db:truncate_all"].invoke
    Rake::Task["db:truncate_all"].reenable
    render json: { success: true }
  end

  def empty_account
    user = FactoryBot.create :cypress_user
    account = FactoryBot.create :account, creator: user
    render json: account.to_json
  end

  def last_delivered_email
    render json: ActionMailer::Base.deliveries.last.as_json
  end
end
