class UsersController < ApplicationController

  layout "site"

  def show
    render "show"
  end

  def explicit_partial_with_locals
    render partial: "users/with_locals", locals: { user: params[:user] }
  end
end
