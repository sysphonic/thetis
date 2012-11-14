#
#= Email
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
class Email < ActiveRecord::Base
  attr_accessible(:user_id, :mail_account_id, :mail_folder_id, :from_address, :subject, :to_addresses, :cc_addresses, :bcc_addresses, :reply_to, :message, :priority, :sent_at, :status, :xtype, :size)

  has_many(:mail_attachments, :dependent => :destroy, :order=>'mail_attachments.xorder')

  require 'net/pop'
  require 'base64'
  require 'digest/sha1'

  public::XTYPE_UNKNOWN = nil
  public::XTYPE_RECV = 'recv'
  public::XTYPE_SEND = 'send'

  public::STATUS_NONE = nil
  public::STATUS_DRAFT = 'draft'
  public::STATUS_TRANSMITTED = 'transmitted'
  public::STATUS_UNREAD = 'unread'
  public::STATUS_TEMPORARY = 'temporary'

  public::ADDRESS_SEPARATOR = "\n"

  public::ADDR_ORDER_SEPARATOR = '#'

  public::ADDR_PREFIX_SEPARATOR = ':'
  public::ADDR_PREFIX_TO = 'To'+ADDR_PREFIX_SEPARATOR
  public::ADDR_PREFIX_CC = 'Cc'+ADDR_PREFIX_SEPARATOR
  public::ADDR_PREFIX_BCC = 'Bcc'+ADDR_PREFIX_SEPARATOR

  public::EXT_RAW = '.eml'


  before_save do |email|
    email.recalc_size
  end

  #=== unread?
  #
  #Gets whether this E-mail is unread or not.
  #
  #return:: true if this E-mail is unread, false otherwise.
  #
  def unread?
    return (self.status == Email::STATUS_UNREAD)
  end

  #=== recalc_size
  #
  #Recalcurates E-mail size.
  #
  def recalc_size
    if @mail.nil? or @mail.raw_source.nil?
      new_size = self.get_raw.length
      if new_size == 0
        new_size += self.subject.length unless self.subject.nil?
        new_size += self.message.length unless self.message.nil?
        new_size += self.get_attach_size
      end
      self.size = new_size
    else
      self.size = @mail.raw_source.length
    end
  end

  #=== zip_attachments
  #
  #Creates a ZIP file of the attachments.
  #
  #_enc_:: Character encoding to apply to file names.
  #return:: Created ZIP file.
  #
  def zip_attachments(enc)

    return nil if self.mail_attachments.nil? or self.mail_attachments.empty?

    require 'zipruby'

    temp = Tempfile.new('thetis_mail_attachments')
    temp.binmode
    temp.close(false)

    Zip::Archive.open(temp.path) do |arc|
      self.mail_attachments.each do |mail_attach|
        fname = mail_attach.name
        begin
          fname.encode!(enc, Encoding::UTF_8, {:invalid => :replace, :undef => :replace, :replace => ' '})
        rescue => evar
          Log.add_error(nil, evar)
        end
        arc.add_file(fname, mail_attach.get_path)
      end
    end

    return temp
  end

  #=== copy_attachments_from
  #
  #Copies MailAttachements from the specified E-mail.
  #
  #_src_email_:: Source E-mail.
  #
  def copy_attachments_from(src_email)

    return if src_email.mail_attachments.nil? or src_email.mail_attachments.empty?

    self.status = Email::STATUS_TEMPORARY
    self.save!

    src_email.mail_attachments.each do |org_attach|
      mail_attach = org_attach.clone
      self.mail_attachments << mail_attach
      mail_attach.copy_file_from(org_attach)
    end
    self.save!  # To recalcurate size
  end

  #=== do_smtp
  #
  #Does send E-mails by SMTP.
  #
  #_mail_account_:: MailAccount to send E-mail.
  #
  def do_smtp(mail_account)

    recipients = []

    if self.to_addresses.nil? or self.to_addresses.empty?
      email_to = nil
    else
      email_to = self.get_to_addresses
      recipients.concat(email_to)
      email_to.map! { |addr|
        EmailsHelper.encode_disp_name(addr)
      }
    end
    if self.cc_addresses.nil? or self.cc_addresses.empty?
      email_cc = nil
    else
      email_cc = self.get_cc_addresses
      recipients.concat(email_cc)
      email_cc.map! { |addr|
        EmailsHelper.encode_disp_name(addr)
      }
    end
    if self.bcc_addresses.nil? or self.bcc_addresses.empty?
      email_bcc = nil
    else
      email_bcc = self.get_bcc_addresses
      recipients.concat(email_bcc)
    end

    sender = self.from_address
    email_from = EmailsHelper.encode_disp_name(sender)

    if !self.reply_to.nil? and !self.reply_to.empty?
      reply_to = self.reply_to
    elsif !mail_account.reply_to.nil? and !mail_account.reply_to.empty?
      reply_to = EmailsHelper.encode_disp_name(mail_account.reply_to)
    else
      reply_to = nil
    end

    if mail_account.organization.nil? or mail_account.organization.empty?
      organization = nil
    else
      organization = Mail::Encodings.decode_encode(mail_account.organization, :encode)
    end

    has_attach = !(self.mail_attachments.nil? or self.mail_attachments.empty?)
    boundary = Digest::SHA1.hexdigest(Time.now.to_f.to_s)

    email_content = ''
    email_content << "From: #{email_from}\n"
    email_content << "To: #{email_to.join(",\n ")}\n"
    unless email_cc.nil?
      email_content << "Cc: #{email_cc.join(",\n ")}\n"
    end
    unless reply_to.nil?
      email_content << "Reply-To: #{reply_to}\n"
    end
    unless organization.nil?
      email_content << "Organization: #{organization}\n"
    end
    email_content << "Subject: #{Mail::Encodings.decode_encode(self.subject, :encode)}\n"
    email_content << "Date: #{Time::now.strftime('%a, %d %b %Y %X %z')}\n"
    email_content << "Mime-Version: 1.0\n"
    email_content << "User-Agent: Thetis\n"
    if has_attach
      email_content << "Content-Type: multipart/mixed; boundary=#{boundary}\n"
      email_content << "\n"
      email_content <<  "--#{boundary}\n"
    end
    email_content << "Content-Type: text/plain; charset=utf-8\n"
    email_content << "Content-Transfer-Encoding: base64\n"
    email_content << "\n"
    email_content << "#{[self.message].pack('m')}\n"
=begin
    email_content << <<EOT
#{Base64::encode64(self.message).scan(/.{1,60}/).join("\n")}
EOT
=end

# logger.fatal email_content

    if has_attach
      email_content << "\n"
      self.mail_attachments.each do |mail_attach|
        attach_name = Mail::Encodings.decode_encode(mail_attach.name, :encode)

        attach_content = File.open(mail_attach.get_path).readlines.join('')

        email_content <<  "--#{boundary}\n"
        email_content << "Content-Type: application/octet-stream;\n"
        email_content << " name=\"#{attach_name}\"\n"
        email_content << "Content-Disposition: attachment;\n"
        email_content << " filename=\"#{attach_name}\"\n"
        email_content << "Content-Transfer-Encoding: base64\n"
        email_content << "\n"
        email_content << "#{[attach_content].pack('m')}\n"
      end
      email_content <<  "--#{boundary}--\n"
    end

    # Do SMTP
    smtp = Net::SMTP.new(mail_account.smtp_server, mail_account.smtp_port)

    case mail_account.smtp_secure_conn
      when MailAccount::SMTP_SECURE_CONN_STARTTLS
        context = Net::SMTP. default_ssl_context
        context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        smtp.enable_starttls(context)
        # smtp.enable_starttls_auto 

      when MailAccount::SMTP_SECURE_CONN_SSL_TLS
        smtp.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
    end

    if mail_account.smtp_auth
      smtp.start('localhost.localdomain', mail_account.smtp_username, mail_account.smtp_password, mail_account.smtp_auth_method) do |_smtp|
        _smtp.sendmail(email_content, sender, recipients.uniq)
      end
    else
      smtp.start do |_smtp|
        _smtp.sendmail(email_content, sender, recipients.uniq)
      end
    end

    begin
      self.save_raw(email_content)
    rescue => evar
      Log.add_error(nil, evar)
    end
  end

  #=== self.do_pop
  #
  #Does pop E-mails from server.
  #
  #_mail_account_:: MailAccount to pop E-mails.
  #return:: Array of handled E-mails.
  #
  def self.do_pop(mail_account)

    return nil if mail_account.nil?

    pop = Net::POP3.APOP(mail_account.pop_secure_auth).new(mail_account.pop_server, mail_account.pop_port)
    if mail_account.pop_secure_conn == MailAccount::POP_SECURE_CONN_SSL_TLS
      pop.enable_ssl
    end
    pop.start(mail_account.pop_username, mail_account.pop_password)

    emails = []
    new_uidl = []

    pop.mails.select { |svr_mail|

      new_uidl << svr_mail.unique_id
      mail_account.need_pop?(svr_mail.unique_id)

    }.each do |svr_mail|

      email = Email.parse_mail(Mail.new(svr_mail.pop))
      email.user_id = mail_account.user_id
      email.mail_account_id = mail_account.id
      inbox = MailFolder.get_for(mail_account.user_id, mail_account.id, MailFolder::XTYPE_INBOX)
      unless inbox.nil?
        email.mail_folder_id = inbox.id
      end
      email.uid = svr_mail.unique_id
      email.status = Email::STATUS_UNREAD
      email.xtype = Email::XTYPE_RECV
      email.created_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      email.save!

      email.save_files

      if mail_account.remove_from_server
        svr_mail.delete
      end

      emails << email
    end

    pop.finish

    mail_account.update_attribute(:uidl, new_uidl.join(MailAccount::UIDL_SEPARATOR))

    if THETIS_MAIL_LIMIT_NUM_PER_ACCOUNT > 0
      Email.trim(mail_account.user_id, mail_account.id, THETIS_MAIL_LIMIT_NUM_PER_ACCOUNT)
    end
    if THETIS_MAIL_CAPACITY_MB_PER_ACCOUNT > 0
      Email.trim_by_capacity(mail_account.user_id, mail_account.id, THETIS_MAIL_CAPACITY_MB_PER_ACCOUNT)
    end

    return emails
  end

  #=== self.parse_mail
  #
  #Parses Mail into Email.
  #
  #_mail_:: Mail object as source.
  #return:: Email object.
  #
  def self.parse_mail(mail)

    email = Email.new
    email.parse_mail(mail)
    return email
  end

  #=== parse_mail
  #
  #Parses Mail.
  #
  #_mail_:: Mail object as source.
  #
  def parse_mail(mail)

    @mail = mail

    unless mail.date.nil?
      self.sent_at = mail.date.strftime('%Y-%m-%d %H:%M:%S')
    end

    unless mail.from.nil?
      begin
        addrs = mail[:from].to_s
        addrs = EmailsHelper.split_preserving_quot(addrs, '"', ',')
        self.from_address = addrs.join(Email::ADDRESS_SEPARATOR)
      rescue
        self.from_address = mail.from.join(Email::ADDRESS_SEPARATOR)
      end
    end

    unless mail.to.nil?
      begin
        addrs = mail[:to].to_s
        addrs = EmailsHelper.split_preserving_quot(addrs, '"', ',')
        self.to_addresses = addrs.join(Email::ADDRESS_SEPARATOR)
      rescue
        self.to_addresses = mail.to.join(Email::ADDRESS_SEPARATOR)
      end
    end

    unless mail.cc.nil?
      begin
        addrs = mail[:cc].to_s
        addrs = EmailsHelper.split_preserving_quot(addrs, '"', ',')
        self.cc_addresses = addrs.join(Email::ADDRESS_SEPARATOR)
      rescue
        self.cc_addresses = mail.cc.join(Email::ADDRESS_SEPARATOR)
      end
    end

    unless mail.bcc.nil?
      begin
        addrs = mail[:bcc].to_s
        addrs = EmailsHelper.split_preserving_quot(addrs, '"', ',')
        self.bcc_addresses = addrs.join(Email::ADDRESS_SEPARATOR)
      rescue
        self.bcc_addresses = mail.bcc.join(Email::ADDRESS_SEPARATOR)
      end
    end

    unless mail.reply_to.nil?
      begin
        addrs = mail[:reply_to].to_s
        addrs = EmailsHelper.split_preserving_quot(addrs, '"', ',')
        self.reply_to = addrs.join(Email::ADDRESS_SEPARATOR)
      rescue
        self.reply_to = mail.reply_to.join(Email::ADDRESS_SEPARATOR)
      end
    end

    self.subject = mail.subject

    # Email Body ###
    plain_part = (@mail.multipart?) ? ((@mail.text_part) ? @mail.text_part : nil) : nil
    html_part = (@mail.html_part) ? @mail.html_part : nil
    message_part = plain_part || html_part || @mail

    charset = @mail.header.charset
    charset = nil if !charset.nil? and (charset.casecmp('US-ASCII') == 0)

    charset ||= message_part.header.charset
    charset = nil if !charset.nil? and (charset.casecmp('US-ASCII') == 0)

    message = message_part.body.decoded
    unless charset.nil? or charset.empty?
      message.encode!(Encoding::UTF_8, charset, {:invalid => :replace, :undef => :replace, :replace => ' '})
    end

    self.message = message
  end

  #=== get_to_addresses
  #
  #Gets an Array of To-addresses.
  #
  def get_to_addresses

    return [] if self.to_addresses.nil?
    return self.to_addresses.split(Email::ADDRESS_SEPARATOR)
  end

  #=== get_cc_addresses
  #
  #Gets an Array of Cc-addresses.
  #
  def get_cc_addresses

    return [] if self.cc_addresses.nil?
    return self.cc_addresses.split(Email::ADDRESS_SEPARATOR)
  end

  #=== get_bcc_addresses
  #
  #Gets an Array of Bcc-addresses.
  #
  def get_bcc_addresses

    return [] if self.bcc_addresses.nil?
    return self.bcc_addresses.split(Email::ADDRESS_SEPARATOR)
  end

  #=== save_files
  #
  #Saves Email body and attachment files into directory.
  #
  def save_files

    return if @mail.nil?

    path = self.get_dir
    FileUtils.mkdir_p(path)

    # Raw data
    self.save_raw(@mail.raw_source)

    # Attachment files

    return unless @mail.has_attachments?

    attach_cnt = 0

    @mail.attachments.each_with_index do |attach, idx|

      mail_attachment = MailAttachment.new
      mail_attachment.email_id = self.id
      mail_attachment.name = Mail::Encodings.decode_encode(attach.filename, :decode)
      mail_attachment.content_type = attach.content_type

      temp = Tempfile.new('thetis_mail_part', path)
      temp.binmode
      temp.write(attach.body.decoded)
      mail_attachment.size = temp.size

      temp.close(false)

      mail_attachment.save!

      FileUtils.mv(temp.path, File.join(path, mail_attachment.id.to_s + File.extname(mail_attachment.name)))

      attach_cnt += 1
    end
  end

  #=== save_raw
  #
  #Saves Email raw data as *.eml.
  #
  #_raw_source_:: Email raw data.
  #
  def save_raw(raw_source)

    path = self.get_dir
    FileUtils.mkdir_p(path)

    eml_path = File.join(path, self.id.to_s + Email::EXT_RAW)

    temp = Tempfile.new('thetis_mail_raw', path)
    temp.binmode
    temp.write(raw_source)

    temp.close(false)

    FileUtils.mv(temp.path, eml_path)
  end

  #=== get_raw
  #
  #Gets Email raw data.
  #
  #return:: Email raw data.
  #
  def get_raw

    path = File.join(self.get_dir, self.id.to_s + Email::EXT_RAW)

    if File.exist?(path)
      return open(path) { |f| f.read }
    else
      return ''
    end
  end

  #=== get_dir
  #
  #Gets path of parent directory of the specified Email.
  #
  #return:: Path of parent directory.
  #
  def get_dir

    case xtype
      when XTYPE_SEND
        sub_folder = 'send'
      when XTYPE_RECV
        sub_folder = 'recv'
      else
        sub_folder = 'unknown'
    end

    user_id = self.user_id

    top_name = (user_id / 100 * 100).to_s

    return File.join(THETIS_MAIL_LOCATION_DIR, top_name, user_id.to_s, sub_folder, self.id.to_s)
  end

  #=== self.trim
  #
  #Trims records within specified number.
  #
  #_user_id_:: Target User-ID.
  #_mail_account_id_:: Target MailAccount-ID.
  #_max_:: Max number.
  #
  def self.trim(user_id, mail_account_id, max)
    begin
      count = Email.count(:id, :conditions => "mail_account_id=#{mail_account_id}")
      if count > max
        over_num = count - max
        emails = []

        # First, empty Trashbox
        user = User.find(user_id)
        trashbox = MailFolder.get_for(user, mail_account_id, MailFolder::XTYPE_TRASH)
        trash_nodes = [trashbox.id.to_s]
        trash_nodes += MailFolder.get_childs(trash_nodes.first, true, false)
        con = "mail_folder_id in (#{trash_nodes.join(',')})"
        emails = Email.find(:all, {:conditions => con, :limit => over_num, :order => 'updated_at ASC'})

        # Now, remove others
        if emails.length < over_num
          over_num -= emails.length
          emails += Email.find(:all, {:conditions => "mail_account_id=#{mail_account_id}", :limit => over_num, :order => 'updated_at ASC'})
        end

        emails.each do |email|
          email.destroy
        end
      end
    rescue
    end
  end

  #=== self.trim_by_capacity
  #
  #Trims records within specified capacity.
  #
  #_user_id_:: Target User-ID.
  #_mail_account_id_:: Target MailAccount-ID.
  #_capacity_mb_:: Capacity by MB.
  #
  def self.trim_by_capacity(user_id, mail_account_id, capacity_mb)

    max_size = capacity_mb * 1024 * 1024
    cur_size = MailAccount.get_using_size(mail_account_id)

    if cur_size > max_size
      over_size = cur_size - max_size
      emails = []

      # First, empty Trashbox
      user = User.find(user_id)
      trashbox = MailFolder.get_for(user, mail_account_id, MailFolder::XTYPE_TRASH)
      trash_nodes = [trashbox.id.to_s]
      trash_nodes += MailFolder.get_childs(trash_nodes.first, true, false)
      con = "mail_folder_id in (#{trash_nodes.join(',')})"
      emails = Email.find(:all, {:conditions => con, :order => 'updated_at ASC'})
      emails.each do |email|
        next if email.size.nil?

        email.destroy
        over_size -= email.size
        break if over_size <= 0
      end

      # Now, remove others
      if over_size > 0
        over_num -= emails.length
        emails = Email.find(:all, {:conditions => "mail_account_id=#{mail_account_id}", :order => 'updated_at ASC'})
        emails.each do |email|
          next if email.size.nil?

          email.destroy
          over_size -= email.size
          break if over_size <= 0
        end
      end
    end
  end

  #=== get_attach_size
  #
  #Gets sum of MailAttachments size of this Email.
  #
  def get_attach_size

    return 0 if self.mail_attachments.nil? or self.mail_attachments.empty?

    sum = 0

    self.mail_attachments.each do |attach|
      sum += attach.size
    end

    return sum
  end

  #=== can_attach?
  #
  #Gets if this Email can be attached given size of MailAttachment.
  #
  #_additional_size_:: Additional size of MailAttachment.
  #
  def can_attach?(additional_size)

    return (additional_size <= (THETIS_MAIL_SEND_ATTACHMENT_MAX_KB*1024 - self.get_attach_size))
  end

  #=== get_sent_at_exp
  #
  #Gets expression of sent-at.
  #
  #_req_full_:: Flag to require full expression.
  #return:: Expression of sent-at.
  #
  def get_sent_at_exp(req_full=true)

    return self.get_timestamp_exp(req_full, :sent_at)
  end

  #=== self.destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  #_id_:: Target Email-ID.
  #
  def self.destroy(id)

    id.is_a?(Array) ? id.each { |id| destroy(id) } : find(id).destroy
  end

  #=== self.destroy_by_user
  #
  #Destroy all Emails of specified User's.
  #
  #_user_id_:: Target User-ID.
  #_add_con_:: Additional condition to query by.
  #
  def self.destroy_by_user(user_id, add_con=nil)

    con = "user_id=#{user_id}"
    con << " and (#{add_con})" unless add_con.nil? or add_con.empty?
    emails = Email.find(:all, :conditions => con)

    unless emails.nil?
      emails.each do |email|
        email.destroy
      end
    end
  end

  #=== destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  def destroy()

    path = self.get_dir
    FileUtils.remove_entry_secure(path, true)
    _clean_dir(File.dirname(path))

    super()
  end

  #=== self.delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  #_id_:: Target Email-ID.
  #
  def self.delete(id)

    Email.destroy(id)
  end

  #=== delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  def delete()

    Email.destroy(self.id)
  end

  #=== self.destroy_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.destroy_all(conditions = nil)

    raise 'Use Email.destroy() instead of Email.destroy_all()!'
  end

  #=== self.delete_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.delete_all(conditions = nil)

    raise 'Use Email.destroy() instead of Email.delete_all()!'
  end

  #=== clean_dir
  #
  #Cleans directories where related files are stored.
  #
  def clean_dir

    path = self.get_dir
    _clean_dir(path)
  end

 private
  #=== _clean_dir
  #
  #Cleans directories where related files are stored.
  #
  def _clean_dir(path)

    if File.expand_path(path) == File.expand_path(THETIS_MAIL_LOCATION_DIR)
      return
    end

    files_dirs = Dir.glob(File.join(path, '**/*'))
    if files_dirs.nil? or files_dirs.empty?
      FileUtils.remove_entry_secure(path, true)
      _clean_dir(File.dirname(path))
    end
  end
end
