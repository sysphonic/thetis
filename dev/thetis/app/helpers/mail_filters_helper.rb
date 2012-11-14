#
#= MailFiltersHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2012 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about MailFolders.
#
#== Note:
#
#*
#
module MailFiltersHelper

  public::CONDITION_POINTS = [:subject, :from, :message_body, :sent_at, :priority, :status, :to, :cc, :to_cc, :from_to_cc_bcc, :days_from_sent_at, :size]
  public::CONDITION_COMPARES = [:include, :not_include, :equal, :not_equal, :begin_with, :end_with, :in_addressbook, :not_in_addressbook, :before, :after, :more_than, :less_than, :heigher_than, :lower_than]

  public::ACITION_VERBS = [:move, :delete, :read, :abort]


  #=== self.match_conditions?
  #
  #Gets if the specified E-mail matches MailFilter conditions.
  #
  #_email_:: Target E-mail.
  #_conditions_:: Conditions to test.
  #_and_or_:: Mode to combine conditions (:and / :or).
  #return:: true if matched, false otherwise.
  #
  def self.match_conditions?(email, conditions, and_or)

    is_matched = false

    conditions.each do |entry|
      point, compare, val = entry

      is_matched = MailFiltersHelper.send("match_condition_#{point}", email, compare, val)

      return true if is_matched and (and_or.to_s == 'or')
      return false if !is_matched and (and_or.to_s == 'and')
    end

    return is_matched
  end

  def self.match_condition_subject(email, compare, val)

    is_matched = false
    target = (email.subject || '').strip

    case compare.to_sym
      when :include
        is_matched = target.include?(val)
      when :not_include
        is_matched = !target.include?(val)
      when :equal
        is_matched = (target == val)
      when :not_equal
        is_matched = (target != val)
      when :begin_with
        regexp = Regexp.new('^' + Regexp.escape(val))
        is_matched = !(target.match(regexp).nil?)
      when :end_with
        regexp = Regexp.new(Regexp.escape(val) + '$')
        is_matched = !(target.match(regexp).nil?)
    end

#if is_matched
#  Log.add_error(nil, nil, "match_condition_subject: #{target} MATCHED! #{compare} - #{val}")
#end
    return is_matched
  end

  def self.match_condition_message_body(email, compare, val)

    is_matched = false
    target = (email.message || '').strip

    case compare.to_sym
      when :include
        is_matched = target.include?(val)
      when :not_include
        is_matched = !target.include?(val)
      when :equal
        is_matched = (target == val)
      when :not_equal
        is_matched = (target != val)
      when :begin_with
        regexp = Regexp.new('^' + Regexp.escape(val))
        is_matched = !(target.match(regexp).nil?)
      when :end_with
        regexp = Regexp.new(Regexp.escape(val) + '$')
        is_matched = !(target.match(regexp).nil?)
    end

    return is_matched
  end

  def self.match_condition_from(email, compare, val)

    is_matched = false
    target = (email.from_address || '').strip

    case compare.to_sym
      when :include
        is_matched = target.include?(val)
      when :not_include
        is_matched = !target.include?(val)
      when :equal
        is_matched = (target == val)
      when :not_equal
        is_matched = (target != val)
      when :begin_with
        regexp = Regexp.new('^' + Regexp.escape(val))
        is_matched = !(target.match(regexp).nil?)
      when :end_with
        regexp = Regexp.new(Regexp.escape(val) + '$')
        is_matched = !(target.match(regexp).nil?)
      when :in_addressbook
        target = EmailsHelper.extract_addr(target)
        unless target.nil? or target.empty?
          is_matched = !(Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?)
        end
      when :not_in_addressbook
        target = EmailsHelper.extract_addr(target)
        unless target.nil? or target.empty?
          is_matched = Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?
        end
    end

    return is_matched
  end

  def self.match_condition_to(email, compare, val)

    is_matched = false

    email.get_to_addresses.each do |addr|
      target = (addr || '').strip

      case compare.to_sym
        when :include
          is_matched = target.include?(val)
        when :not_include
          is_matched = !target.include?(val)
        when :equal
          is_matched = (target == val)
        when :not_equal
          is_matched = (target != val)
        when :begin_with
          regexp = Regexp.new('^' + Regexp.escape(val))
          is_matched = !(target.match(regexp).nil?)
        when :end_with
          regexp = Regexp.new(Regexp.escape(val) + '$')
          is_matched = !(target.match(regexp).nil?)
        when :in_addressbook
          target = EmailsHelper.extract_addr(target)
          unless target.nil? or target.empty?
            is_matched = !(Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?)
          end
        when :not_in_addressbook
          target = EmailsHelper.extract_addr(target)
          unless target.nil? or target.empty?
            is_matched = Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?
          end
      end

      break if is_matched
    end

    return is_matched
  end

  def self.match_condition_cc(email, compare, val)

    is_matched = false

    email.get_cc_addresses.each do |addr|
      target = (addr || '').strip

      case compare.to_sym
        when :include
          is_matched = target.include?(val)
        when :not_include
          is_matched = !target.include?(val)
        when :equal
          is_matched = (target == val)
        when :not_equal
          is_matched = (target != val)
        when :begin_with
          regexp = Regexp.new('^' + Regexp.escape(val))
          is_matched = !(target.match(regexp).nil?)
        when :end_with
          regexp = Regexp.new(Regexp.escape(val) + '$')
          is_matched = !(target.match(regexp).nil?)
        when :in_addressbook
          target = EmailsHelper.extract_addr(target)
          unless target.nil? or target.empty?
            is_matched = !(Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?)
          end
        when :not_in_addressbook
          target = EmailsHelper.extract_addr(target)
          unless target.nil? or target.empty?
            is_matched = Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?
          end
      end

      break if is_matched
    end

    return is_matched
  end

  def self.match_condition_to_cc(email, compare, val)

    is_matched = false

    addrs = (email.get_to_addresses | email.get_cc_addresses)
    addrs.each do |addr|
      target = (addr || '').strip

      case compare.to_sym
        when :include
          is_matched = target.include?(val)
        when :not_include
          is_matched = !target.include?(val)
        when :equal
          is_matched = (target == val)
        when :not_equal
          is_matched = (target != val)
        when :begin_with
          regexp = Regexp.new('^' + Regexp.escape(val))
          is_matched = !(target.match(regexp).nil?)
        when :end_with
          regexp = Regexp.new(Regexp.escape(val) + '$')
          is_matched = !(target.match(regexp).nil?)
        when :in_addressbook
          target = EmailsHelper.extract_addr(target)
          unless target.nil? or target.empty?
            is_matched = !(Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?)
          end
        when :not_in_addressbook
          target = EmailsHelper.extract_addr(target)
          unless target.nil? or target.empty?
            is_matched = Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?
          end
      end

      break if is_matched
    end

    return is_matched
  end

  def self.match_condition_from_to_cc_bcc(email, compare, val)

    is_matched = false

    addrs = (email.get_to_addresses | email.get_cc_addresses | email.get_bcc_addresses)
    addrs.each do |addr|
      target = (addr || '').strip

      case compare.to_sym
        when :include
          is_matched = target.include?(val)
        when :not_include
          is_matched = !target.include?(val)
        when :equal
          is_matched = (target == val)
        when :not_equal
          is_matched = (target != val)
        when :begin_with
          regexp = Regexp.new('^' + Regexp.escape(val))
          is_matched = !(target.match(regexp).nil?)
        when :end_with
          regexp = Regexp.new(Regexp.escape(val) + '$')
          is_matched = !(target.match(regexp).nil?)
        when :in_addressbook
          target = EmailsHelper.extract_addr(target)
          unless target.nil? or target.empty?
            is_matched = !(Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?)
          end
        when :not_in_addressbook
          target = EmailsHelper.extract_addr(target)
          unless target.nil? or target.empty?
            is_matched = Address.get_by_email(target, User.find_by_id(email.user_id), Address::BOOK_BOTH).empty?
          end
      end

      break if is_matched
    end

    return is_matched
  end

  def self.match_condition_sent_at(email, compare, val)

    is_matched = false
    target = email.sent_at
    return false if target.nil?

    val = DateTime.parse(val)

    case compare.to_sym
      when :equal
        is_matched = (target == val)
      when :not_equal
        is_matched = (target != val)
      when :before
        is_matched = (target < val)
      when :after
        is_matched = (target > val)
    end

    return is_matched
  end

  def self.match_condition_priority(email, compare, val)

    is_matched = false
    target = (email.priority || 0)

    case compare.to_sym
      when :equal
        is_matched = (target == val.to_i)
      when :heigher_than
        is_matched = (target > val.to_i)
      when :lower_than
        is_matched = (target < val.to_i)
    end

    return is_matched
  end

  def self.match_condition_status(email, compare, val)

    is_matched = false
    target = (email.status || '')

    case compare.to_sym
      when :equal
        is_matched = (target == val)
      when :not_equal
        is_matched = (target != val)
    end

    return is_matched
  end

  def self.match_condition_days_from_sent_at(email, compare, val)

    is_matched = false
    target = UtilDate.create(email.sent_at).get_date - Date.today

    case compare.to_sym
      when :equal
        is_matched = (target == val.to_i)
      when :more_than
        is_matched = (target > val.to_i)
      when :less_than
        is_matched = (target < val.to_i)
    end

    return is_matched
  end

  def self.match_condition_size(email, compare, val)

    is_matched = false
    target = email.size

    case compare.to_sym
      when :equal
        is_matched = (target == val.to_i)
      when :more_than
        is_matched = (target > val.to_i)
      when :less_than
        is_matched = (target < val.to_i)
    end

    return is_matched
  end

  #=== self.execute_actions
  #
  #Executes MailFilter actions.
  #
  #_mail_filter_:: Executed MailFilter.
  #_email_:: Target E-mail.
  #_actions_:: Actions to execute.
  #return:: true if it should be continued, false otherwise.
  #
  def self.execute_actions(mail_filter, email, actions)

    actions.each do |entry|
      verb, val = entry

      result = MailFiltersHelper.send("execute_action_#{verb}", mail_filter, email, val)
      return false unless result
    end
    return true
  end

  def self.execute_action_move(mail_filter, email, val)

    mail_folder_id = val

    mail_folder = MailFolder.find_by_id(mail_folder_id)
    if !mail_folder.nil? and (mail_folder.user_id == email.user_id)
      email.update_attribute(:mail_folder_id, mail_folder_id)
    end

    return true
  end

  def self.execute_action_delete(mail_filter, email, val)

    user = User.find_by_id(email.user_id)

    mail_account_id = mail_filter.mail_account_id
    mail_folder = MailFolder.find_by_id(email.mail_folder_id)
    trash_folder = MailFolder.get_for(user, mail_account_id, MailFolder::XTYPE_TRASH)

    if trash_folder.nil? \
        or mail_folder.id == trash_folder.id \
        or mail_folder.get_parents(false).include?(trash_folder.id.to_s)
      email.destroy
    else
      email.update_attribute(:mail_folder_id, trash_folder.id)
    end

    return true
  end

  def self.execute_action_read(mail_filter, email, val)

    if email.xtype == Email::XTYPE_RECV
      email.update_attribute(:status, Email::STATUS_NONE)
    end

    return true
  end

  def self.execute_action_abort(mail_filter, email, val)

    return false
  end

  #=== self.opts_condition_point
  #
  #Gets options for the point of filter condition.
  #
  #_with_blank_opt_:: Flag to request blank option as the first element.
  #return:: Options for the point of filter condition.
  #
  def self.opts_condition_point(with_blank_opt=false)

    opts = []
    opts << [I18n.t('msg.select_item'), nil] if with_blank_opt

    MailFiltersHelper::CONDITION_POINTS.each do |point|
      opts << [I18n.t("mail_filter.condition.point.#{point.to_s}"), point.to_s]
    end
    return opts
  end

  #=== self.opts_condition_compare
  #
  #Gets options for the comparing verb of filter condition.
  #
  #_with_blank_opt_:: Flag to request blank option as the first element.
  #return:: Options for the comparing verb of filter condition.
  #
  def self.opts_condition_compare(with_blank_opt=false)

    opts = []
    opts << [I18n.t('msg.select_item'), nil] if with_blank_opt

    MailFiltersHelper::CONDITION_COMPARES.each do |compare|
      opts << [I18n.t("mail_filter.condition.compare.#{compare.to_s}"), compare.to_s]
    end
    return opts
  end

  #=== self.opts_condition_priority
  #
  #Gets options for the mail priority of filter condition.
  #
  #_with_blank_opt_:: Flag to request blank option as the first element.
  #return:: Options for the mail priority of filter condition.
  #
  def self.opts_condition_priority(with_blank_opt=false)

    priorities = [1, 2, 3, 4, 5]

    opts = []
    opts << [I18n.t('msg.select_item'), nil] if with_blank_opt

    priorities.each do |priority|
      opts << [I18n.t("email.priority.priority_#{priority}"), priority.to_s]
    end
    return opts
  end

  #=== self.opts_condition_status
  #
  #Gets options for the mail status of filter condition.
  #
  #_with_blank_opt_:: Flag to request blank option as the first element.
  #return:: Options for the mail status of filter condition.
  #
  def self.opts_condition_status(with_blank_opt=false)

    opts = []
    opts << [I18n.t('msg.select_item'), nil] if with_blank_opt

    opts << [I18n.t('msg.been_read'), (:been_read).to_s]

    return opts
  end

  #=== self.opts_action_verb
  #
  #Gets options for the verb of filter action.
  #
  #_with_blank_opt_:: Flag to request blank option as the first element.
  #return:: Options for the verb of filter action.
  #
  def self.opts_action_verb(with_blank_opt=false)

    opts = []
    opts << [I18n.t('msg.select_item'), nil] if with_blank_opt

    MailFiltersHelper::ACITION_VERBS.each do |verb|
      opts << [I18n.t("mail_filter.action.verb.#{verb.to_s}"), verb.to_s]
    end
    return opts
  end
end
