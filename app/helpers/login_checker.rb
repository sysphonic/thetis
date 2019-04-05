#
#= LoginChecker
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
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

    if @login_user.nil?
      unless params[:user].nil?
        user = User.authenticate(params[:user])
        unless user.nil?
          @login_user = LoginHelper.on_login(user, session)
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

    unless session[:timestamp].nil?

      dt = DateTime.parse(session[:timestamp])

      if Time.utc(dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec) < Time.now.utc - THETIS_SESSION_EXPIRE_AFTER_MIN * 60
        @login_user = nil
        reset_session
      end
    end

    if @login_user.nil?
      Log.add_check(request, '[check_login]'+params.inspect)

      flash[:notice] = t('msg.need_to')+'<span class=\'msg_bold\'>'+t('login.name')+'</span>'+t('msg.need_to_suffix')
      if request.xhr?
        @redirect_url = url_for(:controller => 'login', :action => 'index')
        render(:partial => 'common/redirect_top_to')
      else
        redirect_to(:controller => 'login', :action => 'index', :fwd_controller => params[:controller], :fwd_action => params[:action], :fwd_params => ApplicationHelper.get_fwd_params(params))
      end
    else
      session[:timestamp] = Time.now.utc.strftime(Schedule::SYS_DATE_FORM + ' %H:%M:%S')
    end
  end

  #=== check_auth
  #
  #Filter method to check if current User has authority for specified operation.
  #
  #_required_auth_:: Required authority.
  #
  def check_auth(required_auth)

    return if (@login_user.nil? and self.performed?)

    if (@login_user.nil? or !@login_user.admin?(required_auth))
      Log.add_check(request, '[check_auth]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_admin')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
