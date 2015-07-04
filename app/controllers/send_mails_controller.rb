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

    mail_account_id = params[:mail_account_id]

    if mail_account_id.nil? or mail_account_id.empty?
      account_xtype = params[:mail_account_xtype]
      @mail_account = MailAccount.get_default_for(@login_user.id, account_xtype)
    else
      @mail_account = MailAccount.find(mail_account_id)
      if @mail_account.user_id != @login_user.id
        flash[:notice] = 'ERROR:' + t('msg.need_to_be_owner')
        render(:partial => 'common/flash_notice', :layout => false)
        return
      end
    end

    if $thetis_config[:menu]['disp_user_list'] == '1'
      unless params[:to_user_ids].blank?
        @email = Email.new
        to_addrs = []
        @user_obj_cache ||= {}
        params[:to_user_ids].each do |user_id|
          user = User.find_with_cache(user_id, @user_obj_cache)
          user_emails = user.get_emails_by_type(nil)
          user_emails.each do |user_email|
            disp = EmailsHelper.format_address_exp(user.get_name, user_email, false)
            entry_val = "#{disp}"   # "#{disp}#{Email::ADDR_ORDER_SEPARATOR}#{user.get_xorder(@group_id)}"

            to_addrs << entry_val
          end
        end
        @email.to_addresses = to_addrs.join(Email::ADDRESS_SEPARATOR)
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

    email_id = params[:id]

    begin
      org_email = Email.find(email_id)
    rescue => evar
      Log.add_error(request, evar)
      redirect_to(:controller => 'login', :action => 'logout')
      return
    end

    @mail_account = MailAccount.find(org_email.mail_account_id)
    if @mail_account.user_id != @login_user.id
      flash[:notice] = 'ERROR:' + t('msg.need_to_be_owner')
      render(:partial => 'common/flash_notice', :layout => false)
      return
    end

    case params[:mode]
      when 'reply'
        @email = Email.new
        @email.user_id = @login_user.id
        @email.subject = 'Re: ' + (org_email.subject || '')
        @email.message = EmailsHelper.quote_message(org_email)
        @email.mail_account_id = @mail_account.id

        @email.to_addresses = org_email.reply_to || org_email.from_address

      when 'reply_to_all'
        @email = Email.new
        @email.user_id = @login_user.id
        @email.subject = 'Re: ' + (org_email.subject || '')
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
          org_to = org_email.get_to_addresses
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
        @email = SendMailsHelper.get_mail_to_send(@login_user, @mail_account, nil)
        @email.subject = 'FW: ' + (org_email.subject || '')
        @email.message = EmailsHelper.quote_message(org_email, :forward)

        @email.copy_attachments_from(org_email)

      when 'duplicate'
        @email = SendMailsHelper.get_mail_to_send(@login_user, @mail_account, nil)

        @email.user_id = @login_user.id
        @email.subject = org_email.subject
        @email.message = org_email.message
        @email.mail_account_id = @mail_account.id
        @email.to_addresses = org_email.to_addresses
        @email.cc_addresses = org_email.cc_addresses
        @email.bcc_addresses = org_email.bcc_addresses

        @email.copy_attachments_from(org_email)

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

    begin
      email = Email.find(params[:id])

      if email.status != Email::STATUS_DRAFT
        # Ignore clicked Send button twice or more at once.
        raise('ERROR:' + 'Specified E-mail is not a draft.')
      end

      mail_account = MailAccount.find(email.mail_account_id)
      if mail_account.user_id != @login_user.id
        raise('ERROR:' + t('msg.need_to_be_owner'))
      end

      sent_folder = MailFolder.get_for(@login_user, mail_account.id, MailFolder::XTYPE_SENT)
      email.do_smtp(mail_account)

      attrs = ActionController::Parameters.new({status: Email::STATUS_TRANSMITTED, mail_folder_id: sent_folder.id, sent_at: Time.now})
      email.update_attributes(attrs.permit(Email::PERMIT_BASE))

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

    unless params[:attach_file].nil?
      attach_attrs = { :file => params[:attach_file] }
      params.delete(:attach_file)
    end

    @mail_account = MailAccount.find(params[:mail_account_id])
    if @mail_account.user_id != @login_user.id
      flash[:notice] = 'ERROR:' + t('msg.need_to_be_owner')
      render(:partial => 'common/flash_notice', :layout => false)
      return
    end

    @email = SendMailsHelper.get_mail_to_send(@login_user, @mail_account, params)

    begin
      @email.save!

      unless attach_attrs.nil?
        attach_attrs[:email_id] = @email.id
        attach_attrs[:xorder] = 0
        @email.mail_attachments << MailAttachment.create(attach_attrs)
        @email.save!  # To recalcurate size
      end

      if THETIS_MAIL_LIMIT_NUM_PER_ACCOUNT > 0
        Email.trim(@login_user.id, @mail_account.id, THETIS_MAIL_LIMIT_NUM_PER_ACCOUNT)
      end
      if THETIS_MAIL_CAPACITY_MB_PER_ACCOUNT > 0
        Email.trim_by_capacity(@login_user.id, @mail_account.id, @mail_account.get_capacity_mb)
      end
      # flash[:notice] = t('msg.save_success')
    rescue => evar
      logger.fatal(evar.to_s)
      if evar.to_s.starts_with?('ERROR:')
        flash[:notice] = evar.to_s
      else
        flash[:notice] = 'ERROR:' + t('msg.system_error') + '<br/>' + evar.to_s
      end
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

    unless params[:attach_file].nil?
      attach_attrs = ActionController::Parameters.new({file: params[:attach_file]})
      params.delete(:attach_file)
    end

    if params[:id].blank?
      mail_account = MailAccount.find(params[:mail_account_id])

      @email = SendMailsHelper.get_mail_to_send(@login_user, mail_account, nil)
      @email.status = Email::STATUS_TEMPORARY
      @email.save!
    else
      @email = Email.find(params[:id])
    end

    unless attach_attrs.nil?

      unless @email.can_attach?(attach_attrs[:file].size)
        flash[:notice] = 'ERROR:' + t('mail.sum_of_attach_size_over')
        render(:partial => 'ajax_mail_attachments', :layout => false)
        return
      end

      attach_attrs[:email_id] = @email.id
      attach_attrs[:xorder] = 0
      @mail_attachment = MailAttachment.create(attach_attrs.permit(MailAttachment::PERMIT_BASE))
      @email.mail_attachments << @mail_attachment

      update_attrs = ActionController::Parameters.new({updated_at: Time.now})
      if @email.status == Email::STATUS_TEMPORARY \
          and !@email.mail_account_id.nil?
        update_attrs[:status] = Email::STATUS_DRAFT
      end
      @email.update_attributes(update_attrs.permit(Email::PERMIT_BASE))
    end

    render(:partial => 'ajax_mail_attachments', :layout => false)

  rescue => evar
    begin
      unless @mail_attachment.nil? or @mail_attachment.id.nil?
        @email.mail_attachments.delete(@mail_attachment)
      end
    rescue
    end
    begin
      unless @mail_attachment.nil? or @mail_attachment.id.nil?
        @mail_attachment.destroy
      end
    rescue
    end
    if evar.to_s.starts_with?('ERROR:')
      err_msg = evar.to_s
    else
      err_msg = 'ERROR:' + t('msg.system_error') + '<br/>' + evar.to_s
    end
    respond_to do |format|
      format.text { render(:text => err_msg) }
      format.html {
        flash[:notice] = err_msg
        render(:partial => 'ajax_mail_attachments', :layout => false)
        return
      }
    end
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

        update_attrs = ActionController::Parameters.new({updated_at: Time.now})
        if @email.status == Email::STATUS_TEMPORARY
          update_attrs[:status] = Email::STATUS_DRAFT
        end
        @email.update_attributes(update_attrs.permit(Email::PERMIT_BASE))
      end
    rescue => evar
      Log.add_error(request, evar)
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

    return if params[:id].nil? or params[:id].empty? or @login_user.nil?

    email = Email.find(params[:id])

    if !@login_user.admin?(User::AUTH_MAIL) and email.user_id != @login_user.id
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
