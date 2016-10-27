#
#= SendMailsHelper
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Provides utility methods and constants about sending Email.
#
#== Note:
#
#* 
#
module SendMailsHelper

  #=== self.get_mail_to_send
  #
  #Gets Email instance to send.
  #
  #_user_:: Current User.
  #_mail_account_:: Current MailAccount.
  #_params_:: Parameters of request.
  #return:: Email instance to send.
  #
  def self.get_mail_to_send(user, mail_account, params)

    params ||= {}

    if params[:id].nil? or params[:id].empty?
      email = Email.new
      email.user_id = user.id
      email.created_at = Time.now
    else
      email = Email.find(params[:id])
    end

    to_addresses = []
    cc_addresses = []
    bcc_addresses = []
    unless params[:addresses].nil?
      params[:addresses].each do |addr|
        if addr.index(Email::ADDR_PREFIX_TO) == 0
          to_addresses << addr.match(Email::ADDR_PREFIX_TO).post_match
        elsif addr.index(Email::ADDR_PREFIX_CC) == 0
          cc_addresses << addr.match(Email::ADDR_PREFIX_CC).post_match
        elsif addr.index(Email::ADDR_PREFIX_BCC) == 0
          bcc_addresses << addr.match(Email::ADDR_PREFIX_BCC).post_match
        end
      end
    end

    email.to_addresses = to_addresses.join(Email::ADDRESS_SEPARATOR)
    email.cc_addresses = cc_addresses.join(Email::ADDRESS_SEPARATOR)
    email.bcc_addresses = bcc_addresses.join(Email::ADDRESS_SEPARATOR)

    unless mail_account.nil?
      email.mail_account_id = mail_account.id
      email.from_address = mail_account.get_from_exp
    end

    unless params[:email].nil?
      email.subject = params[:email][:subject]
      email.message = params[:email][:message]
    end

    if email.mail_folder_id.nil?
      drafts_folder = MailFolder.get_for(user, email.mail_account_id, MailFolder::XTYPE_DRAFTS)
      email.mail_folder_id = drafts_folder.id unless drafts_folder.nil?
    end

    email.xtype = Email::XTYPE_SEND
    email.status = Email::STATUS_DRAFT
    email.updated_at = Time.now

    return email
  end
end
