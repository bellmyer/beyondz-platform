# Prevent CSRF attacks by raising an exception.
class ApplicationController < ActionController::Base
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  layout :default_layout
  before_action :save_external_referrer
  before_action :permit_lms_iframe
  before_filter :redirect_if_old

  private

  # We moved from beyondz.org to join.bebraven.org but I couldn't
  # get .htaccess redirects working on heroku, so I'm doing it in code.
  # Don't do it on dev though since you may have setup some funky domain stuff
  # to develop (e.g. you're using ngrok to expose your server to the internets)
  def redirect_if_old
    if Rails.env.production? && request.host != Rails.application.secrets.root_domain
      redirect_to "#{request.protocol}#{Rails.application.secrets.root_domain}#{request.fullpath}", :status => :moved_permanently
    end
  end

  def permit_lms_iframe
    secure = Rails.application.secrets.canvas_use_ssl ? 's' : ''
    domain = Rails.application.secrets.canvas_server
    port   = Rails.application.secrets.canvas_port
    if (secure && port != 443) || (!secure && port != 80)
      port = ":#{port}"
    else
      port = ''
    end

    response.headers['X-Frame-Options'] = "ALLOW-FROM http#{secure}://#{domain}#{port}"
    response.headers['Content-Security-Policy'] = "frame-ancestors 'self' http#{secure}://#{domain}#{port}"
  end

  def save_external_referrer
    if session[:referrer].nil?
      session[:referrer] = request.referrer
    end
  end

  # see: http://stackoverflow.com/questions/4982073/different-layout-for-sign-in-action-in-devise
  def default_layout
    if devise_controller?
      'public'
    else
      'application'
    end
  end

  # use controller specific JS whene requested
  # use: before_action :use_controller_js
  def use_controller_js
    @controller_js = params[:controller].split('/')[-1]
  end

  def require_student
    unless user_signed_in?
      flash[:error] = 'Please log in to see your assignments.'
      redirect_to new_user_session_path
    end
  end

  def require_coach
    unless user_signed_in? && current_user.coach?
      flash[:error] = 'Please log in to see your coaching dashboard.'
      redirect_to new_user_session_path
    end
  end

  # direct users to the proper path upon registration
  # We are now sending them all to a generic page, but I'm
  # keeping this method because we might change our mind back
  # and then we'd do to undo just to redo...
  def redirect_to_welcome_path(user)
    # FIXME: Hack for now. When spam problem is fixed, we want to wait for email activiation/confirmation
    if user.salesforce_campaign_id
      please_wait_path(new_user_id: user.id)
    else
      welcome_path(new_user_id: user.id)
    end
  end
end
