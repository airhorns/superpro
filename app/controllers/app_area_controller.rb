class AppAreaController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_account

  layout "app_area"

  def current_account
    @current_account
  end

  private

  def set_current_account
    account_id = nil
    if params[:account_id].present?
      account_id = params[:account_id]
    elsif session[:current_account_id].present?
      account_id = session[:current_account_id]
    end

    if account_id.present?
      account = current_user.permissioned_accounts.kept.find(account_id)
    else
      account = current_user.permissioned_accounts.kept.first!
    end

    @current_account = account
    session[:current_account_id] = @current_account.id
  end
end
