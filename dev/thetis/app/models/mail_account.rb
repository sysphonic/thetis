#
#= MailAccount
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
class MailAccount < ActiveRecord::Base

  validates_presence_of :title

  public::UIDL_SEPARATOR = "\n"

  public::POP_SECURE_CONN_NONE = 'none'
  public::POP_SECURE_CONN_STARTTLS = 'starttls'
  public::POP_SECURE_CONN_SSL_TLS = 'ssl_tls'

  public::SMTP_SECURE_CONN_NONE = 'none'
  public::SMTP_SECURE_CONN_STARTTLS = 'starttls'
  public::SMTP_SECURE_CONN_SSL_TLS = 'ssl_tls'


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
  #return:: Default MailAccount.
  #
  def self.get_default_for(user_id)

    con = []
    con << "(user_id = #{user_id})"
    con << '(is_default = 1)'

    where = ''
    unless con.nil? or con.empty?
      where = 'where ' + con.join(' and ')
    end

    account_ary = MailAccount.find_by_sql('select * from mail_accounts ' + where + ' order by xorder ASC, title ASC')

    if account_ary.nil? or account_ary.empty?
      return nil
    else
      return account_ary.first
    end
  end
end
