#
#= LoginController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about LOGIN.
#
#== Note:
#
#* 
#
class LoginController < ApplicationController
  layout 'base'

  #=== index
  #
  #Does nothing about showing rhtml.
  #
  def index
    Log.add_info(request, params.inspect)
  end

  #=== login
  #
  #Does Login.
  #
  def login
    Log.add_info(request, '')   # Not to show passwords.

    user = User.authenticate(params[:user])

    if user.nil?

      flash[:notice] = '<span class=\'font_msg_bold\'>'+t('user.u_name')+'</span>'+t('msg.or')+'<span class=\'font_msg_bold\'>'+t('password.name')+'</span>'+t('msg.is_invalid')

      if params[:fwd_controller].nil? or params[:fwd_controller].empty?

        redirect_to(:controller => 'login', :action => 'index')
      else

        url_h = {:controller => 'login', :action => 'index', :fwd_controller => params[:fwd_controller], :fwd_action => params[:fwd_action]}

        unless params[:fwd_params].nil?
          params[:fwd_params].each do |key, val|
            url_h["fwd_params[#{key}]"] = val
          end
        end

        redirect_to(url_h)
      end

    else

      @login_user = LoginHelper.on_login(user, session)

      if params[:fwd_controller].nil? or params[:fwd_controller].empty?
        prms = ApplicationHelper.get_fwd_params(params)
        prms.delete('user')
        prms[:controller] = 'desktop'
        prms[:action] = 'show'
        redirect_to(prms)
      else
        url_h = {:controller => params[:fwd_controller], :action => params[:fwd_action]}
        url_h = url_h.update(params[:fwd_params]) unless params[:fwd_params].nil?
        redirect_to(url_h)
      end
    end
  end

  #=== logout
  #
  #Does Logout.
  #
  def logout
    Log.add_info(request, params.inspect)

    session[:login_user_id] = nil
    session[:settings] = nil
    session[:folder_id] = nil
    reset_session

    prms = ApplicationHelper.get_fwd_params(params)
    prms[:controller] = 'login'
    prms[:action] = 'index'
    redirect_to(prms)
  end

  #=== send_password
  #
  #Sends User account information by E-mail.
  #
  def send_password
    Log.add_info(request, params.inspect)

    begin
      users = User.find(:all, :conditions => "email='"+params[:thetisBoxEdit]+"'")
    rescue => evar
    end

    if users.nil? or users.empty?
      Log.add_error(request, evar)
      flash[:notice] = 'ERROR:' + t('email.address_not_found')
    else
      user_passwords_h = {}
      users.each do |user|
        newpass = UsersHelper.generate_password
        user.update_attribute(:pass_md5, UsersHelper.generate_digest_pass(user.name, newpass))

        user_passwords_h[user] = newpass
      end

      NoticeMailer.password(user_passwords_h, ApplicationHelper.root_url(request)).deliver;
      flash[:notice] = t('email.sent')
    end

    render(:controller => 'login', :action => 'index')
  end
end
