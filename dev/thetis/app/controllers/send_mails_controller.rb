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

  include LoginChecker

  before_filter :check_login
  before_filter :check_owner, :except => [:new]


  #=== new
  #
  #Does nothing about showing empty form to create Email to send.
  #
  def new
    Log.add_info(request, params.inspect)
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

    case params[:mode]
      when 'reply'
        @email = Email.new
        @email.user_id = login_user.id
        @email.subject = 'Re: ' + org_email.subject
        @email.message = EmailsHelper.quote_message(org_email)

        @email.to_addresses = org_email.reply_to || org_email.from_address

      when 'reply_to_all'
        @email = Email.new
        @email.user_id = login_user.id
        @email.subject = 'Re: ' + org_email.subject
        @email.message = EmailsHelper.quote_message(org_email)

        @email.to_addresses = org_email.reply_to || org_email.from_address
        @email.cc_addresses = org_email.cc_addresses
        @email.bcc_addresses = org_email.bcc_addresses

      when 'forward'
        @email = SendMailsHelper.get_mail_to_send(login_user)
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
        end

      else
        @email = org_email
    end

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
        render(:text => 'ERROR:' + t('msg.transmit_failed') + "\n Specified E-mail is not a draft.")
        return
      end

      sent_folder = MailFolder.get_for(login_user, MailFolder::XTYPE_SENT)

      mail_account = MailAccount.find(email.mail_account_id)
      if mail_account.user_id != login_user.id
        raise t('msg.need_to_be_owner')
      end

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

    @email = SendMailsHelper.get_mail_to_send(login_user, params)

    begin
      @email.save!

      unless attach_attrs.nil? or attach_attrs[:file].size <= 0
        attach_attrs[:email_id] = @email.id
        attach_attrs[:xorder] = 0
        @email.mail_attachments << MailAttachment.create(attach_attrs)
      end

      if THETIS_MAIL_LIMIT_NUM_PER_USER > 0
        Email.trim(login_user.id, THETIS_MAIL_LIMIT_NUM_PER_USER)
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

    unless params[:attach_file].nil?
      attach_attrs = { :file => params[:attach_file] }
      params.delete(:attach_file)
    end

    @email = Email.find(params[:id])

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
      if @email.status == Email::STATUS_TEMPORARY
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
