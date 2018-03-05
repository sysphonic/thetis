#
#= EmailsHelper
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Provides utility methods and constants about Email.
#
#== Note:
#
#* 
#
module EmailsHelper

  #=== self.get_message_id_from_header
  #
  #Gets Message-ID from mail header.
  #
  #_header_:: Mail header.
  #return:: Message-ID.
  #
  def self.get_message_id_from_header(header)

    message_id_matches = header.scan(/Message-ID:\s*[<]?([^>\n]+)[>]?/)
    unless message_id_matches.nil? or message_id_matches.empty?
      return message_id_matches.first.first
    end
    return nil
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
  #_email_:: Source Email.
  #_mode_:: Quoting mode.
  #return:: Message in quoted format.
  #
  def self.quote_message(email, mode=:reply)

    case mode
      when :reply
        sender = EmailsHelper.get_sender_exp(email.from_address)
        msg = "\r\n\r\n\r\n\r\n(#{email.get_sent_at_exp}), #{sender} wrote:\r\n"
        msg << email.message.split("\n").map!{|line| '> ' + line.chomp}.join("\r\n")
        msg << "\r\n\r\n"
        return msg
      when :forward
        msg = "\r\n\r\n\r\n\r\n-------- Original Message --------\r\n"

        parse_keys = ['Subject', 'Date', 'From', 'Reply-To', 'Organization', 'To', 'Cc', 'Bcc']
        header = EmailsHelper.raw_header(email.get_raw)
        parsed_header = ''
        unless header.nil?
          header.each_line {|line|
            line.chomp!
            if !parsed_header.empty? and line.match(/^\s/).nil?
              parsed_header << "\r\n"
            end
            parsed_header << line
          }
        end
        lines = parsed_header.split("\r\n")
        parse_keys.each do |key|
          key_line = lines.find {|line| !line.match(Regexp.new("^#{key}:")).nil? }
          unless key_line.nil?
            msg << EmailsHelper.decode_b(key_line) + "\r\n"
          end
        end
        msg << "\r\n"
        msg << email.message + "\r\n\r\n"
        return msg
      else
        return email.message
    end
  end

  #=== self.raw_header
  #
  #Gets raw header of the Email.
  #
  #_raw_source_:: Target raw source of the Email.
  #return:: Raw header of the Email.
  #
  def self.raw_header(raw_source)

    return nil if raw_source.nil?

    return raw_source.split("(\r\n\r\n|\n\n)", 2).first
  end

  #=== self.raw_header_infos
  #
  #Gets raw header informations of the Email.
  #
  #_raw_source_:: Target raw source of the Email.
  #return:: Array of raw header informations.
  #
  def self.raw_header_infos(raw_source)

    header = EmailsHelper.raw_header(raw_source)
    return nil if header.nil?

    line_sep = (EmailsHelper.raw_line_sep(raw_source) || "\r\n")

    infos = []
    lines = []
    modified = false
    header.gsub(/\r\n/, "\n").split(/\n/).each do |line|
      break if line.empty?

      unless line.match(/\A[^:\s]+[:]/).nil? or lines.empty?
        infos << lines.join(line_sep)
        lines = []
      end
      lines << line
    end
    infos << lines.join(line_sep) unless lines.empty?
    return infos
  end

  #=== self.raw_body
  #
  #Gets raw body of the Email.
  #
  #_raw_source_:: Target raw source of the Email.
  #return:: Raw body of the Email.
  #
  def self.raw_body(raw_source)

    return nil if raw_source.nil?

    return raw_source.split("(\r\n\r\n|\n\n)", 2).last
  end

  #=== self.raw_line_sep
  #
  #Gets raw line separator of the Email.
  #
  #_raw_source_:: Target raw source of the Email.
  #return:: Raw line separator of the Email.
  #
  def self.raw_line_sep(raw_source)

    return nil if raw_source.nil?

    m = raw_source.match(/(\r\n|\n)/)
    unless m.nil? or m[1].nil?
      return m[1]
    end
    return nil
  end

  #=== self.remove_raw_addr
  #
  #Removes raw E-mail address from E-mail address expression.
  #
  #_exp_:: E-mail address expression.
  #return:: E-mail address expression without raw E-mail address.
  #
  def self.remove_raw_addr(exp)

    return nil if exp.nil?

    return exp.gsub(/[ \t]*<[^>]+>[ \t]*/, '').gsub(/["]/, '')
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

  #=== self.extract_name
  #
  #Gets name in E-mail address expression.
  #
  #_exp_:: E-mail address expression.
  #return:: Name in E-mail address expression.
  #
  def self.extract_name(exp)

    return nil if exp.nil?

    name = exp.slice(/([^<>]+)<.+>/, 1)
    return name.strip unless name.nil?

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
  #_enc_:: Encoding to apply to sending Email.
  #_addr_exp_:: Target address expression.
  #return:: Encoded expression.
  #
  def self.encode_disp_name(addr_exp, enc=nil)

    return '' if addr_exp.nil?

    mail_addr = addr_exp.slice(/<([^>]+)>/, 1)
    return addr_exp if mail_addr.nil?

    disp_name = addr_exp.slice(/"(.+)"\s*</, 1) \
                || addr_exp.slice(/(.+)</, 1)
    disp_name.strip! unless disp_name.nil?
    return addr_exp if disp_name.nil? or disp_name.empty?

    enc_name = EmailsHelper.encode_b(disp_name, enc)

    return EmailsHelper.format_address_exp(enc_name, mail_addr)
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

    SqlHelper.validate_token([folder_ids, sort_col, sort_type, limit_num])

    where = ' where'
    where << " (Email.user_id=#{user.id})"

    where << " and ((status is null) or not(status='#{Email::STATUS_TEMPORARY}'))"

    unless keyword.blank?
      key_array = keyword.split(nil)
      key_array.each do |key|
        where << ' and ' + SqlHelper.get_sql_like([:subject, :from_address, :to_addresses, :cc_addresses, :bcc_addresses, :reply_to, :message], key)
      end
    end

    unless folder_ids.nil?
      folder_cons = []

      unless folder_ids.instance_of?(Array)
        folder_ids = [folder_ids]
      end

      folder_ids.each do |folder_id|
        folder_cons << "(Email.mail_folder_id=#{folder_id})"
      end

      where << ' and (' + folder_cons.join(' or ') + ')'
    end

    unless add_con.blank?
      where << ' and (' + add_con + ')'
    end

    sort_col = 'sent_at' if sort_col.blank?
    sort_type = 'DESC' if sort_type.blank?

    case sort_col
      when 'has_attach'
        sql = "select distinct Email.*, count(MailAttachment.id) as AttachmentsNum from (emails Email left join mail_attachments MailAttachment on (Email.id=MailAttachment.email_id))"
        order_by = ' group by Email.id order by AttachmentsNum ' + sort_type
      else
        sql = 'select distinct Email.* from emails Email'
        order_by = " order by #{sort_col} #{sort_type}"
        if sort_col == 'sent_at'
          order_by << ", updated_at #{sort_type}"
        end
    end

    limit = ''
    unless limit_num.nil? or limit_num <= 0
      limit = ' limit 0,' + limit_num.to_s
    end

    sql << where + order_by + limit

    return sql
  end

  #=== self.get_send_email_by_message_id
  #
  #Gets Email which has 'Send' xtype and the specified Message-ID.
  #
  #_message_id_:: Target Message-ID.
  #return:: Email which has 'Send' xtype and the specified Message-ID.
  #
  def self.get_send_email_by_message_id(message_id)

    con = []
    con << "(xtype='#{Email::XTYPE_SEND}')"
    con << "(message_id='#{message_id}')"

    return Email.where(con.join(' and ')).first
  end

  #=== self.encode_b
  #
  #Gets B-Encoded String.
  #
  #_str_:: Target String.
  #_enc_:: Encoding to apply to sending Email.
  #return:: Encoded String.
  #
  def self.encode_b(str, enc=nil)
    require 'nkf'

    return str if str.nil? or str.empty?

    # return Mail::Encodings.decode_encode(str, :encode)
    parts = str.scan(/.{16}|.+\Z/)
    enc = enc.upcase unless enc.nil?
    case enc
      when 'ISO-2022-JP'
        parts.collect!{|part| "=?ISO-2022-JP?B?#{NKF.nkf('-jWMB', part).gsub(/[\r\n]/, '')}?="}
      when 'UTF-8', nil
        parts.collect!{|part| "=?UTF-8?B?#{NKF.nkf('-wWMB', part).gsub(/[\r\n]/, '')}?="}
      else
        parts.collect!{|part| "=?#{enc}?B?#{[EmailsHelper.encode(part, enc)].pack('m0')}?="}
    end
    return parts.join("\r\n ")
  end

  #=== self.encode
  #
  #Gets encoded String.
  #
  #_str_:: Target String.
  #_enc_:: Encoding to apply to sending Email.
  #return:: Encoded String.
  #
  def self.encode(str, enc=nil)
    require 'nkf'

    return str if str.nil? or str.empty?

    enc = enc.upcase unless enc.nil?
    case enc
      when 'ISO-2022-JP'
        return NKF.nkf('-jW', str)
      when 'UTF-8', nil
        return str
      else
        return Iconv.conv(enc+'//IGNORE', 'utf-8', str)
    end
  end

  #=== self.encode_b_raw
  #
  #Gets B-Encoded String in raw style.
  #
  #_str_:: Target String.
  #_enc_:: Encoding to apply to sending Email.
  #return:: Encoded String in raw style.
  #
  def self.encode_b_raw(str, enc=nil)
    require 'nkf'

    return str if str.nil? or str.empty?

    enc = enc.upcase unless enc.nil?
    case enc
      when 'UTF-8', nil
        return [str].pack('m').gsub(/(\r\n|\n)/){"\r\n"}
      else
        return [EmailsHelper.encode(str, enc)].pack('m').gsub(/(\r\n|\n)/){"\r\n"}
    end
  end

  #=== self.decode_b
  #
  #Gets decoded String of the B-Encoded header info.
  #
  #_header_:: Target mail header.
  #_key_:: Target key of the mail header.
  #return:: Decoded String.
  #
  def self.decode_b(header, key=nil)
    require 'nkf'

    if key.nil?
      return NKF.nkf('-w', header)
    else
      parsed_header = ''
      header.each_line {|line|
        line.chomp!
        if !parsed_header.empty? and line.match(/^\s/).nil?
          parsed_header << "\r\n"
        end
        parsed_header << line
      }

      m = parsed_header.scan(Regexp.new("#{key}:(.*)$"))

      unless m.nil? or m.empty?
        raw_val = m.flatten.first.strip
        val = NKF.nkf('-w', raw_val)
        return val
      end
      return nil
    end
  end

  #=== self.get_message_part
  #
  #Gets message part of Mail.
  #
  #_mail_:: Target Mail (not Email).
  #return:: Message part of Mail.
  #
  def self.get_message_part(mail)

    plain_part = (mail.multipart?) ? ((mail.text_part) ? mail.text_part : nil) : nil
    html_part = (mail.html_part) ? mail.html_part : nil
    message_part = (plain_part || html_part)
    message_part ||= mail unless mail.multipart?

    return message_part
  end

  #=== self.get_message_charset
  #
  #Gets charset of message part.
  #
  #_message_part_:: Message part.
  #_mail_charset_:: Mail charset.
  #return:: Charset of message part.
  #
  def self.get_message_charset(message_part, mail_charset)

    charset = nil

    unless message_part.nil?

      unless message_part.header.nil?
        m = message_part.header.to_s.match(/charset=["']?([0-9a-zA-Z_-]+)["']?/)
        unless m.nil? or m[1].nil?
          charset = m[1]
        end
      end

      if charset.nil?
        unless message_part.body.nil? or message_part.body.match(/\e[$]B/).nil?
          charset = 'ISO-2022-JP'
        end
      end

      if charset.nil?
        unless message_part.header.charset.blank?
          charset = message_part.header.charset
        end
      end
    end

    charset ||= mail_charset

    charset = 'CP50220' if !charset.nil? and (charset.casecmp('ISO-2022-JP') == 0)

    return charset
  end

  #=== self.replace_jis_cp
  #
  #Replaces ISO-2022-JP with CP50220.
  #
  #_raw_source_:: Original raw source.
  #return:: Replaced text.
  #
  def self.replace_jis_cp(raw_source)

    lines = []
    is_header = true
    boundary = nil
    modified = false
    raw_source.gsub(/\r\n/, "\n").split(/\n/).each do |line|
      if is_header
        if line.empty?
          is_header = false
        else
          unless line.match(/=[?]ISO-2022-JP[?]/i).nil?
            line = line.gsub(/=[?]ISO-2022-JP[?]/i, '=?CP50220?')
            modified = true
          end
          m = line.match(/\AContent-Type:.*boundary=["']?([^"'\s]+)["']?/i)
          unless m.nil? or m[1].nil?
            boundary = m[1]
          end
        end
      else
        if (!boundary.nil? and (line == '--'+boundary))
          is_header = true
        end
      end
      lines << line
    end
    if modified
      return lines.join("\r\n")
    else
      return raw_source
    end
  end

  #=== self.remove_invalid_dates
  #
  #Removes header informations which contain invalid dates.
  #
  #_raw_source_:: Original raw source.
  #return:: Replaced text.
  #
  def self.remove_invalid_dates(raw_source)

    target_keys = ['Date', 'Received']

    header_infos = EmailsHelper.raw_header_infos(raw_source)
    line_sep = (EmailsHelper.raw_line_sep(raw_source) || "\r\n")

    modified = false
    valid_infos = []
    header_infos.each do |header_info|
      is_valid = true
      m = header_info.match(/\A([^:\s]+)[:]/)
      key = nil
      key = m[1] unless m.nil?
      if target_keys.include?(key)
        date_m = header_info.match(/([a-zA-Z\s\d+-]+\d\d[:]\d\d[:]\d\d[a-zA-Z\s\d+-]+)/)
        unless date_m.nil? or date_m[1].nil?
          begin
            DateTime.parse(date_m[1])
          rescue
            is_valid = false
            modified = true
          end
        end
      end
      valid_infos << header_info if is_valid
    end
    if modified
      body = EmailsHelper.raw_body(raw_source)
      return [valid_infos.join(line_sep), body].join(line_sep+line_sep)
    else
      return raw_source
    end
  end

  #=== self.remove_invalid_headers
  #
  #Removes invalid header informations.
  #
  #_raw_source_:: Original raw source.
  #return:: Replaced text.
  #
  def self.remove_invalid_headers(raw_source)

    header_infos = EmailsHelper.raw_header_infos(raw_source)
    line_sep = (EmailsHelper.raw_line_sep(raw_source) || "\r\n")

    modified = false
    valid_infos = []
    header_infos.each do |header_info|
      begin
        # Test
        mail = Mail.new(header_info+line_sep+line_sep+'dummy body'+line_sep)
        [:header, :date, :from, :to, :cc, :bcc, :reply_to].each do |key|
          mail.send(key.to_s)
        end
        message_part = EmailsHelper.get_message_part(mail)
        message_part.header.to_s unless message_part.nil?

        valid_infos << header_info
      rescue
        modified = true
      end
    end
    if modified
      body = EmailsHelper.raw_body(raw_source)
      return [valid_infos.join(line_sep), body].join(line_sep+line_sep)
    else
      return raw_source
    end
  end

  #=== self.trim_content_type
  #
  #Trims content-type.
  #
  #_content_type_:: Target content-type.
  #return:: Trimmed content-type.
  #
  def self.trim_content_type(content_type)

    return nil if content_type.nil?

    content_type = content_type.strip.gsub(/\s*name=(["][^"]*["]|['][^']*[']|[^ ]*)[;]?/, '')
    unless content_type.match(/\A[^;]+[;]\z/).nil?
      content_type = content_type.gsub(/[;]\z/, '')
    end
    return content_type
  end
end
