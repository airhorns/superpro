# frozen_string_literal: true

class AppAreaController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_account
  layout "app_area_client_side_app"

  attr_reader :current_account

  private

  def set_current_account
    account_id = nil
    if params[:account_id].present?
      account_id = params[:account_id]
    elsif session[:current_account_id].present?
      account_id = session[:current_account_id]
    end

    account = if account_id.present?
                current_user.permissioned_accounts.kept.find(account_id)
              else
                current_user.permissioned_accounts.kept.first!
              end

    @current_account = account
    session[:current_account_id] = @current_account.id
  end
end
