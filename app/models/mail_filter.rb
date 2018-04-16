#
#= MailFilter
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class MailFilter < ApplicationRecord
  public::PERMIT_BASE = [:title, :enabled, :triggers, :and_or, :conditions, :actions, :xorder]

  validates_presence_of(:title)

  belongs_to(:mail_account)

  public::TRIGGER_CHECKING = 'checking'
  public::TRIGGER_MANUAL = 'manual'

  #=== execute
  #
  #Executes actions registered to the MailFilter.
  #
  #_target_:: Target (a MailFolder, an Email or an Array of Emails).
  #return:: true if it should be continued, false otherwise.
  #
  def execute(target)
    return false unless self.enabled?

    conditions = self.get_conditions
    actions = self.get_actions

    if target.instance_of?(MailFolder)
      mail_folder = target
    elsif target.instance_of?(Email)
      emails = [target]
    else
      emails = target
    end
    emails.each do |email|
      next unless MailFiltersHelper.match_conditions?(email, conditions, self.and_or)

      result = MailFiltersHelper.execute_actions(self, email, actions)
      return false unless result
    end
    return true
  end

  #=== self.get_for
  #
  #Gets MailFilters registered to specified MailAccount.
  #
  #_mail_account_id_:: Target MailAccount-ID.
  #_enabled_:: Flag to obtain enabled or disabled MailFilters.
  #_trigger_:: Target trigger.
  #return:: Array of MailFilters.
  #
  def self.get_for(mail_account_id, enabled=nil, trigger=nil)

    return [] if mail_account_id.nil?

    SqlHelper.validate_token([mail_account_id, trigger])

    con = []
    con << "(mail_account_id=#{mail_account_id.to_i})"
    con << "(enabled=#{(enabled)?(1):(0)})" unless enabled.nil?
    con << SqlHelper.get_sql_like([:triggers], "|#{trigger}|") unless trigger.nil?

    return MailFilter.where(con.join(' and ')).order('(xorder is null) ASC, xorder ASC, id ASC').to_a
  end

  #=== get_conditions
  #
  #Gets condition entries as an Array.
  #
  #return:: Array of condition entries [point, compare, val].
  #
  def get_conditions

    conditions = []

    unless self.conditions.nil? or self.conditions.empty?
      conditions = self.conditions.split("\n").collect {|entry|
        m = entry.match(/\A([a-z_0-9]+)-([a-z_0-9]+)(?:-(.+))?\z/)
        if m.nil?
          []
        else
          [m[1], m[2], m[3]]
        end
      }
    end
    return conditions
  end

  #=== get_actions
  #
  #Gets action entries as an Array.
  #
  #return:: Array of action entries [verb, val].
  #
  def get_actions

    actions = []

    unless self.actions.nil? or self.actions.empty?
      actions = self.actions.split("\n").collect {|entry| entry.split('-') }
    end
    return actions
  end

  #=== editable?
  #
  #Gets if the specified MailFilter is editable by the specified User.
  #
  #_user_:: Target User.
  #return:: true if the specified MailFilter is editable, false otherwise.
  #
  def editable?(user)

    return false if user.nil?

    return true if user.admin?(User::AUTH_MAIL)

    return (self.mail_account.user_id == user.id)
  end

  #=== get_triggers_a
  #
  #Gets Array of trigger strings.
  #
  #return:: Array of trigger strings.
  #
  def get_triggers_a

    return ApplicationHelper.attr_to_a(self.triggers)
  end
end
