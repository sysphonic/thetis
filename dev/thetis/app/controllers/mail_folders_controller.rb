#
#= MailFoldersController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#== Note:
#
#* 
#
class MailFoldersController < ApplicationController
  layout 'base'

  include LoginChecker

  before_filter :check_login
  before_filter :check_owner, :only => [:rename, :destroy, :move, :get_mails, :empty]
  before_filter :check_mail_owner, :only => [:get_mail_content, :get_mail_attachments, :ajax_delete_mail, :get_mail_raw, :move_mail]

  #=== show_tree
  #
  #Shows MailFolder tree.
  #
  def show_tree
    Log.add_info(request, params.inspect)
    login_user = session[:login_user]

    if MailFolder.count(:id, :conditions => ['user_id = ?', login_user.id]) <= 0
      login_user.create_default_mail_folders
    end

    Email.destroy_by_user(login_user.id, "status='#{Email::STATUS_TEMPORARY}'")

    @folder_tree = MailFolder.get_tree_for(login_user)
  end

  #=== ajax_get_tree
  #
  #<Ajax>
  #Gets MailFolder tree by Ajax.
  #
  def ajax_get_tree
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    @folder_tree = MailFolder.get_tree_for(login_user)

    render(:partial => 'ajax_get_tree', :layout => false)
  end

  #=== create
  #
  #<Ajax>
  #Creates MailFolder.
  #Receives MailFolder name from ThetisBox.
  #
  def create
    Log.add_info(request, params.inspect)

    parent_id = params[:selectedFolderId]

    if params[:thetisBoxEdit].nil? or params[:thetisBoxEdit].empty?
      @mail_folder = nil
    else
      @mail_folder = MailFolder.new
      @mail_folder.name = params[:thetisBoxEdit]
      @mail_folder.parent_id = parent_id
      @mail_folder.user_id = session[:login_user].id
      @mail_folder.xtype = nil
      @mail_folder.save!
    end
    render(:partial => 'ajax_folder_entry', :layout => false)
  end

  #=== rename
  #
  #<Ajax>
  #Renames MailFolder.
  #Receives MailFolder name from ThetisBox.
  #
  def rename
    Log.add_info(request, params.inspect)

    @mail_folder = MailFolder.find(params[:id])

    unless params[:thetisBoxEdit].nil? or params[:thetisBoxEdit].empty?
      @mail_folder.name = params[:thetisBoxEdit]
      @mail_folder.save
    end
    render(:partial => 'ajax_folder_name', :layout => false)
  end

  #=== destroy
  #
  #<Ajax>
  #Deletes MailFolder.
  #
  def destroy
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    mail_folder = MailFolder.find(params[:id])
    trash_folder = MailFolder.get_for(login_user, MailFolder::XTYPE_TRASH)

    if mail_folder.get_parents(false).include?(trash_folder.id.to_s)
      mail_folder.force_destroy
      render(:text => '')
    else
      mail_folder.update_attribute(:parent_id, trash_folder.id)
      flash[:notice] = t('msg.moved_to_trash')
      @redirect_url = ApplicationHelper.url_for(:controller => params[:controller], :action => 'show_tree')
      render(:partial => 'common/redirect_to', :layout => false)
    end
  end

  #=== move
  #
  #Moves MailFolder.
  #Receives target MailFolder-ID from access-path and destination MailFolder-ID from ThetisBox.
  #params[:thetisBoxSelKeeper] keeps selected ID of <a>-tag like "thetisBoxSelKeeper-1:<selected-id>". 
  #
  def move
    Log.add_info(request, params.inspect)

    @mail_folder = MailFolder.find(params[:id])

    if params[:thetisBoxSelKeeper].nil? or params[:thetisBoxSelKeeper].empty?
      redirect_to(:action => 'show_tree')
      return
    end

    parent_id = params[:thetisBoxSelKeeper].split(':').last

    check = true

    # Check if specified parent is not one of subfolders.
    childs = MailFolder.get_childs(@mail_folder.id, true, false)
    if childs.include?(parent_id) or @mail_folder.id.to_s == parent_id
      flash[:notice] = 'ERROR:' + t('folder.cannot_be_parent')
      redirect_to(:action => 'show_tree')
      return
    end

    @mail_folder.parent_id = parent_id
    @mail_folder.save
    redirect_to(:action => 'show_tree')
  end

  #=== get_mails
  #
  #<Ajax>
  #Gets Mails in specified MailFolder.
  #
  def get_mails
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    if !params[:pop].nil? and params[:pop] == 'true'
      new_arrivals = 0
      mail_accounts = MailAccount.find_all("user_id=#{login_user.id}") || []
      mail_accounts.each do |mail_account|
        new_arrivals += Email.do_pop(mail_account)
      end
      if new_arrivals > 0
        flash[:notice] = t('mail.received', :count => new_arrivals)
      end
    end

    folder_id = params[:id]
    if folder_id == '0'   # '0' for ROOT
      @emails = nil
    else
      @emails = MailFolder.get_mails_to_show(folder_id, login_user)
    end

    session[:mailfolder_id] = folder_id

    render(:partial => 'ajax_folder_mails', :layout => false)
  end

  #=== get_mail_content
  #
  #<Ajax>
  #Gets Email content.
  #
  def get_mail_content
    Log.add_info(request, params.inspect)

    mail_id = params[:id]

    begin
      @email = Email.find(mail_id)
      render(:partial => 'ajax_mail_content', :layout => false)
    rescue StandardError => err
      Log.add_error(nil, err)
      render(:text => '')
    end
  end

  #=== get_mail_attachments
  #
  #<Ajax>
  #Gets Email attachments.
  #
  def get_mail_attachments
    email_id = params[:id]

    begin
      email = Email.find(email_id)
      unless email.nil?
        @mail_attachs = email.mail_attachments
        unless @mail_attachs.nil? or @mail_attachs.empty?
          render(:partial => 'ajax_get_attachment', :layout => false)
          return
        end
      end
    rescue StandardError => err
      Log.add_error(nil, err)
    end

    render(:text => '')
  end

  #=== get_mail_attachment
  #
  #Gets attachment-file of the Email.
  #
  def get_mail_attachment
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    attached_id = params[:id].to_i
    mail_attach = MailAttachment.find(attached_id)

    if mail_attach.nil?
      redirect_to(THETIS_RELATIVE_URL_ROOT + '/404.html')
      return
    end

    email = Email.find(mail_attach.email_id)
    if email.nil? or email.user_id != login_user.id
      render(:text => '')
      return
    end

    mail_attach_name = mail_attach.name

    agent = request.env['HTTP_USER_AGENT']
    unless agent.nil?
      ie_ver = nil
      agent.scan(/\sMSIE\s?(\d+)[.](\d+)/){|m|
                  ie_ver = m[0].to_i + (0.1 * m[1].to_i)
                }
      mail_attach_name = CGI::escape(mail_attach_name) unless ie_ver.nil?
    end

    filepath = mail_attach.get_path
    send_file(filepath, :filename => mail_attach_name, :stream => true, :disposition => 'attachment')
  end

  #=== move_mail
  #
  #<Ajax>
  #Moves Email to the specified MailFolder.
  #Receives target Email-ID from access-path and destination MailFolder-ID from ThetisBox.
  #params[:thetisBoxSelKeeper] keeps selected ID of <a>-tag like "thetisBoxSelKeeper-1:<selected-id>". 
  #
  def move_mail
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    if params[:thetisBoxSelKeeper].nil? or params[:thetisBoxSelKeeper].empty?
      flash[:notice] = 'ERROR:' + t('msg.system_error')
      redirect_to(:action => 'show_tree')
      return
    end

    parent_id = params[:thetisBoxSelKeeper].split(':').last
    if parent_id == '0' or MailFolder.find(parent_id).user_id != login_user.id
      flash[:notice] = 'ERROR:' + t('msg.cannot_save_in_folder')
      redirect_to(:action => 'show_tree')
      return
    end

    email = Email.find(params[:id])
    email.update_attribute(:mail_folder_id, parent_id)

    session[:mailfolder_id] = parent_id

    flash[:notice] = t('msg.move_success')
    redirect_to(:action => 'show_tree')
  end

  #=== get_mail_raw
  #
  #Gets raw data of the Email.
  #
  def get_mail_raw
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    email = Email.find(params[:id])
    email_name = email.subject + Email::EXT_RAW

    agent = request.env['HTTP_USER_AGENT']
    unless agent.nil?
      ie_ver = nil
      agent.scan(/\sMSIE\s?(\d+)[.](\d+)/){|m|
                  ie_ver = m[0].to_i + (0.1 * m[1].to_i)
                }
      email_name = CGI::escape(email_name) unless ie_ver.nil?
    end

    filepath = File.join(email.get_dir, email.id.to_s + Email::EXT_RAW)
    send_file(filepath, :filename => email_name, :stream => true, :disposition => 'attachment')
  end

  #=== ajax_delete_mail
  #
  #<Ajax>
  #Deletes specified Email.
  #
  def ajax_delete_mail
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    trash_folder = MailFolder.get_for(login_user, MailFolder::XTYPE_TRASH)

    email = Email.find(params[:id])
    if email.mail_folder_id == trash_folder.id \
        or MailFolder.find(email.mail_folder_id).get_parents(false).include?(trash_folder.id.to_s)
      email.destroy
      flash[:notice] = t('msg.delete_success')
    else
      email.update_attribute(:mail_folder_id, trash_folder.id)
      flash[:notice] = t('msg.moved_to_trash')
    end

    folder_id = params[:folder_id]
    @emails = MailFolder.get_mails_to_show(folder_id, login_user)

    render(:partial => 'ajax_folder_mails', :layout => false)
  end

  #=== empty
  #
  #<Ajax>
  #Deletes all Emails in specified MailFolder.
  #
  def empty
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    trash_folder = MailFolder.get_for(login_user, MailFolder::XTYPE_TRASH)

    mail_folder = MailFolder.find(params[:id])
    emails = MailFolder.get_mails(mail_folder.id, login_user) || []

    if mail_folder.id == trash_folder.id \
        or mail_folder.get_parents(false).include?(trash_folder.id.to_s)
      emails.each do |email|
        email.destroy
      end
      flash[:notice] = t('msg.delete_success')
    else
      emails.each do |email|
        email.update_attribute(:mail_folder_id, trash_folder.id)
      end
      flash[:notice] = t('msg.moved_to_trash')
    end

    @emails = MailFolder.get_mails_to_show(mail_folder.id, login_user)

    render(:partial => 'ajax_folder_mails', :layout => false)
  end

 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of the specified MailFolder.
  #
  def check_owner
    # '0' for ROOT
    return if params[:id].nil? \
             or params[:id].empty? \
             or params[:id]=='0' \
             or session[:login_user].nil?

    begin
      owner_id = MailFolder.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    login_user = session[:login_user]
    if !login_user.admin?(User::AUTH_MAIL) and owner_id != login_user.id
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end

  #=== check_mail_owner
  #
  #Filter method to check if current User is owner of the specified Email.
  #
  def check_mail_owner
    return if params[:id].nil? or params[:id].empty? or session[:login_user].nil?

    begin
      owner_id = Email.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    login_user = session[:login_user]
    if !login_user.admin?(User::AUTH_MAIL) and owner_id != login_user.id
      Log.add_check(request, '[check_mail_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
