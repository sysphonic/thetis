#
#= SchedulesHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about Schedules.
#
#== Note:
#
#*
#
module SchedulesHelper

  #=== self.zone_datetime
  #
  #Gets zoned date time.
  #
  #_dt_:: Target date time.
  #return:: Zoned date time.
  #
  def self.zone_datetime(dt)

    return Time.zone.parse(dt.strftime(Schedule::SYS_DATETIME_FORM))
  end

  #=== self.get_members_condition_for
  #
  #Gets array of the SQL condition clauses about membership
  #of the specified User.
  #
  #_user_:: The target User.
  #return:: Array of SQL condition clauses about membership.
  #
  def self.get_members_condition_for(user)
    members_con = ["(users like '%|#{user.id}|%')"]
    user.get_groups_a(true).each do |group_id|
      members_con << "(groups like '%|#{group_id}|%')"
    end
    user.get_teams_a.each do |team_id|
      members_con << "(teams like '%|#{team_id}|%')"
    end
    return members_con
  end

  #=== self.get_list_sql
  #
  #Gets SQL for list of some latest Schedules.
  #
  #_user_:: The target User.
  #return:: SQL to get list.
  #
  def self.get_list_sql(user)

    sql = 'select distinct * from schedules'

    if user.nil?
      sql << " where (scope='#{Schedule::SCOPE_ALL}')"
    else
      members_con = SchedulesHelper.get_members_condition_for(user)
      sql << " where ((scope='#{Schedule::SCOPE_ALL}') or #{members_con.join(' or ')})"
    end

    sql << " and ((xtype != '#{Schedule::XTYPE_HOLIDAY}') or (xtype is null))"

    sql << ' order by updated_at DESC limit 0,10'

    return sql
  end

  #=== self.regularize
  #
  #Regularizes date string.
  #For example, '2007-01-01 25:00' to '2007-01-02 1:00'.
  #
  #_date_:: Date string to regularize.
  #return:: Result string which represents regularized date.
  #
  def self.regularize(date)

    return date if date.nil? or date.empty?

    _date = date.split(' ').first
    time = date.split(' ').last
    hour = time.split(':').first
    min = time.split(':').last

    if hour.to_i >= 24

      reg_str = _date + ' ' + (hour.to_i-24).to_s + ':' + min
      dt = DateTime.parse(reg_str) + 1
      return dt.strftime(THETIS_DATE_FORMAT_YMD+' %H:%M');

    else

      return date
    end
  end

  #=== self.get_somebody_conditions
  #
  #Gets conditions to quote someone's Schedules.
  #
  #_login_user_:: Login User.
  #_user_id_:: Target User-ID.
  #return:: Conditions to quote someone's Schedules.
  #
  def self.get_somebody_conditions(login_user, user_id)

    if login_user.nil? or user_id.nil?
      con = ["(scope='#{Schedule::SCOPE_ALL}')"]
    elsif login_user.admin?(User::AUTH_SCHEDULE) or login_user.id.to_s == user_id.to_s
      members_con = SchedulesHelper.get_members_condition_for(User.find(user_id))
      con = ["(scope='#{Schedule::SCOPE_ALL}' or #{members_con.join(' or ')})"]
    else
      con = []
      con << "(scope='#{Schedule::SCOPE_ALL}')"
      diff_con = []
      diff_con << "(users like '%|#{user_id}|%')"

      target_user = User.find(user_id)

      group_obj_cache = {}
      target_user_groups = target_user.get_groups_a(true, group_obj_cache)
      login_user_groups = login_user.get_groups_a(true, group_obj_cache)

      common_groups = target_user_groups & login_user_groups
      common_groups.each do |group_id|
        con << "(groups like '%|#{group_id}|%')"
      end
      diff_groups = target_user_groups - login_user_groups
      diff_groups.each do |group_id|
        diff_con << "(groups like '%|#{group_id}|%')"
      end

      target_user_teams = target_user.get_teams_a
      login_user_teams = login_user.get_teams_a

      common_teams = target_user_teams & login_user_teams
      common_teams.each do |team_id|
        con << "(teams like '%|#{team_id}|%')"
      end
      diff_teams = target_user_teams - login_user_teams
      diff_teams.each do |team_id|
        diff_con << "(teams like '%|#{team_id}|%')"
      end

      unless diff_con.empty?
        con << "((#{diff_con.join(' or ')}) and (((users like '%|#{login_user.id}|%')) or (scope != '#{Schedule::SCOPE_PRIVATE}')))"
      end

      con = ['(' + con.join(' or ') + ')']
    end

    return con
  end
end
