#
#= EmailsHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about Email.
#
#== Note:
#
#* 
#
module EmailsHelper

  #=== self.split_preserving_quot
  #
  #Splits string preserving quotations.
  #
  #_quot_:: Quotation character.
  #_delim_:: Delimiter.
  #return:: Array of the parts.
  #
  def self.split_preserving_quot(str, quot, delim)

    return nil if str.nil?
    return str if quot.nil? or delim.nil?

    regexp = Regexp.new("([#{quot}](\\#{quot}|[^#{quot}])*[#{quot}])*#{delim}")
    ary = str.split(regexp)
    ary.collect!{|entry|
      entry.strip
    }
    return ary
  end

  #=== self.format_address_exp
  #
  #Gets E-mail address expression.
  #
  #_disp_name_:: Display name.
  #_mail_addr_:: Mail address.
  #_quoted_:: Flag to quote name.
  #return:: Mail address expression.
  #
  def self.format_address_exp(disp_name, mail_addr, quoted=true)

    if disp_name.nil? or disp_name.empty?
      return "<#{mail_addr}>"
    elsif quoted
      return "\"#{disp_name}\" <#{mail_addr}>"
    else
      return "#{disp_name} <#{mail_addr}>"
    end
  end

  #=== self.quote_message
  #
  #Gets given message in quoted format.
  #
  #_msg_:: Source message.
  #return:: Message in quoted format.
  #
  def self.quote_message(email)
    sender = EmailsHelper.get_sender_exp(email.from_address)
    return "\n\n(#{email.get_sent_at_exp}), #{sender} wrote:\n" \
           + email.message.split("\n").map!{|line| '> ' + line}.join("\n")
  end

  #=== self.extract_addr
  #
  #Gets E-mail address from E-mail address expression.
  #
  #_exp_:: E-mail address expression.
  #return:: E-mail address.
  #
  def self.extract_addr(exp)

    return nil if exp.nil?

    addr = exp.slice(/<(.+)>/, 1)
    return addr.strip unless addr.nil?

    return exp
  end

  #=== self.get_sender_exp
  #
  #Gets Sender expression of From address.
  #
  #_from_:: From address.
  #return:: Sender expression.
  #
  def self.get_sender_exp(from)

    return nil if from.nil?

    sender = from.slice(/"(.+)"\s*</, 1)
    return sender.strip unless sender.nil?

    sender = from.slice(/(.+)</, 1)
    return sender.strip unless sender.nil?

    sender = from.slice(/<(.+)>/, 1)
    return sender.strip unless sender.nil?

    return from
  end

  #=== self.encode_disp_name
  #
  #Gets encoded expression of E-mail address.
  #
  #_addr_exp_:: Target address expression.
  #return:: Encoded expression.
  #
  def self.encode_disp_name(addr_exp)

    mail_addr = addr_exp.slice(/<([^>]+)>/, 1)
    return addr_exp if mail_addr.nil?

    disp_name = addr_exp.slice(/"(.+)"\s*</, 1) \
                || addr_exp.slice(/(.+)</, 1)
    disp_name.strip! unless disp_name.nil?
    return addr_exp if disp_name.nil? or disp_name.empty?

    disp_name = Mail::Encodings.decode_encode(disp_name, :encode)

    return EmailsHelper.format_address_exp(disp_name, mail_addr)
  end

  #=== self.get_list_sql
  #
  #Gets SQL for list of Emails.
  #
  #_user_:: User Instance for whom list will be made. If not required, specify nil.
  #_keyword_:: Search keyword. If not required, specify nil.
  #_folder_ids_:: Array of MailFolder-IDs. If not required, specify nil.
  #_sort_col_:: Column to be used to sort list. If specified nil, uses default('updated_at').
  #_sort_type_:: Sort type. Specify 'ASC' , 'DESC'. If specified nil, uses default('DESC').
  #_limit_num_:: Limit count to get. If without limit, specify 0.
  #_admin_:: Optional flag to apply Administrative Authority. Default = false.
  #_add_con_:: Additional condition. This parameter is added to 'where' clause with 'and'. Default = nil.
  #return:: SQL for list of Emails.
  #
  def self.get_list_sql(user, keyword, folder_ids, sort_col, sort_type, limit_num, add_con=nil)

    where = ' where'
    where << " (Email.user_id=#{user.id})"

    where << " and ((status is null) or not(status='#{Email::STATUS_TEMPORARY}'))"

    unless keyword.nil? or keyword.empty?
      key_array = keyword.split(nil)
      key_array.each do |key| 
        key = "\'%" + key + "%\'"
        where << ' and (subject like '+key+' or from_address like '+key+' or to_addresses like '+key+' or cc_addresses like '+key+' or bcc_addresses like '+key+' or reply_to like '+key+' or message like '+key+')'
      end
    end

    unless folder_ids.nil?
      folder_cons = []

      if !folder_ids.instance_of?(Array)
        folder_ids = [folder_ids]
      end

      folder_ids.each do |folder_id|
        folder_cons << '(Email.mail_folder_id = '+folder_id.to_s+')'
      end

      where << ' and (' + folder_cons.join(' or ') + ')'
    end

    unless add_con.nil? or add_con.empty?
      where << ' and (' + add_con + ')'
    end

    sort_col = 'sent_at' if sort_col.nil? or sort_col.empty?
    sort_type = 'DESC' if sort_type.nil? or sort_type.empty?

    if sort_col == 'has_attach'
      sql = "select distinct Email.*, count(MailAttachment.id) as AttachmentsNum from (emails Email left join mail_attachments MailAttachment on (Email.id=MailAttachment.email_id)), mail_folders MailFolder"
      order_by = ' group by Email.id order by AttachmentsNum ' + sort_type
    else
      sql = 'select distinct Email.* from emails Email, mail_folders MailFolder'
      order_by = ' order by ' + sort_col + ' ' + sort_type
    end

    limit = ''
    unless limit_num.nil? or limit_num <= 0
      limit = ' limit 0,' + limit_num.to_s
    end

    sql << where + order_by + limit

    return sql
  end
end
