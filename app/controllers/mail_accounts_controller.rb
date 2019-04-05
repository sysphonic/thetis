#
#= MailAccountsController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class MailAccountsController < ApplicationController
  layout('base')

  before_action(:check_login)
  before_action(:check_owner, :only => [:edit, :update, :show_summary])

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

    raise(RequestPostOnlyException) unless request.post?

    if (params[:mail_account][:smtp_auth].nil? or params[:mail_account][:smtp_auth] != '1')
      params[:mail_account].delete(:smtp_username)
      params[:mail_account].delete(:smtp_password)
    end

    @mail_account = MailAccount.new(MailAccount.permit_base(params.require(:mail_account)))
    @mail_account.user_id = @login_user.id

    @mail_account.is_default = true

    begin
      @mail_account.save!
    rescue
      if request.xhr?
        render(:partial => 'mail_account_error', :layout => false)
      else
        redirect_to(:controller => 'mail_folders', :action => 'show_tree')
      end
      return
    end

    flash[:notice] = t('msg.register_success')

    if request.xhr?
      render(:partial => 'common/flash_notice', :layout => false)
    else
      redirect_to(:controller => 'mail_folders', :action => 'show_tree')
    end
  end

  #=== edit
  #
  #Shows form to edit MailAccount information.
  #
  def edit
    Log.add_info(request, params.inspect)

    mail_account_id = params[:id]

    begin
      @mail_account = MailAccount.find(mail_account_id)
    rescue => evar
      Log.add_error(request, evar)
      redirect_to(:controller => 'login', :action => 'logout')
      return
    end
    render(:layout => (!request.xhr?))
  end

  #=== update
  #
  #Updates MailAccount information.
  #
  def update
    Log.add_info(request, '')   # Not to show passwords.

    raise(RequestPostOnlyException) unless request.post?

    @mail_account = MailAccount.find(params[:id])

    if (params[:mail_account][:smtp_auth].nil? or params[:mail_account][:smtp_auth] != '1')
      params[:mail_account].delete(:smtp_username)
      params[:mail_account].delete(:smtp_password)
    end

    if @mail_account.update_attributes(MailAccount.permit_base(params.require(:mail_account)))

      flash[:notice] = t('msg.update_success')
      if request.xhr?
        render(:partial => 'common/flash_notice', :layout => false)
      else
        prms = ApplicationHelper.get_fwd_params(params)
        prms[:controller] = 'mail_folders'
        prms[:action] = 'show_tree'
        redirect_to(prms)
      end
    else
      Log.add_error(request, nil, @mail_account.errors.inspect)
      if request.xhr?
        render(:partial => 'mail_account_error', :layout => false)
      else
        prms = ApplicationHelper.get_fwd_params(params)
        prms[:controller] = 'mail_folders'
        prms[:action] = 'show_tree'
        redirect_to(prms)
      end
    end
  end

  #=== show_summary
  #
  #Shows summary of the MailAccount.
  #
  def show_summary
    Log.add_info(request, params.inspect)

    mail_account_id = params[:id]
    SqlHelper.validate_token([mail_account_id])

    begin
      @mail_account = MailAccount.find(mail_account_id)
    rescue => evar
      Log.add_error(request, evar)
      redirect_to(:controller => 'login', :action => 'logout')
      return
    end

    @folder_tree = MailFolder.get_tree_for(@login_user, [mail_account_id])
# logger.fatal('@@@ ' + sorted_mail_folders.flatten.collect{|rec| rec.name}.inspect)
    mail_folders = TreeElement.get_flattened_nodes(@folder_tree)
    mail_folder_ids = mail_folders.collect{|rec| rec.id.to_s}

    @unread_emails_h = {}
    unless mail_folder_ids.nil? or mail_folder_ids.empty?
      unread_emails = Email.where("user_id=#{@login_user.id} and status='#{Email::STATUS_UNREAD}' and mail_folder_id in (#{mail_folder_ids.join(',')})").to_a
      unread_emails.each do |email|
        mail_folder = mail_folders.find{|rec| rec.id == email.mail_folder_id}
        unless mail_folder.nil?
          @unread_emails_h[mail_folder] ||= 0
          @unread_emails_h[mail_folder] += 1
        end
      end
    end
    @unread_emails_h = @unread_emails_h.sort_by{|mail_folder, count| mail_folders.index(mail_folder) }

    @draft_emails_h = {}
    unless mail_folder_ids.nil? or mail_folder_ids.empty?
      draft_emails = Email.where("user_id=#{@login_user.id} and status='#{Email::STATUS_DRAFT}' and mail_folder_id in (#{mail_folder_ids.join(',')})").to_a
      draft_emails.each do |email|
        mail_folder = mail_folders.find{|rec| rec.id == email.mail_folder_id}
        unless mail_folder.nil?
          @draft_emails_h[mail_folder] ||= 0
          @draft_emails_h[mail_folder] += 1
        end
      end
    end
    @draft_emails_h = @draft_emails_h.sort_by{|mail_folder, count| mail_folders.index(mail_folder) }

    @folder_obj_cache ||= MailFolder.build_cache(mail_folders)

    render(:layout => (!request.xhr?))
  end


 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of specified Item.
  #
  def check_owner

    return if (params[:id].blank? or @login_user.nil?)

    mail_account = MailAccount.find(params[:id])

    if !@login_user.admin?(User::AUTH_MAIL) and mail_account.user_id != @login_user.id
      Log.add_check(request, '[check_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
