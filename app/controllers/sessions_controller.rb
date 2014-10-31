class SessionsController < Devise::SessionsController
  def new
    unless params['plain_login']
      redirect_to new_sso_user_session_path
    else
      super
    end
  end
end
