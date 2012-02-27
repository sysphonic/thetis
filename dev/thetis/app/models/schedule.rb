#
#= Schedule
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Schedule is related to date (or rules) and Users. It can be also related to Equipment and Items.
#
#== Note:
#
#*
#
class Schedule < ActiveRecord::Base

  require RAILS_ROOT+'/lib/util/util_date'

  validates_presence_of  :title

  public::SYS_DATE_FORM = '%Y-%m-%d'
  public::SYS_DATETIME_FORM = SYS_DATE_FORM + ' %H:%M'
  public::WDAYS = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
  public::LAST_DAY_OF_MONTH = 'last_day'
  public::FIRST_WEEKDAY_OF_MONTH = 'first_weekday'
  public::LAST_WEEKDAY_OF_MONTH = 'last_weekday'

  public::SCOPE_PRIVATE = 'private'
  public::SCOPE_PUBLIC = 'public'
  public::SCOPE_ALL = 'all'

  public::XTYPE_HOLIDAY = 'holiday'

  #=== self.wday_name
  #
  #Gets name of specified weekday.
  #
  def self.wday_name(wday)
    return [I18n.t('wday.sun'), I18n.t('wday.mon'), I18n.t('wday.tue'), I18n.t('wday.wed'), I18n.t('wday.thu'), I18n.t('wday.fri'), I18n.t('wday.sat')][wday]
  end

  #=== self.rule_names
  #
  #Gets hash of rule names.
  #
  def self.rule_names

    ret = PseudoHash.new
    7.times do |wday|
      ret[WDAYS[wday], true] = Schedule::wday_name(wday)
    end
    for day in 1..31
      ret[day.to_s, true] = I18n.t('schedule.day_of_month', :day => day.to_s)
    end
    ret[LAST_DAY_OF_MONTH, true] = I18n.t('schedule.last_day_of_month')
    ret[FIRST_WEEKDAY_OF_MONTH, true] = I18n.t('schedule.first_weekday_of_month')
    ret[LAST_WEEKDAY_OF_MONTH, true] = I18n.t('schedule.last_weekday_of_month')

    return ret
  end

  #=== self.get_holidays
  #
  #Gets all Schedules of holiday.
  #
  def self.get_holidays
    return Schedule.find(:all, :conditions => "xtype = '#{Schedule::XTYPE_HOLIDAY}'", :order => 'start DESC')
  end

  #=== self.check_holiday
  #
  #Gets Schedule of holiday if the specified date is registered as a holiday.
  #
  #_date_:: Target date.
  #_holidays_:: Array of Schedules of holiday.
  #return:: If the specified date is registered as a holiday, the Schedule record. nil otherwise.
  #
  def self.check_holiday(date, holidays=nil)
    if holidays.nil?
      holidays = Schedule.get_holidays
      return nil if holidays.nil?
    end

    holidays.each do |schedule|
      holiday = schedule.start.utc
      if holiday.year == date.year and holiday.month == date.month and holiday.day == date.day
        return schedule
      end
    end
    return nil
  end

  #=== holiday?
  #
  #Gets if this Schedule is holiday.
  #
  #return:: true if holiday, false otherwise.
  #
  def holiday?
    return (self.xtype == Schedule::XTYPE_HOLIDAY)
  end

  #=== public?
  #
  #Gets if this Schedule is public.
  #
  #return:: true if public, false otherwise.
  #
  def public?
    return (self.scope == Schedule::SCOPE_PUBLIC)
  end

  #=== for_all?
  #
  #Gets if this Schedule is displayed for all.
  #
  #return:: true if public, false otherwise.
  #
  def for_all?
    return (self.scope == Schedule::SCOPE_ALL)
  end

  #=== private?
  #
  #Gets if this Schedule is private.
  #
  #return:: true if public, false otherwise.
  #
  def private?
    return (self.scope == Schedule::SCOPE_PRIVATE)
  end

  #=== self.get_title
  #
  #Gets Schedule title.
  #
  #return:: Schedule title.
  #
  def self.get_title(schedule_id)

    begin
      schedule = Schedule.find(schedule_id)
    rescue
    end
    if schedule.nil?
      return schedule_id.to_s + ' '+ I18n.t('paren.deleted')
    else
      return schedule.title
    end
  end

  #=== is_member?(user)
  #
  #Checks if the specified User is a member the Schedule.
  #
  #_user_:: Target User.
  #return:: true if specified user is one of the members, false otherwise.
  #
  def is_member?(user)

    return true if self.get_users_a.include?(user.id.to_s)

    member_groups = self.get_groups_a
    user.get_groups_a(true).each do |group_id|
      return true if member_groups.include?(group_id)
    end

    member_teams = self.get_teams_a
    user.get_teams_a.each do |team_id|
      return true if member_teams.include?(team_id)
    end

    return false
  end

  #=== check_user_auth
  #
  #Checks user authority to read or write contents
  #of the Schedule.
  #
  #_user_:: Target User.
  #_rxw_:: Specify 'r' to check read-authority, 'w' to write-authority.
  #_check_admin_:: Flag to consider about User's authority.
  #return:: true if specified user has authority, false otherwise.
  #
  def check_user_auth(user, rxw, check_admin)

    if check_admin and !user.nil? and user.admin?(User::AUTH_SCHEDULE)
      return true
    end

    if rxw == 'r'
      if self.private?
        if user.nil?
          return false
        else
          if self.is_member?(user)
            return true
          else
            return false
          end
        end
      else
        if $thetis_config[:menu]['req_login_schedules'] == '1'
          if user.nil?
            return false
          else
            return true
          end
        else
          return true
        end
      end

    else  # rxw == 'w'
      if user.nil?
        return false
      else
        if self.for_all? or self.is_member?(user)
          return true
        else
          return false
        end
      end
    end

    return false
  end

  #=== get_nearest_day
  #
  #Gets the nearest day of the specified date corresponding to
  #the rules of the repeated Schedule. If this is not repeated,
  #returns normally the start date.
  #
  #_date_:: Standard date for repeated Schedule.
  #return:: Nearest date (in the future by priority) from specified date. If not exists, returns nil.
  #
  def get_nearest_day(date)

    nearest_day = nil

    date = UtilDate.new(date.year, date.month, date.day)

    if self.repeat?

      excepts = self.get_excepts_a

      self.get_rules_a.each do |rule|

        backward = false
        if !self.repeat_start.nil? and date.before?(self.repeat_start)
          date = UtilDate.create(self.repeat_start)
        elsif !self.repeat_end.nil? and date.after?(self.repeat_end)
          if self.repeat_start.nil?
            date = UtilDate.create(self.repeat_end)
            backward = true
          else
            date = UtilDate.create(self.repeat_start)
          end
        end

        if Schedule::WDAYS.include?(rule)

          unless backward
            d = date.dup
            loop do
              if !self.repeat_end.nil? and d.after?(self.repeat_end)
                backward = true
                break
              end
              if excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                d += 1
                next
              end
              if Schedule::WDAYS[d.wday] == rule
                break
              end
              d += 1
            end
          end
          if backward
            d = date.dup
            loop do
              if !self.repeat_start.nil? and d.before?(self.repeat_start)
                d = nil
                break
              end
              if excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                d -= 1
                next
              end
              if Schedule::WDAYS[d.wday] == rule
                break
              end
              d -= 1
            end
          end

        elsif rule == Schedule::LAST_DAY_OF_MONTH

          found = false
          unless backward
            forward = 0
            loop do
              d = date.dup >> forward
              d = UtilDate.new(d.year, d.month, -1)
              if !self.repeat_end.nil? and d.after?(self.repeat_end)
                backward = true
                break
              end
              unless excepts.include?(d.strftime(Schedule::SYS_DATE_FORM)) and d.after?(date, true)
                break
              end
              forward += 1
            end
          end
          if backward
            backward = 0
            loop do
              d = date.dup << backward
              d = UtilDate.new(d.year, d.month, -1)
              if d.after?(date)
                backward += 1
                next
              end
              if !self.repeat_start.nil? and d.before?(self.repeat_start)
                d = nil
                break
              end
              unless excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                break
              end
              backward += 1
            end
          end

        elsif rule == Schedule::FIRST_WEEKDAY_OF_MONTH

          holidays = Schedule.get_holidays
          found = false
          unless backward
            forward = 0
            loop do
              d = UtilDate.new(date.year, date.month, 1) >> forward
              loop do
                if THETIS_WEEKDAYS.include?(WDAYS[d.wday]) and Schedule.check_holiday(d, holidays).nil?
                  unless excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                    if d.after?(date, true) and (self.repeat_end.nil? or d.before?(self.repeat_end, true))
                      found = true
                    end
                  end
                  break
                end
                d += 1
                if !self.repeat_end.nil? and d.after?(self.repeat_end)
                  backward = true
                  break
                end
              end
              break if found or backward
              forward += 1
            end
          end
          if backward
            backward = 0
            loop do
              d = UtilDate.new(date.year, date.month, 1) << backward
              loop do
                if THETIS_WEEKDAYS.include?(WDAYS[d.wday]) and Schedule.check_holiday(d, holidays).nil?
                  break if d.after?(date)
                  if !self.repeat_start.nil? and d.before?(self.repeat_start)
                    d = nil
                    break
                  end
                  unless excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                    found = true
                  end
                  break
                end
                d += 1
              end
              break if found or d.nil?
              backward += 1
            end
          end

        elsif rule == Schedule::LAST_WEEKDAY_OF_MONTH

          found = false
          unless backward
            forward = 0
            loop do
              d = date.dup >> forward
              d = UtilDate.new(d.year, d.month, -1)
              loop do
                break if date.after?(d)
                if THETIS_WEEKDAYS.include?(WDAYS[d.wday]) and Schedule.check_holiday(d, holidays).nil?
                  if !self.repeat_end.nil? and d.after?(self.repeat_end)
                    backward = true
                    break
                  end
                  unless excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                    found = true
                  end
                  break
                end
                d -= 1
              end
              break if found or backward
              forward += 1
            end
          end
          if backward
            backward = 0
            loop do
              d = date.dup << backward
              d = UtilDate.new(d.year, d.month, -1)
              loop do
                break if d.after?(date)
                if THETIS_WEEKDAYS.include?(WDAYS[d.wday]) and Schedule.check_holiday(d, holidays).nil?
                  if !self.repeat_start.nil? and d.before?(self.repeat_start)
                    d = nil
                    break
                  end
                  unless excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                    found = true
                  end
                  break
                end
                d -= 1
              end
              break if found or d.nil?
              backward += 1
            end
          end

        elsif not (/^\d+$/ =~ rule).nil?

          rule_day = rule.to_i

          unless backward
            forward = 0
            loop do
              d = date.dup >> forward  # 1/31 -> 2/28
              d = UtilDate.new(d.year, d.month, rule_day)
              begin
                if d.before?(date)
                  forward += 1
                  next
                end
                if !self.repeat_end.nil? and d.after?(self.repeat_end)
                  backward = true
                  break
                end
                unless excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                  break
                end
              rescue
              end
              forward += 1
            end
          end
          if backward
            backward = 0
            loop do
              d = date.dup << backward
              d = UtilDate.new(d.year, d.month, rule_day)
              begin
                if !self.repeat_start.nil? and d.before?(self.repeat_start)
                  d = nil
                  break
                end
                unless excepts.include?(d.strftime(Schedule::SYS_DATE_FORM))
                  break
                end
              rescue
              end
              backward += 1
            end
          end

        end

        unless d.nil?
          if nearest_day.nil? or d.before?(nearest_day)
            nearest_day = d.get_date
          end
        end
      end

    else

      nearest_day = self.start
    end

    return nearest_day
  end

  #=== self.check_overlap_equipment
  #
  #Checks if the Equipment overlaps among the specified Schedules.
  #
  #_equipment_id_:: Target Equipment-ID.
  #_schedules_:: Array of the Schedules to check.
  #_date_:: Target Date (for Schedules over days or repeated).
  #return:: Array of the overlapping Schedule-IDs.
  #
  def self.check_overlap_equipment(equipment_id, schedules, date)

    return [] if equipment_id.nil? or schedules.nil? or date.nil?

    target_ary = []
    ret_ary = []

    schedules.each do |schedule|
      next unless schedule.get_equipment_a.include?(equipment_id.to_s)

      target_ary.each do |other|
        if schedule.overlap?(other, date)
          ret_ary = ret_ary | [other.id, schedule.id]
        end
      end

      target_ary << schedule
    end

    return ret_ary
  end

  #=== overlap?
  #
  #Checks if the specified Schedule overlaps this Schedule.
  #
  #_other_:: Target Schedule.
  #_date_:: Target Date (to compare repeated Schedules or those over days).
  #return:: true if the specified Schedules overlap, false otherwise.
  #
  def overlap?(other, date)

    return false if other.nil? or date.nil?

    t_src = self.start
    if self.repeat? or t_src.nil?
      year = date.year; month = date.month; day = date.day
    else
      year = t_src.year; month = t_src.month; day = t_src.day; hour = t_src.hour; min = t_src.min; sec = t_src.sec;
    end
    if self.allday?
      hour = 0; min = 0; sec = 0
    end
    a_start = Time.local(year, month, day, hour, min, sec)

    t_src = self.end
    if self.repeat? or t_src.nil?
      year = date.year; month = date.month; day = date.day
    else
      year = t_src.year; month = t_src.month; day = t_src.day; hour = t_src.hour; min = t_src.min; sec = t_src.sec;
    end
    if self.allday?
      hour = 23; min = 59; sec = 59
    end
    a_end = Time.local(year, month, day, hour, min, sec)

    t_src = other.start
    if other.repeat? or t_src.nil?
      year = date.year; month = date.month; day = date.day
    else
      year = t_src.year; month = t_src.month; day = t_src.day; hour = t_src.hour; min = t_src.min; sec = t_src.sec;
    end
    if other.allday?
      hour = 0; min = 0; sec = 0
    end
    b_start = Time.local(year, month, day, hour, min, sec)

    t_src = other.end
    if other.repeat? or t_src.nil?
      year = date.year; month = date.month; day = date.day
    else
      year = t_src.year; month = t_src.month; day = t_src.day; hour = t_src.hour; min = t_src.min; sec = t_src.sec;
    end
    if other.allday?
      hour = 23; min = 59; sec = 59
    end
    b_end = Time.local(year, month, day, hour, min, sec)

# logger.fatal("#{a_start} ~ #{a_end} vs #{b_start} ~ #{b_end}")

    if a_end <= b_start or b_end <= a_start
      return false
    else
      return true
    end
  end

  #=== get_representative
  #
  #Gets representative User of this Schedule.
  #
  #return:: User-ID of the representative.
  #
  def get_representative

    user_ids = self.get_users_a

    if !self.created_by.nil? and user_ids.include?(self.created_by.to_s)
      return self.created_by.to_s
    end
    if !self.updated_by.nil? and user_ids.include?(self.updated_by.to_s)
      return self.updated_by.to_s
    end
    unless user_ids.empty?
      return user_ids.first
    end
    return nil
  end

  #=== self.get_user_day
  #
  #Gets User's Schedules of specified date including private ones.
  #
  #_user_:: Target User.
  #_date_:: Target date.
  #_holidays_:: Array of Schedules of holidays (Specify to improve response-delay).
  #return:: Schedules of specified User and date.
  #
  def self.get_user_day(user, date, holidays=nil)

    if user.nil?
      con = ["(scope='#{Schedule::SCOPE_ALL}')"]
    else
      members_con = SchedulesHelper.get_members_condition_for(user)
      con = ["(scope='#{Schedule::SCOPE_ALL}' or #{members_con.join(' or ')})"]
    end

    _get_by_day(con, date, holidays)
  end

  #=== self.get_somebody_day
  #
  #Gets User's Schedules of specified date excluding private ones.
  #
  #_login_user_:: Login User.
  #_user_id_:: Target User-ID.
  #_date_:: Target date.
  #_holidays_:: Array of Schedules of holidays (Specify to improve response-delay).
  #return:: Schedules of specified User and date.
  #
  def self.get_somebody_day(login_user, user_id, date, holidays=nil)

    con = SchedulesHelper.get_somebody_conditions(login_user, user_id)

    _get_by_day(con, date, holidays)
  end

  #=== self.get_somebody_week
  #
  #Gets User's Schedules of specified week.
  #
  #_login_user_:: Login User.
  #_user_id_:: Target User-ID.
  #_date_:: Date of the first day of the week.
  #_holidays_:: Array of Schedules of holidays (Specify to improve response-delay).
  #return:: Schedules hash of specified User and week.
  #
  def self.get_somebody_week(login_user, user_id, date, holidays=nil)

    con = SchedulesHelper.get_somebody_conditions(login_user, user_id)

    _get_by_week(con, date, holidays)
  end

  #=== self.get_equipment_day
  #
  #Gets Equipment's Schedules of specified date.
  #
  #_equipment_id_:: Target Equipment-ID.
  #_date_:: Target date.
  #return:: Schedules of specified Equipment and date.
  #
  def self.get_equipment_day(equipment_id, date)

    con = ["(equipment like '%|#{equipment_id}|%')"]
    _get_by_day(con, date)
  end

  #=== self.get_equipment_week
  #
  #Gets Equipment's Schedules of specified week.
  #
  #_equipment_id_:: Target Equipment-ID.
  #_date_:: Date of the first day of the week.
  #_holidays_:: Array of Schedules of holidays (Specify to improve response-delay).
  #return:: Schedules hash of specified Equipment and week.
  #
  def self.get_equipment_week(equipment_id, date, holidays=nil)

    con = ["(equipment like '%|#{equipment_id}|%')"]
    _get_by_week(con, date, holidays)
  end

private
  #=== self._get_by_day
  #
  #Gets Schedules of specified conditions and date.
  #
  #_conditions_:: Array of conditions.
  #_date_:: Target date.
  #_holidays_:: Array of Schedules of holidays (Specify to improve response-delay).
  #return:: Schedules of specified conditions and date.
  #
  def self._get_by_day(conditions, date, holidays=nil)

    if holidays.nil?
      holidays = Schedule.get_holidays
    end
    last_day = Date.new(date.year, date.month, -1)

    last_weekday = last_day
    loop do
      if Schedule.check_holiday(last_weekday, holidays).nil?
        break if THETIS_WEEKDAYS.include?(WDAYS[last_weekday.wday])
      end
      last_weekday -= 1
    end

    first_weekday = Date.new(date.year, date.month, 1)
    loop do
      if Schedule.check_holiday(first_weekday, holidays).nil?
        break if THETIS_WEEKDAYS.include?(WDAYS[first_weekday.wday])
      end
      first_weekday += 1
    end

    con = Marshal.load(Marshal.dump(conditions))
    if con.nil?
      con = ['']
    else
      con[0] << ' and '
    end

    curday = date
    nextday = date + 1

    curday_local = SchedulesHelper.zone_datetime(curday)
    nextday_local = SchedulesHelper.zone_datetime(nextday)

    curday_begins_at = curday_local.utc.strftime(Schedule::SYS_DATETIME_FORM)
    nextday_begins_at = nextday_local.utc.strftime(Schedule::SYS_DATETIME_FORM)

    curday_str = curday.strftime(Schedule::SYS_DATE_FORM)

    con[0] << '('
    con[0] << '('

      con[0] << '('

        # for Once
        con[0] << '(not (allday = 1))'
        con[0] << ' and ('

          con[0] << "((start >= '#{curday_begins_at}') and (start < '#{nextday_begins_at}'))"
          con[0] << ' or '
          con[0] << "((end >= '#{curday_begins_at}') and (end < '#{nextday_begins_at}'))"
          con[0] << ' or '
          con[0] << "((start <= '#{curday_begins_at}') and (end >= '#{nextday_begins_at}'))"

        con[0] << ')'

      con[0] << ') or ('

        con[0] << "(allday = 1) and (start = '#{curday_str}')"

      con[0] << ')'

    con[0] << ') or ('

      # for Repeat
      con[0] << '('
      con[0] << '(repeat_rule like \'%|' + curday.day.to_s + '|%\')'
      con[0] << ' or '
      con[0] << '(repeat_rule like \'%|' + WDAYS[curday.wday] + '|%\')'
      if date.day == first_weekday.day
        con[0] << ' or '
        con[0] << '(repeat_rule like \'%|' + FIRST_WEEKDAY_OF_MONTH + '|%\')'
      end
      if date.day == last_weekday.day
        con[0] << ' or '
        con[0] << '(repeat_rule like \'%|' + LAST_WEEKDAY_OF_MONTH + '|%\')'
      end
      if date.day == last_day.day
        con[0] << ' or '
        con[0] << '(repeat_rule like \'%|' + LAST_DAY_OF_MONTH + '|%\')'
      end
      con[0] << ')'

      con[0] << ' and '

      con[0] << '('
        con[0] << "(repeat_start is null or repeat_start <= '#{curday_str}')"
        con[0] << ' and '
        con[0] << "(repeat_end is null or '#{curday_str}' <= repeat_end)"
      con[0] << ')'

      con[0] << ' and '

      con[0] << '(except is null or not (except like \'%|' + curday_str + '|%\'))'

    con[0] << ')'
    con[0] << ')'

    # Rails 3.0.7 eventually causes the following error in
    # ActiveRecord::Base.sanitize_sql_array:
    #   ArgumentError (malformed format string - %...)
    # To work it around, we should not use the Array wrapper
    # as much as possible.
    #
    con = con[0] if con.length == 1

    schedules = Schedule.find(:all, :conditions => con, :order => 'xtype DESC, start ASC');

    schedules.sort! { |a, b|
      if a.holiday?
        -1
      elsif b.holiday?
        1
      else
        a_start = a.start
        b_start = b.start

        hour_a = 0
        min_a = 0

        unless a.start.nil?
          hour_a = a_start.hour
          min_a = a_start.min
        end

        hour_b = 0
        min_b = 0

        unless b.start.nil?
          hour_b = b_start.hour
          min_b = b_start.min
        end

        if a.repeat?
          time_a = Time.local date.year, date.month, date.day, hour_a, min_a
        else
          time_a = Time.local a_start.year, a_start.month, a_start.day, hour_a, min_a
        end
        if b.repeat?
          time_b = Time.local date.year, date.month, date.day, hour_b, min_b
        else
          time_b = Time.local b_start.year, b_start.month, b_start.day, hour_b, min_b
        end

        time_a.to_i - time_b.to_i
      end
    }

    return schedules
  end

  #=== self._get_by_week
  #
  #Gets Schedules of specified conditions and week.
  #
  #_conditions_:: Array of conditions.
  #_date_:: Date of the first day of the week.
  #_holidays_:: Array of Schedules of holidays (Specify to improve response-delay).
  #return:: Schedules hash of specified conditions and week.
  #
  def self._get_by_week(conditions, date, holidays=nil)

    schedules_h = PseudoHash.new

    7.times do |day_idx|
      curday = date + day_idx
      schedules_h[curday, true] = _get_by_day(conditions, curday, holidays)
    end

    return schedules_h
  end

 public
  #=== self.trim_on_destroy_member
  #
  #Deletes Schedules which cannot be refered by anyone any more.
  #
  #_type_:: Type of the deleted member. (:user / :group / :team)
  #_member_id_:: ID of the deleted member.
  #
  def self.trim_on_destroy_member(type, member_id)
    user_exists_cache = {}
    group_exists_cache = {}
    team_exists_cache = {}

    case type
     when :user
      user_exists_cache[member_id.to_s] = false
      con = "(users like '%|#{member_id}|%')"
     when :group
      group_exists_cache[member_id.to_s] = false
      con = "(groups like '%|#{member_id}|%')"
     when :team
      team_exists_cache[member_id.to_s] = false
      con = "(teams like '%|#{member_id}|%')"
     else
      return
    end
    con << " and (scope != '#{Schedule::SCOPE_ALL}')"

    schedules = Schedule.find(:all, :conditions => con) || []
    schedules.each do |schedule|
      break if SchedulesHelper.check_valid_members(schedule.get_users_a, user_exists_cache, User)
      break if SchedulesHelper.check_valid_members(schedule.get_groups_a, group_exists_cache, Group)
      break if SchedulesHelper.check_valid_members(schedule.get_teams_a, team_exists_cache, Team)
      schedule.destroy
    end
  end

  #=== get_users_a
  #
  #Gets Users array related to this Schedule.
  #
  #return:: Users array without empty element. If no Users, returns empty array.
  #
  def get_users_a

    return [] if self.users.nil? or self.users.empty?

    array = self.users.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_groups_a
  #
  #Gets Groups array related to this Schedule.
  #
  #return:: Groups array without empty element. If no Groups, returns empty array.
  #
  def get_groups_a

    return [] if self.groups.nil? or self.groups.empty?

    array = self.groups.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_teams_a
  #
  #Gets Teams array related to this Schedule.
  #
  #return:: Teams array without empty element. If no Teams, returns empty array.
  #
  def get_teams_a

    return [] if self.teams.nil? or self.teams.empty?

    array = self.teams.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_rules_a
  #
  #Gets repeat-rule array of this Schedule.
  #
  #return:: Repeat rule array without empty element. If no rules, returns empty array.
  #
  def get_rules_a

    return [] if self.repeat_rule.nil? or self.repeat_rule.empty?

    array = self.repeat_rule.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_excepts_a
  #
  #Gets exception array of this Schedule.
  #
  #return:: Exception rule array without empty element. If no exceptions, returns empty array.
  #
  def get_excepts_a

    return [] if self.except.nil? or self.except.empty?

    array = self.except.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_equipment_a
  #
  #Gets Equipment array of this Schedule.
  #
  #return:: Equipment array without empty element. If no Equipment, returns empty array.
  #
  def get_equipment_a

    return [] if self.equipment.nil? or self.equipment.empty?

    array = self.equipment.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_items_a
  #
  #Gets Item array related to this Schedule.
  #
  #return:: Item array without empty element. If no Items, returns empty array.
  #
  def get_items_a

    return [] if self.items.nil? or self.items.empty?

    array = self.items.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== repeat?
  #
  #Checks if this Schedule schould be repeated.
  #
  #return:: true if this Schedule schould be repeated, false otherwise.
  #
  def repeat?

     !self.repeat_rule.nil? and !self.repeat_rule.empty?
  end

  #=== within_a_day?
  #
  #Checks if this Schedule starts and ends within a day.
  #
  #return:: true if this Schedule starts and ends within a day.
  #
  def within_a_day?

     # Repeat and Allday
     return true if self.start.nil? or self.end.nil?

     self.start.strftime(Schedule::SYS_DATE_FORM) == self.end.strftime(Schedule::SYS_DATE_FORM)
  end

  #=== self.get_toys
  #
  #Gets Toys (desktop items) of specified User.
  #
  #_user_:: The target User.
  #return:: Toys (desktop items) of specified User.
  #
  def self.get_toys(user)

    toys = []

    sql = SchedulesHelper.get_list_sql(user)

    unless sql.nil?
      schedules = Schedule.find_by_sql(sql)

      schedules.each do |schedule|
        toys << Toy.copy(nil, schedule)
      end
    end

    return toys
  end

  #=== self.get_feeds
  #
  #Gets Web feeds of specified User.
  #
  #_user_:: The target User.
  #_root_url_:: Root URL.
  #return:: Array of FeedEntry.
  #
  def self.get_feeds(user, root_url)

    sql = SchedulesHelper.get_list_sql(user)

    schedules = Schedule.find_by_sql(sql)

    return self._get_feeds(schedules, '['+Schedule.human_name+'] ', root_url, 'schedule')
  end

  #=== self.get_alarm_feeds
  #
  #Gets Web feeds of specified User.
  #ex.
  #  Schedule which starts at 16:00 today will be noticed
  #  on Feed client from 15:30 to 16:10 in [*Alarm*] category.
  #
  #_user_:: The target User.
  #_root_url_:: Root URL.
  #return:: Array of FeedEntry.
  #
  def self.get_alarm_feeds(user, root_url)

    today = Date.today
    schedules = Schedule.get_user_day(user, today)
    return [] if schedules.nil?

    today_str = today.strftime(Schedule::SYS_DATE_FORM)

    margin_before = 30*60
    margin_after = 10*60

    now = Time.now
    scope = now + margin_before

    alarms = []

    schedules.each do |schedule|

      next if schedule.holiday?

      if schedule.repeat? or schedule.start.strftime(Schedule::SYS_DATE_FORM) == today_str
        if  schedule.allday?
          schedule.updated_at = today
          alarms << schedule
        else
          s = schedule.start
          start_time = Time.mktime(today.year, today.month, today.day, s.hour, s.min, s.sec)

          if now - margin_after <= start_time and start_time <= scope
            schedule.updated_at = start_time - margin_before
            alarms << schedule
          end
        end
      end
    end

    return self._get_feeds(alarms, '['+I18n.t('schedule.alarm_mark')+'] ', root_url, 'alarm')
  end

 private
  #=== self._get_feeds
  #
  #Get Web feeds of specified user.
  #
  #_schedules_:: Schedules to add to RSS.
  #_title_pref_:: Title prefix.
  #_root_url_:: Root URL.
  #_type_:: Type parameter which will be added to the URL to dinstinguish between [Schedule] and [*Alarm*].
  #return:: Array of FeedEntry.
  #
  def self._get_feeds(schedules, title_pref, root_url, type)

    entries = []

    return entries if schedules.nil?

    schedules.each do |schedule|
      feed_entry  = FeedEntry.new
      feed_entry.created_at = schedule.created_at
      feed_entry.updated_at = schedule.updated_at

      if schedule.repeat?

        descript = ''
        unless schedule.allday
          descript << schedule.start.strftime('%H:%M') + ' ~ ' + schedule.end.strftime('%H:%M') + ' / '
        end

        descript << I18n.t('schedule.cap_rule') + ' '
        rules_locale = []
        schedule.get_rules_a.each do |rule|
          rules_locale << rule    #TODO: _(rule)
        end
        descript << rules_locale.join(', ')

        descript << ' / '
        descript << I18n.t('schedule.cap_term') + ' '
        if schedule.repeat_start.nil? and schedule.repeat_end.nil?
          descript << I18n.t('paren.not_specified')
        else
          unless schedule.repeat_start.nil?
            repeat_start = schedule.repeat_start.strftime(THETIS_DATE_FORMAT_YMD)
          else
            repeat_start = ''
          end
          unless schedule.repeat_end.nil?
            repeat_end = schedule.repeat_end.strftime(THETIS_DATE_FORMAT_YMD)
          else
            repeat_end = ''
          end

          descript << repeat_start + ' ~ ' + repeat_end
        end

        unless schedule.get_excepts_a.empty?
          descript << ' / '
          descript << I18n.t('schedule.cap_except') + ' '
          descript << schedule.get_excepts_a.join(', ')
        end

      else

        if schedule.within_a_day?
          descript = schedule.start.strftime(THETIS_DATE_FORMAT_YMD)

          unless schedule.allday
            descript << ' '

            format = '%H:%M'
            descript << schedule.start.strftime(format) + ' ~ ' + schedule.end.strftime(format)
          end
        else
          format = "#{THETIS_DATE_FORMAT_YMD}"
          format << ' %H:%M' unless schedule.allday
          descript = schedule.start.strftime(format) + ' ~ ' + schedule.end.strftime(format)
        end

      end

      date_s = schedule.updated_at.strftime(Schedule::SYS_DATE_FORM)
      feed_entry.link = root_url + ApplicationHelper.url_for(:controller => 'frames', :action => 'index', :default => ApplicationHelper.url_for(:controller => 'schedules', :action => 'show_in_day', :id => schedule.id, :date => date_s), :type => type)
      # Every time 'link' parameter is changed, RSS client will take it for a new item.
      feed_entry.guid = FeedEntry.create_guid(schedule, ApplicationHelper.get_timestamp(schedule))

      feed_entry.content     = descript
      feed_entry.title       = title_pref + schedule.title

      if $thetis_config[:feed]['feed_content'] == '1' and schedule.detail.nil?
        feed_entry.content_encoded = "<![CDATA[#{schedule.detail}]]>"
      end
      entries << feed_entry
    end
    return entries
  end

end
