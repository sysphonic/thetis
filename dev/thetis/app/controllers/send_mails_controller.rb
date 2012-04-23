#
#= SendMailsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Sending Emails.
#
#== Note:
#
#* 
#
class SendMailsController < ApplicationController
  layout 'base'

  before_filter :check_login
  before_filter :check_owner, :except => [:new]


  #=== new
  #
  #Does nothing about showing empty form to create Email to send.
  #
  def new
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    mail_account_id = params[:mail_account_id]

    if mail_account_id.nil? or mail_account_id.empty?
      account_xtype = params[:mail_account_xtype]
      @mail_account = MailAccount.get_default_for(login_user.id, account_xtype)
    else
      @mail_account = MailAccount.find(mail_account_id)
      if @mail_account.user_id != login_user.id
        raise t('msg.need_to_be_owner')
      end
    end

    render(:action => 'edit', :layout => (!request.xhr?))
  end

  #=== edit
  #
  #Shows form to edit Email to send.
  #
  def edit
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    email_id = params[:id]

    begin
      org_email = Email.find(email_id)
    rescue StandardError => err
      Log.add_error(request, err)
      redirect_to(:controller => 'login', :action => 'logout')
      return
    end

    @mail_account = MailAccount.find(org_email.mail_account_id)
    if @mail_account.user_id != login_user.id
      raise t('msg.need_to_be_owner')
    end

    case params[:mode]
      when 'reply'
        @email = Email.new
        @email.user_id = login_user.id
        @email.subject = 'Re: ' + org_email.subject
        @email.message = EmailsHelper.quote_message(org_email)
        @email.mail_account_id = @mail_account.id

        @email.to_addresses = org_email.reply_to || org_email.from_address

      when 'reply_to_all'
        @email = Email.new
        @email.user_id = login_user.id
        @email.subject = 'Re: ' + org_email.subject
        @email.message = EmailsHelper.quote_message(org_email)
        @email.mail_account_id = @mail_account.id

        if org_email.xtype == Email::XTYPE_SEND
          @email.to_addresses = org_email.to_addresses
          @email.cc_addresses = org_email.cc_addresses
        else
          @email.to_addresses = org_email.reply_to || org_email.from_address

          self_addrs = [
            EmailsHelper.extract_addr(@mail_account.from_address),
            EmailsHelper.extract_addr(@mail_account.reply_to)
          ]
          self_addrs.compact!
          org_to = org_email.to_addresses.split(Email::ADDRESS_SEPARATOR)
          org_to.reject! { |to_addr|
            self_addrs.include?(EmailsHelper.extract_addr(to_addr))
          }
          cc_addrs = []
          cc_addrs << org_to.join(Email::ADDRESS_SEPARATOR) unless org_to.empty?
          cc_addrs << org_email.cc_addresses
          @email.cc_addresses = cc_addrs.join(Email::ADDRESS_SEPARATOR)
        end
        @email.bcc_addresses = org_email.bcc_addresses

      when 'forward'
        @email = SendMailsHelper.get_mail_to_send(login_user, @mail_account, nil)
        @email.subject = 'FW: ' + org_email.subject
        @email.message = EmailsHelper.quote_message(org_email)

        unless org_email.mail_attachments.nil? or org_email.mail_attachments.empty?
          @email.status = Email::STATUS_TEMPORARY
          @email.save!

          org_email.mail_attachments.each do |org_attach|
            mail_attach = org_attach.clone
            @email.mail_attachments << mail_attach
            mail_attach.copy_file_from(org_attach)
          end
          @email.save!  # To recalcurate size
        end

      else
        @email = org_email
    end

    render(:layout => (!request.xhr?))
  end

  #=== edit_send_to
  #
  #Shows form to edit Send-To addresses of Email.
  #
  def edit_send_to
    Log.add_info(request, params.inspect)

    render(:layout => (!request.xhr?))
  end

  #=== do_send
  #
  #<Ajax>
  #Does send E-mail.
  #
  def do_send
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    begin
      email = Email.find(params[:id])

      if email.status != Email::STATUS_DRAFT
        # Ignore clicked Send button twice or more at once.
        raise('ERROR:' + 'Specified E-mail is not a draft.')
      end

      mail_account = MailAccount.find(email.mail_account_id)
      if mail_account.user_id != login_user.id
        raise('ERROR:' + t('msg.need_to_be_owner'))
      end

      sent_folder = MailFolder.get_for(login_user, mail_account.id, MailFolder::XTYPE_SENT)

      email.do_smtp(mail_account)
      email.update_attributes({:status => Email::STATUS_TRANSMITTED, :mail_folder_id => sent_folder.id, :sent_at => Time.now})
      flash[:notice] = t('msg.transmit_success')
    rescue => evar
      Log.add_error(request, evar)
      flash[:notice] = 'ERROR:' + t('msg.transmit_failed') + '<br/>' + evar.to_s
    end

    render(:partial => 'common/flash_notice', :layout => false)
  end

  #=== save
  #
  #<Ajax>
  #Saves draft Email.
  #
  def save
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    unless params[:attach_file].nil?
      attach_attrs = { :file => params[:attach_file] }
      params.delete(:attach_file)
    end

    @mail_account = MailAccount.find(params[:mail_account_id])
    if @mail_account.user_id != login_user.id
      raise t('msg.need_to_be_owner')
    end

    @email = SendMailsHelper.get_mail_to_send(login_user, @mail_account, params)

    begin
      @email.save!

      unless attach_attrs.nil? or attach_attrs[:file].size <= 0
        attach_attrs[:email_id] = @email.id
        attach_attrs[:xorder] = 0
        @email.mail_attachments << MailAttachment.create(attach_attrs)
        @email.save!  # To recalcurate size
      end

      if THETIS_MAIL_LIMIT_NUM_PER_USER > 0
        Email.trim(login_user.id, @mail_account.id, THETIS_MAIL_LIMIT_NUM_PER_USER)
      end
      # flash[:notice] = t('msg.save_success')
    rescue => evar
      logger.fatal(evar.to_s)
      flash[:notice] = 'ERROR:' + t('msg.system_error') + '<br/>' + evar.to_s
    end

    render(:partial => 'ajax_mail_content', :layout => false)
  end

  #=== add_attachment
  #
  #<Ajax>
  #Attaches a file to the Email.
  #
  def add_attachment
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    unless params[:attach_file].nil?
      attach_attrs = { :file => params[:attach_file] }
      params.delete(:attach_file)
    end

    if params[:id].nil? or params[:id].empty?
      mail_account = MailAccount.find(params[:mail_account_id])

      @email = SendMailsHelper.get_mail_to_send(login_user, mail_account, nil)
      @email.status = Email::STATUS_TEMPORARY
      @email.save!
    else
      @email = Email.find(params[:id])
    end

    unless attach_attrs.nil? or attach_attrs[:file].size <= 0

      unless @email.can_attach?(attach_attrs[:file].size)
        flash[:notice] = 'ERROR:' + t('mail.sum_of_attach_size_over')
        render(:partial => 'ajax_mail_attachments', :layout => false)
        return
      end

      attach_attrs[:email_id] = @email.id
      attach_attrs[:xorder] = 0
      @email.mail_attachments << MailAttachment.create(attach_attrs)

      update_attrs = {:updated_at => Time.now}
      if @email.status == Email::STATUS_TEMPORARY \
          and !@email.mail_account_id.nil?
        update_attrs[:status] = Email::STATUS_DRAFT
      end
      @email.update_attributes(update_attrs)
    end

    render(:partial => 'ajax_mail_attachments', :layout => false)
  end

  #=== delete_attachment
  #
  #<Ajax>
  #Deletes MailAttachment of the Email.
  #
  def delete_attachment
    Log.add_info(request, params.inspect)

    begin
      attachment = MailAttachment.find(params[:attachment_id])
      @email = Email.find(params[:id])

      if attachment.email_id == @email.id
        attachment.destroy

        update_attrs = {:updated_at => Time.now}
        if @email.status == Email::STATUS_TEMPORARY
          update_attrs[:status] = Email::STATUS_DRAFT
        end
        @email.update_attributes(update_attrs)
      end
    rescue StandardError => err
      Log.add_error(request, err)
    end

    render(:partial => 'ajax_mail_attachments', :layout => false)
  end

  #=== get_group_users
  #
  #<Ajax>
  #Gets Users in specified Group.
  #
  def get_group_users
    Log.add_info(request, params.inspect)

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].nil? and !params[:group_id].empty?
      @group_id = params[:group_id]
    end

    submit_url = url_for(:controller => 'send_mails', :action => 'get_group_users')
    render(:partial => 'common/select_users', :layout => false, :locals => {:target_attr => :email, :submit_url => submit_url})
  end

 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of specified Item.
  #
  def check_owner

    login_user = session[:login_user]

    return if params[:id].nil? or params[:id].empty? or login_user.nil?

    email = Email.find(params[:id])

    if !login_user.admin?(User::AUTH_MAIL) and email.user_id != login_user.id
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
