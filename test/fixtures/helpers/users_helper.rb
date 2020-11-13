module UsersHelper
  def user_info(user)
    render "users/info", user: user
  end
end
