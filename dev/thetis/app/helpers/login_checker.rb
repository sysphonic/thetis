#
#= LoginChecker
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants for classes which need to
#filter unlogged-in User.
#
#== Note:
#
#* 
#
module LoginChecker

  #=== allow_midair_login
  #
  #Allows LOGIN on the fly if parameters contain authentication
  #information.
  #Call this filter alone (in other words, out of :check_login filter)
  #if the target action does not require LOGIN for itself but allows
  #the operationg User to act as LOGIN User.
  #
  def allow_midair_login

    if session[:login_user].nil?
      unless params[:user].nil?
        user = User.authenticate(params[:user])
        unless user.nil?
          LoginHelper.on_login(user, session)
          return
        end
      end
    end
  end

  #=== check_login
  #
  #Filter method to check if current User has LOGIN session.
  #
  def check_login

    allow_midair_login

    if session[:login_user].nil?
      Log.add_check(request, '[check_login]'+request.to_s)

      flash[:notice] = t('msg.need_to')+'<span class=\'font_msg_bold\'>'+t('login.name')+'</span>'+t('msg.need_to_suffix')
      redirect_to(:controller => 'login', :action => 'index', :fwd_controller => params[:controller], :fwd_action => params[:action], :fwd_params => ApplicationHelper.get_fwd_params(params))
    end
  end

  #=== check_auth
  #
  #Filter method to check if current User has authority for specified operation.
  #
  #_required_auth_:: Required authority.
  #
  def check_auth(required_auth)

    return if session[:login_user].nil? and self.performed?

    if session[:login_user].nil? \
        or !session[:login_user].admin?(required_auth)
      Log.add_check(request, '[check_auth]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_admin')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
