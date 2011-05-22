#
#= MailAccountsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro, Outsourced cooperators
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#== Note:
#
#* 
#
class MailAccountsController < ApplicationController
  layout 'base'

  include LoginChecker

  before_filter :check_login
  before_filter :check_owner, :only => [:edit, :update]


  #=== new
  #
  #Does nothing about showing empty form to create MailAccount.
  #
  def new
    Log.add_info(request, params.inspect)
    render(:layout => (!request.xhr?))
  end

  #=== create
  #
  #Creates MailAccount.
  #
  def create
    Log.add_info(request, '')   # Not to show passwords.

    login_user = session[:login_user]

    if params[:mail_account][:smtp_auth].nil? or params[:mail_account][:smtp_auth] != '1'
      params[:mail_account].delete :smtp_username
      params[:mail_account].delete :smtp_password
    end

    @mail_account = MailAccount.new(params[:mail_account])
    @mail_account.user_id = login_user.id

    @mail_account.is_default = true

    begin
      @mail_account.save!
    rescue
      if request.xhr?
        render(:partial => 'mail_account_error', :layout => false)
      else
        render(:controller => 'mail_accounts', :action => 'new')
      end
      return
    end

    flash[:notice] = t('msg.register_success')
    if request.xhr?
      render(:partial => 'common/flash_notice', :layout => false)
    else
      redirect_to(:controller => 'mail_accounts', :action => 'list')
    end
  end

  #=== edit
  #
  #Shows form to edit MailAccount information.
  #
  def edit
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    mail_account_id = params[:id]

    begin
      @mail_account = MailAccount.find(mail_account_id)
    rescue StandardError => err
      Log.add_error(request, err)
      redirect_to(:controller => 'login', :action => 'logout')
      return
    end
    render(:layout => (!request.xhr?))
  end

  #=== edit_default
  #
  #Shows form to edit default MailAccount information.
  #If not found, shows New Account form.
  #
  def edit_default
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]
    mail_account = MailAccount.get_default_for(login_user.id)

    if mail_account.nil?
      redirect_to(:action => 'new')
    else
      redirect_to(:action => 'edit', :id => mail_account.id)
    end
  end

  #=== update
  #
  #Updates MailAccount information.
  #
  def update
    Log.add_info(request, '')   # Not to show passwords.

    @mail_account = MailAccount.find(params[:id])

    if params[:mail_account][:smtp_auth].nil? or params[:mail_account][:smtp_auth] != '1'
      params[:mail_account].delete :smtp_username
      params[:mail_account].delete :smtp_password
    end

    if @mail_account.update_attributes(params[:mail_account])

      flash[:notice] = t('msg.update_success')
      if request.xhr?
        render(:partial => 'common/flash_notice', :layout => false)
      else
        redirect_to(:controller => 'mail_accounts', :action => 'list')
      end
    else
      if request.xhr?
        render(:partial => 'mail_account_error', :layout => false)
      else
        render(:controller => 'mail_accounts', :action => 'edit')
      end
    end
  end

 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of specified Item.
  #
  def check_owner

    login_user = session[:login_user]

    return if params[:id].nil? or params[:id].empty? or login_user.nil?

    mail_account = MailAccount.find(params[:id])

    if !login_user.admin?(User::AUTH_MAIL) and mail_account.user_id != login_user.id
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
