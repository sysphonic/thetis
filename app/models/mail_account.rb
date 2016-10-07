#
#= MailAccount
#
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#== Note:
#
#* 
#
class MailAccount < ActiveRecord::Base
  public::PERMIT_BASE = [:title, :user_id, :is_default, :smtp_server, :smtp_port, :smtp_secure_conn, :smtp_auth, :smtp_auth_method, :smtp_username, :smtp_password, :pop_server, :pop_port, :pop_username, :pop_password, :pop_secure_conn, :pop_secure_auth, :from_name, :from_address, :reply_to, :organization, :remove_from_server, :xorder, :xtype]

  validates_presence_of(:title)

  has_many(:mail_filters, ->(rec) {order('mail_filters.xorder asc')}, {:dependent => :destroy})

  public::UIDL_SEPARATOR = "\n"

  public::POP_SECURE_CONN_NONE = 'none'
  public::POP_SECURE_CONN_STARTTLS = 'starttls'
  public::POP_SECURE_CONN_SSL_TLS = 'ssl_tls'

  public::SMTP_SECURE_CONN_NONE = 'none'
  public::SMTP_SECURE_CONN_STARTTLS = 'starttls'
  public::SMTP_SECURE_CONN_SSL_TLS = 'ssl_tls'

  public::XTYPE_INTERNET = 'internet'
  public::XTYPE_INTRANET = 'intranet'

  #=== self.get_xtype_name
  #
  #Gets String which represents xtype of the class.
  #
  #_xtype_:: String which represents xtype of the class.
  #return:: String which represents xtype of the class.
  #
  def self.get_xtype_name(xtype)
    case xtype
      when XTYPE_INTERNET
        return I18n.t('mail_account.xtype.internet')
      when XTYPE_INTRANET
        return I18n.t('mail_account.xtype.intranet')
    end
  end

  #=== get_capacity_mb
  #
  #Gets Mailbox Capacity in MB.
  #
  #return:: Mailbox Capacity in MB.
  #
  def get_capacity_mb

    return THETIS_MAIL_CAPACITY_MB_PER_ACCOUNT
    #return (self.capacity_mb.nil?)?(THETIS_MAIL_CAPACITY_MB_PER_ACCOUNT):(self.capacity_mb)
  end

  #=== self.get_using_size
  #
  #Gets using size of specified MailAccount.
  #
  #_mail_account_id_:: Target MailAccount-ID.
  #_add_con_:: Additional condition to query by.
  #return:: Using size.
  #
  def self.get_using_size(mail_account_id, add_con=nil)

    SqlHelper.validate_token([mail_account_id])

    con = []
    con << "(mail_account_id=#{mail_account_id.to_i})"
    con << "(#{add_con})" unless add_con.nil? or add_con.empty?

    return (Email.count_by_sql("select SUM(size) from emails where #{con.join(' and ')}") || 0)
  end

  #=== self.get_title
  #
  #Gets MailAccount title.
  #
  #_mail_account_id_:: Target MailAccount-ID.
  #return:: MailAccount title.
  #
  def self.get_title(mail_account_id)

    begin
      mail_account = MailAccount.find(mail_account_id)
    rescue
    end
    if mail_account.nil?
      return mail_account_id.to_s + ' '+ I18n.t('paren.deleted')
    else
      return mail_account.get_title
    end
  end

  #=== get_title
  #
  #Gets MailAccount title.
  #
  #return:: MailAccount title.
  #
  def get_title

    ret = self.title

    if ret.nil? or ret.empty?
      ret = MailAccount.get_xtype_name(self.xtype)
    end

    return ret
  end

  #=== get_from_exp
  #
  #Gets From expression.
  #
  #return:: From expression.
  #
  def get_from_exp

    return nil if self.from_address.nil?

    from_exp = "<#{self.from_address}>"

    unless self.from_name.nil? or self.from_name.empty?
      from_exp = "#{self.from_name} #{from_exp}"
    end

    return from_exp
  end

  #=== need_pop?
  #
  #Gets if we need pop mail which has specified Unique-ID.
  #
  #_uid_:: Unique-ID of the target E-mail.
  #return:: true if we need pop this mail, false otherwise.
  #
  def need_pop?(uid)
    self.uidl.nil? or !self.uidl.split(MailAccount::UIDL_SEPARATOR).include?(uid)
  end

  #=== self.destroy_by_user
  #
  #Destroy all MailAccounts of specified User's.
  #
  #_user_id_:: Target User-ID.
  #_add_con_:: Additional condition to query with.
  #
  def self.destroy_by_user(user_id, add_con=nil)

    SqlHelper.validate_token([user_id])

    con = "(user_id=#{user_id.to_i})"
    con << " and (#{add_con})" unless add_con.nil? or add_con.empty?
    mail_accounts = MailAccount.where(con).to_a

    mail_accounts.each do |mail_account|
      mail_account.destroy
    end
  end

  #=== self.destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  #_id_:: Target User-ID.
  #
  def self.destroy(id)

    id.is_a?(Array) ? id.each { |id| destroy(id) } : find(id).destroy
  end

  #=== destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  def destroy()

    super()
  end

  #=== self.delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  #_id_:: Target MailAccount-ID.
  #
  def self.delete(id)

    MailAccount.destroy(id)
  end

  #=== delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  def delete()

    MailAccount.destroy(self.id)
  end

  #=== self.destroy_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.destroy_all(conditions = nil)

    raise 'Use MailAccount.destroy() instead of MailAccount.destroy_all()!'
  end

  #=== self.delete_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.delete_all(conditions = nil)

    raise 'Use MailAccount.destroy() instead of MailAccount.delete_all()!'
  end

  #=== self.find_all
  #
  #Finds all MailAccounts in order to display with specified condition.
  #
  #_con_:: Condition (String without 'where '). If not required, specify nil.
  #return:: Array of MailAccounts.
  #
  def self.find_all(con = nil)

    where = ''

    unless con.nil? or con.empty?
      where = 'where ' + con
    end

    MailAccount.find_by_sql('select * from mail_accounts ' + where + ' order by xorder ASC, title ASC')
  end

  #=== self.get_default_for
  #
  #Get User-specific default MailAccount, or nil if not found.
  #
  #_user_id_:: Target User-ID.
  #_xtype_:: Target xtype.
  #return:: Default MailAccount.
  #
  def self.get_default_for(user_id, xtype=nil)

    SqlHelper.validate_token([user_id, xtype])

    con = []
    con << "(user_id=#{user_id.to_i})"
    con << '(is_default=1)'
    con << "(xtype='#{xtype}')" unless xtype.blank?

    where = ''
    unless con.nil? or con.empty?
      where = 'where ' + con.join(' and ')
    end

    mail_accounts = MailAccount.find_by_sql('select * from mail_accounts ' + where + ' order by xorder ASC, title ASC')

    if mail_accounts.nil? or mail_accounts.empty?
      return nil
    else
      return mail_accounts.first
    end
  end
end
