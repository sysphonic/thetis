#
#= SchedulesController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Schedules.
#
#== Note:
#
#* 
#
class SchedulesController < ApplicationController
  layout 'base'

  if $thetis_config[:menu]['req_login_schedules'] == '1'
    before_filter :check_login
  else
    before_filter :check_login, :only => [:new, :destroy, :save, :edit, :get_group_users]
  end

  before_filter :only => [:configure, :add_holidays, :delete_holidays] do |controller|
    controller.check_auth(User::AUTH_SCHEDULE)
  end


  #=== configure
  #
  #Shows form of configuration.
  #
  def configure
    Log.add_info(request, params.inspect)

    @holidays = Schedule.get_holidays
  end

  #=== add_holidays
  #
  #<Ajax>
  #Adds holidays.
  #
  def add_holidays
    Log.add_info(request, params.inspect)

    holidays = params[:thetisBoxEdit]
    unless holidays.nil?
      holidays.split("\n").each do |holiday|
        tokens = holiday.split(',')
        date = DateTime.parse(tokens.shift.strip)
        date += date.offset   # 2011-01-01 09:00:00 +0900 (==> 2011-01-01 00:00:00 UTC)
        name = tokens.join(',').strip

        schedule = Schedule.new
        schedule.xtype = Schedule::XTYPE_HOLIDAY
        schedule.scope = Schedule::SCOPE_ALL
        schedule.title = name
        schedule.start = date
        schedule.end = date
        schedule.allday = true
        schedule.save!
      end
    end

    @holidays = Schedule.get_holidays
    render(:partial => 'config_holidays', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)
    flash[:notice] = 'ERROR:' + t('msg.format_invalid')

    @holidays = Schedule.get_holidays
    render(:partial => 'config_holidays', :layout => false)
  end

  #=== delete_holidays
  #
  #<Ajax>
  #Deletes holidays.
  #
  def delete_holidays
    Log.add_info(request, params.inspect)

    holidays = params[:holidays]
    unless holidays.nil?
      holidays.each do |schedule_id|
        Schedule.destroy(schedule_id)
      end
    end

    @holidays = Schedule.get_holidays
    render(:partial => 'config_holidays', :layout => false)
  end

  #=== new
  #
  #<Ajax>
  #Shows the page to register new Schedule.
  #
  def new
    @date = Date.parse(params[:date])
    @schedule = Schedule.new
    @schedule.scope = Schedule::SCOPE_PUBLIC
    @schedule.start = DateTime.parse(@date.strftime(Schedule::SYS_DATE_FORM+' 08:00 '+Time.zone.to_s))
    @schedule.end = DateTime.parse(@date.strftime(Schedule::SYS_DATE_FORM+' 09:00 '+Time.zone.to_s))
    render(:partial => 'ajax_edit_detail', :layout => false)
  end

  #=== save
  #
  #Saves the Schedule.
  #
  def save
    Log.add_info(request, params.inspect)

    date = Date.parse(params[:date])

    unless params[:id].nil? or params[:id].empty?
      begin
        schedule = Schedule.find(params[:id])
      rescue StandardError => err
        Log.add_error(request, err)
        flash[:notice] = 'ERROR:' + t('msg.already_deleted', :name => Schedule.model_name.human)
        redirect_to(:action => 'day', :date => date.strftime(Schedule::SYS_DATE_FORM))
        return
      end

      unless schedule.check_user_auth(@login_user, 'w', true)

        Log.add_check(request, '[Schedule.check_user_auth]'+request.to_s)

        if @login_user.nil?
          check_login
        else
          redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
        end
        return
      end
    end

    if (params[:users].nil? or params[:users].empty?) \
        and (params[:groups].nil? or params[:groups].empty?) \
        and (params[:teams].nil? or params[:teams].empty?) \
        and (params[:schedule][:scope] != Schedule::SCOPE_ALL)

        nearest_day = schedule.get_nearest_day(date)
        schedule.destroy unless schedule.nil?
    else

      if params[:users].nil? or params[:users].empty?
        params[:schedule][:users] = nil
      else
        params[:schedule][:users] = '|' + params[:users].join('|') + '|'
      end

      if params[:groups].nil? or params[:groups].empty?
        params[:schedule][:groups] = nil
      else
        params[:schedule][:groups] = '|' + params[:groups].join('|') + '|'
      end

      if params[:teams].nil? or params[:teams].empty?
        params[:schedule][:teams] = nil
      else
        params[:schedule][:teams] = '|' + params[:teams].join('|') + '|'
      end

      if params[:equipment].nil? or params[:equipment].empty?
        params[:schedule][:equipment] = nil
      else
        params[:equipment].each do |equipment_id|
          equipment = Equipment.find(equipment_id)
          if equipment.nil? or !equipment.is_accessible_by(@login_user)
            flash[:notice] = 'ERROR:' + t('msg.need_auth_to_access') + t('cap.suffix') + Equipment.get_name(equipment_id)
            redirect_to(:action => 'day', :date => params[:date])
            return
          end
        end
        params[:schedule][:equipment] = '|' + params[:equipment].join('|') + '|'
      end

      if params[:items].nil? or params[:items].empty?
        params[:schedule][:items] = nil
      else
        params[:schedule][:items] = '|' + params[:items].join('|') + '|'
      end

      if params[:is_repeat] == '1'

        if params[:repeat_rules].nil? or params[:repeat_rules].empty?
          params[:schedule][:repeat_rule] = nil
        else
          params[:schedule][:repeat_rule] = '|' + params[:repeat_rules].join('|') + '|'
        end

        if params[:excepts].nil? or params[:excepts].empty?
          params[:schedule][:except] = nil
        else
          excepts = params[:excepts]
          excepts.sort!
          excepts.reverse!
          params[:schedule][:except] = '|' + excepts.join('|') + '|'
        end

      else

        params[:schedule][:repeat_rule] = nil
        params[:schedule][:repeat_start] = nil
        params[:schedule][:repeat_end] = nil
        params[:schedule][:except] = nil
      end

      params[:schedule][:end] = SchedulesHelper.regularize(params[:schedule][:end])

      check_schedule = Schedule.new(params[:schedule])
      nearest_day = check_schedule.get_nearest_day(date)
      if nearest_day.nil?
        check_schedule.id = params[:id].to_i unless params[:id].nil? or params[:id].empty?
        session[:edit_schedule] = check_schedule
        flash[:notice] = 'ERROR:' + t('schedule.no_day_in_rule')
        redirect_to(:action => 'day', :date => params[:date])
        return
      end

      created = false
      if schedule.nil? or params[:repeat_update_target] == 'each'
        # Create
        params[:schedule][:created_by] = @login_user.id
        params[:schedule][:created_at] = Time.now
        schedule = Schedule.new(params[:schedule])
        schedule.save!
        created = true
      else
        # Update
        params[:schedule][:updated_by] = @login_user.id
        params[:schedule][:updated_at] = Time.now
        schedule.update_attributes(params[:schedule])
      end

      if params[:repeat_update_target] == 'each'
        # Update original repeated schedule
        org_schedule = Schedule.find(params[:id])
        attrs = {}
        attrs[:updated_by] = @login_user.id
        attrs[:updated_at] = Time.now
        excepts = org_schedule.get_excepts_a
        excepts << params[:date]
        excepts.sort!
        excepts.reverse!
        attrs[:except] = '|' + excepts.join('|') + '|'
        org_schedule.update_attributes(attrs)
      end

      prms = {:show_id => schedule.id}
    end

    if created
      flash[:notice] = t('msg.register_success')
    else
      flash[:notice] = t('msg.update_success')
    end

    prms ||= {}
    prms[:action] = 'day'
    prms[:id] = nearest_day.strftime(Schedule::SYS_DATE_FORM)
    redirect_to(prms)

  rescue StandardError => err
    Log.add_error(request, err)

    date = Date.parse(params[:date])
    redirect_to(:action => 'day', :date => date.strftime(Schedule::SYS_DATE_FORM))
  end

  #=== edit
  #
  #<Ajax>
  #Shows the page to edit Schedule.
  #
  def edit
    Log.add_info(request, params.inspect)

    @date = Date.parse(params[:date])
    @schedule = Schedule.find(params[:id])

    begin
      schedule = Schedule.find(params[:id])
    rescue StandardError => err
      Log.add_error(request, err)
      flash[:notice] = 'ERROR:' + t('msg.already_deleted', :name => Schedule.model_name.human)
      render(:text => '')
      return
    end

    unless schedule.check_user_auth(@login_user, 'w', true)

      Log.add_check(request, '[Schedule.check_user_auth]'+request.to_s)

      if @login_user.nil?
        check_login
      else
        flash[:notice] = 'ERROR:' + t('schedule.need_auth_to_edit')
        render(:text => '')
      end
      return
    end

    render(:partial => 'ajax_edit_detail', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    render(:partial => 'ajax_edit_detail', :layout => false)
  end

  #=== destroy
  #
  #<Ajax>
  #Destroys specified Schedule.
  #
  def destroy
    Log.add_info(request, params.inspect)

    @date = Date.parse(params[:date])

    begin
      schedule = Schedule.find(params[:id])
    rescue StandardError => err
      Log.add_error(request, err)
      @schedules = Schedule.get_user_day(@login_user, @date)
      render(:partial => 'timetable', :layout => false)
      return
    end

    unless schedule.check_user_auth(@login_user, 'w', true)

      Log.add_check(request, '[Schedule.check_user_auth]'+request.to_s)

      if @login_user.nil?
        check_login
      else
        flash[:notice] = 'ERROR:' + t('schedule.need_auth_to_edit_destroy')
        @schedules = Schedule.get_user_day(@login_user, @date)
        render(:partial => 'timetable', :layout => false)
      end
      return
    end

    schedule.destroy

    @schedules = Schedule.get_user_day(@login_user, @date)

    render(:partial => 'timetable', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    @schedules = Schedule.get_user_day(@login_user, @date)
    render(:partial => 'timetable', :layout => false)
  end

  #=== show
  #
  #<Ajax>
  #Shows detail of specified Schedule.
  #
  def show
    Log.add_info(request, params.inspect)

    @schedule = Schedule.find(params[:id])

    unless @schedule.check_user_auth(@login_user, 'r', true)

      Log.add_check(request, '[Schedule.check_user_auth]'+request.to_s)

      if login_user.nil?
        check_login
      else
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
      end
      return
    end

    render(:partial => 'ajax_show_detail', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    render(:partial => 'ajax_show_detail', :layout => false)
  end

  #=== show_in_day
  #
  #Shows detail of specified Schedule with a day-timetable.
  #
  def show_in_day
    Log.add_info(request, params.inspect)

    schedule = Schedule.find(params[:id])

    date_s = params[:date]
    date_s = Date.today.strftime(Schedule::SYS_DATE_FORM) if date_s.nil?
    date = Date.parse(date_s)

    nearest_day = schedule.get_nearest_day(date)
    date_s = nearest_day.strftime(Schedule::SYS_DATE_FORM) unless nearest_day.nil?

    redirect_to(:action => 'day', :date => date_s, :show_id => schedule.id)

  rescue StandardError => err
    Log.add_error(request, err)

    redirect_to(:action => 'day')
  end

  #=== index
  #
  #Shows Schedules for specified diplay type.
  #
  def index
    Log.add_info(request, params.inspect)

    if params[:display].nil? or params[:display].empty?

    else
      prms = ApplicationHelper.get_fwd_params(params)

      case params[:display]
        when 'month'
          prms[:action] = 'month'
          redirect_to(prms)
        when 'week'
          prms[:action] = 'week'
          redirect_to(prms)
        when 'day'
          prms[:action] = 'day'
          redirect_to(prms)
        else
          display_type = params[:display].split('_')[0]
          display_id = params[:display].split('_')[1]
          prms[:action] = display_type
          prms[:id] = display_id
          redirect_to(prms)
      end
    end
  end

  #=== month
  #
  #Shows calendar.
  #
  def month
    Log.add_info(request, params.inspect)

    date_s = params[:date]

    if date_s.nil? or date_s.empty?
      @date = Date.today
    else
      @date = Date.parse(date_s)
    end

    if params[:user_id].nil? and !@login_user.nil? and !session[:settings].nil?
      timecard_icons = params[:timecard_icons]

      if timecard_icons.nil?
        params[:timecard_icons] = session[:settings][Setting::KEY_CALENDAR_WITH_TIMECARD_ICONS]
      else
        if timecard_icons != session[:settings][Setting::KEY_CALENDAR_WITH_TIMECARD_ICONS]
          Setting.save_value(@login_user.id, Setting::CATEGORY_SCHEDULE, Setting::KEY_CALENDAR_WITH_TIMECARD_ICONS, timecard_icons)
          session[:settings][Setting::KEY_CALENDAR_WITH_TIMECARD_ICONS] = timecard_icons
        end
      end

      if params[:timecard_icons] == 'true'
        start_date, end_date = TimecardsHelper.get_month_span(@date, 1)
        @timecards = Timecard.find_term(@login_user.id, start_date, end_date)
      end
    end

    params[:display] = 'month'
  end

  #=== week
  #
  #Shows Schedules of a week.
  #
  def week
    Log.add_info(request, params.inspect)

    date_s = params[:date]

    if date_s.nil? or date_s.empty?
      @date = Date.today
    else
      @date = Date.parse(date_s)
    end
    params[:display] = 'week'
  end

  #=== day
  #
  #Shows Schedules of a day.
  #
  def day
    Log.add_info(request, params.inspect)

    date_s = params[:date]

    if date_s.nil? or date_s.empty?
      @date = Date.today
    else
      @date = Date.parse(date_s)
    end

    if params[:user_id].nil? or params[:user_id].empty?
      user_id = @login_user.id unless @login_user.nil?
      @schedules = Schedule.get_user_day(@login_user, @date)
    else
      user_id = params[:user_id].to_i
      @schedules = Schedule.get_somebody_day(@login_user, user_id, @date)
    end

    schedule_id = nil
    schedule_id = params[:show_id] unless params[:show_id].nil?
    schedule_id = params[:edit_id] unless params[:edit_id].nil?
    unless schedule_id.nil?
      begin
        @schedule = Schedule.find(schedule_id)

        unless @schedule.check_user_auth(@login_user, 'r', true)

          Log.add_check(request, '[Schedule.check_user_auth]'+request.to_s)

          if @login_user.nil?
            check_login
          else
            redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
          end
          return
        end
      rescue
      end
    end

    if !@login_user.nil? and user_id == @login_user.id and !@schedules.nil?
      equip_ary = []
      @schedules.each do |schedule|
        equip_ary = equip_ary | schedule.get_equipment_a
      end
      overlap_h = PseudoHash.new
      equip_ary.each do |equip_id|
        schedule_ary = Schedule.get_equipment_day(equip_id, @date)
        overlaps = Schedule.check_overlap_equipment(equip_id, schedule_ary, @date)
        unless overlaps.empty?
          overlap_h[equip_id, true] = overlaps
        end
      end
      unless overlap_h.empty?
        flash[:notice] = 'ERROR:' + t('schedule.conflict_equipment')
        flash[:notice] << '<br/>'
        overlap_h.each do |equip_id, schedule_ary|
          flash[:notice] << '&laquo;' + Equipment.get_name(equip_id) + '&raquo;<br/>'
          flash[:notice] << '<ul style=\'padding-left:40px;\'>'
          schedule_ary.each do |schedule_id|
            flash[:notice] << '<li>' + Schedule.get_title(schedule_id) + '</li>'
          end
          flash[:notice] << '</ul>'
        end
      end
    end

    params[:display] = 'day'
  end

  #=== group
  #
  #Shows Schedules of the Group to which Login-User belongs.
  #
  def group
    Log.add_info(request, params.inspect)

    date_s = params[:date]
    if date_s.nil? or date_s.empty?
      @date = Date.today
    else
      @date = Date.parse(date_s)
    end

    @group_id = params[:id]
    group_users = Group.get_users(params[:id])

    @user_schedule_hash = PseudoHash.new
    unless group_users.nil?
      @holidays = Schedule.get_holidays
      group_users.each do |user|
        @user_schedule_hash[user.id.to_s, true] = Schedule.get_somebody_week(@login_user, user.id, @date, @holidays)
      end
    end

    params[:display] = params[:action] + '_' + params[:id]
  end

  #=== team
  #
  #Shows Schedules of the Team to which Login-User belongs.
  #
  def team
    Log.add_info(request, params.inspect)

    date_s = params[:date]
    if date_s.nil? or date_s.empty?
      @date = Date.today
    else
      @date = Date.parse(date_s)
    end

    begin
      team = Team.find(params[:id])
      team_users = team.get_users_a
    rescue StandardError => err
      Log.add_error(request, err)
    end

    @user_schedule_hash = PseudoHash.new
    unless team_users.nil?
      @holidays = Schedule.get_holidays
      team_users.each do |user_id|
        @user_schedule_hash[user_id, true] = Schedule.get_somebody_week(@login_user, user_id, @date, @holidays)
      end
    end

    params[:display] = params[:action] + '_' + params[:id]
  end

  #=== get_folder_items
  #
  #<Ajax>
  #Gets Items in specified Folder.
  #
  def get_folder_items
    Log.add_info(request, params.inspect)

    unless params[:thetisBoxSelKeeper].nil? or params[:thetisBoxSelKeeper].empty?
      @folder_id = params[:thetisBoxSelKeeper].split(':').last
    end

    begin
      if Folder.check_user_auth(@folder_id, @login_user, 'r', true)
        @items = Folder.get_items(@login_user, @folder_id)
      end

      unless params[:schedule_id].nil? or params[:schedule_id].empty?
        @schedule = Schedule.find(params[:schedule_id])
      end
    rescue StandardError => err
      Log.add_error(request, err)
    end

    render(:partial => 'ajax_select_items', :layout => false)
  end

  #=== get_group_users
  #
  #<Ajax>
  #Gets Users in specified Group.
  #
  def get_group_users
    Log.add_info(request, params.inspect)

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].nil? and !params[:group_id].empty?
      @group_id = params[:group_id]
    end

    @users = Group.get_users(@group_id)

    render(:partial => 'ajax_select_users', :layout => false)
  end
end
