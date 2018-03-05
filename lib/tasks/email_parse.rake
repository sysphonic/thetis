# bundle exec rake thetis:email_parse[username] RAILS_ENV=production THETIS_DATABASE_PASSWORD=

namespace :thetis do
  task(:email_parse, [:username] => :environment) do |task, args|

    #
    # Configuration
    #
    email_path = File.join(Rails.root.to_s, 'test.eml')
    if args[:username].blank?
      user_id = nil
      mail_account = nil
    else
      user_id = User.get_from_name(args[:username]).id
      mail_account = MailAccount.get_default_for(user_id, MailAccount::XTYPE_INTRANET)
    end

    #
    # Now do it ..
    #
    raw_org = File.read(email_path)

header_infos = EmailsHelper.raw_header_infos(raw_org)
puts('>>> '+header_infos.inspect)

    raw_source = EmailsHelper.replace_jis_cp(raw_org)
    raw_source = EmailsHelper.remove_invalid_headers(raw_source)

header_infos = EmailsHelper.raw_header_infos(raw_source)
puts('<<< '+header_infos.inspect)

    mail = Mail.new(raw_source)

    #mail = Mail.read(email_path)

    puts('1) --------------------------------------------------')
    puts('mail.header.charset = ' + mail.header.charset.to_s)
    message_part = EmailsHelper.get_message_part(mail)
    puts('charset of message_part = ' + EmailsHelper.get_message_charset(message_part, mail.header.charset))
    puts('mail.multipart? = ' + (mail.multipart?).to_s)
    unless mail.text_part.nil?
      puts('mail.text_part.header = ' + mail.text_part.header.to_s)
      puts('mail.text_part = ' + mail.text_part.to_s)
    end
    puts('')

    email = Email.parse_mail(mail)
    header = EmailsHelper.raw_header(mail.raw_source)

    email.user_id = user_id
    email.mail_account_id = (mail_account.nil?)?(nil):(mail_account.id)
    inbox = nil
    unless email.user_id.nil? or email.mail_account_id.nil?
      inbox = MailFolder.get_for(email.user_id, email.mail_account_id, MailFolder::XTYPE_INBOX)
    end
    unless inbox.nil?
      email.mail_folder_id = inbox.id
    end
    email.uid = 1 #svr_mail.unique_id

    msg_id = EmailsHelper.get_message_id_from_header(header)
    unless msg_id.nil?
      email.message_id = msg_id
    end
    priority_matches = header.scan(/X-Priority:\s*(\d)\s*([(]|\r\n|\n)/)
    unless priority_matches.nil? or priority_matches.empty?
      email.priority = priority_matches.first.first
    end
    email.status = Email::STATUS_UNREAD
    email.xtype = Email::XTYPE_RECV
    email.created_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')

    unless email[:subject].nil?
      if email[:subject].respond_to?(:encoding)
        if email[:subject].encoding.inspect.include?("ASCII-8BIT")
          email[:subject] = '***'
        end
      end
    end
    unless email[:message].nil?
      if email[:message].respond_to?(:encoding)
        if email[:message].encoding.inspect.include?("ASCII-8BIT")
          email[:message] = email[:message].force_encoding("UTF-8")
        end
      end
      if email[:message].respond_to?('scrub!')
        email[:message].scrub!('?')
      end
    end

    if inbox.nil?
      if mail.has_attachments?
        mail.attachments.each_with_index do |attach, idx|

          mail_attachment = MailAttachment.new
          mail_attachment.email_id = 0
          begin
            mail_attachment.name = Mail::Encodings.decode_encode(attach.filename, :decode)
          rescue => evar
            mail_attachment.name = attach.filename
          end
          mail_attachment.content_type = EmailsHelper.trim_content_type(attach.content_type)
    puts('  --------------------------------------------------')
    puts('  mail_attachment.name = ' + mail_attachment.name.to_s)
    puts('  mail_attachment.content_type = ' + mail_attachment.content_type.to_s)
        end
      end
    else
      email.save!
      email.save_files

      puts("==> SAVED in #{mail_account.title} - #{inbox.name}")
    end

    puts('2) --------------------------------------------------')
    puts("email.sent_at = #{email.get_sent_at_exp(false)} (#{email.get_sent_at_exp(true)})")
    puts(email.inspect)
    puts('')

    puts('3) --------------------------------------------------')
    puts("mail.subject = #{mail.subject}")
    puts("mail[:from] = #{mail[:from]}")
    puts("mail[:to] = #{mail[:to]}")
    puts("mail[:cc] = #{mail[:cc]}")
    puts("mail[:bcc] = #{mail[:bcc]}")
  end
end
