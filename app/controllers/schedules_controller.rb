#
#= SchedulesController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2013 MORITA Shintaro, Sysphonic. All rights reserved.
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
    before_filter :check_login, :only => [:new, :destroy, :save, :edit, :select_users, :get_group_users, :select_items, :get_folder_items, :select_equipment, :get_group_equipment]
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

  rescue => evar
    Log.add_error(request, evar)
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
    render(:partial => 'edit_detail', :layout => false)
  end

  #=== save
  #
  #Saves the Schedule.
  #
  def save
    Log.add_info(request, params.inspect)

    date = Date.parse(params[:date])

    unless params[:id].blank?
      begin
        schedule = Schedule.find(params[:id])
      rescue => evar
        Log.add_error(request, evar)
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

    if params[:users].blank? \
        and params[:groups].blank? \
        and params[:teams].blank? \
        and (params[:schedule][:scope] != Schedule::SCOPE_ALL)

      nearest_day = schedule.get_nearest_day(date)
      schedule.destroy unless schedule.nil?
    else
      [:users, :groups, :teams, :items].each do |attr|
        if params[attr].blank?
          params[:schedule][attr] = nil
        else
          params[:schedule][attr] = '|' + params[attr].join('|') + '|'
        end
      end

      equipment_ids = (params[:equipment] || [])
      equipment_ids.delete('')

      if equipment_ids.empty?
        params[:schedule][:equipment] = nil
      else
        equipment_ids.each do |equipment_id|
          equipment = Equipment.find(equipment_id)
          if equipment.nil? or !equipment.is_accessible_by(@login_user)
            flash[:notice] = 'ERROR:' + t('msg.need_auth_to_access') + t('cap.suffix') + Equipment.get_name(equipment_id)
            redirect_to(:action => 'day', :date => params[:date])
            return
          end
        end
        params[:schedule][:equipment] = '|' + equipment_ids.join('|') + '|'
      end

      if params[:is_repeat] == '1'

        if params[:repeat_rules].blank?
          params[:schedule][:repeat_rule] = nil
        else
          params[:schedule][:repeat_rule] = '|' + params[:repeat_rules].join('|') + '|'
        end

        if params[:excepts].blank?
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

      check_schedule = Schedule.new(params.require(:schedule).permit(Schedule::PERMIT_BASE))
      nearest_day = check_schedule.get_nearest_day(date)
      if nearest_day.nil?
        check_schedule.id = params[:id].to_i unless params[:id].nil? or params[:id].empty?
        flash[:notice] = 'ERROR:' + t('schedule.no_day_in_rule')
        if params[:fwd_controller].nil? or params[:fwd_controller].empty?
          self.index
        else
          prms = ApplicationHelper.get_fwd_params(params)
          prms.delete('id')
          prms.delete('schedule')
          prms[:controller] = params[:fwd_controller]
          prms[:action] = params[:fwd_action]
          redirect_to(prms)
        end
      # redirect_to(:action => 'day', :date => params[:date])
        return
      end

      created = false
      if schedule.nil? or params[:repeat_update_target] == 'each'
        # Create
        params[:schedule][:created_by] = @login_user.id
        params[:schedule][:created_at] = Time.now
        schedule = Schedule.new(params.require(:schedule).permit(Schedule::PERMIT_BASE))
        schedule.save!
        created = true
      else
        # Update
        params[:schedule][:updated_by] = @login_user.id
        params[:schedule][:updated_at] = Time.now
        schedule.update_attributes(params.require(:schedule).permit(Schedule::PERMIT_BASE))
      end

      if params[:repeat_update_target] == 'each'
        # Update original repeated schedule
        org_schedule = Schedule.find(params[:id])
        attrs = ActionController::Parameters.new()
        attrs[:updated_by] = @login_user.id
        attrs[:updated_at] = Time.now
        excepts = org_schedule.get_excepts_a
        excepts << params[:date]
        excepts.sort!
        excepts.reverse!
        attrs[:except] = '|' + excepts.join('|') + '|'
        org_schedule.update_attributes(attrs.permit(Schedule::PERMIT_BASE))
      end

      # prms = {:show_id => schedule.id}
    end

    if created
      flash[:notice] = t('msg.register_success')
    else
      flash[:notice] = t('msg.update_success')
    end

    params[:date] = nearest_day.strftime(Schedule::SYS_DATE_FORM)

    if params[:fwd_controller].blank?
      self.index
      self.show unless self.performed?
    else
      prms = ApplicationHelper.get_fwd_params(params)
      prms.delete('id')
      prms.delete('schedule')
      prms[:controller] = params[:fwd_controller]
      prms[:action] = params[:fwd_action]
      redirect_to(prms)
    end

  rescue => evar
    Log.add_error(request, evar)

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
    rescue => evar
      Log.add_error(request, evar)
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

    render(:partial => 'edit_detail', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    render(:partial => 'edit_detail', :layout => false)
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
    rescue => evar
      Log.add_error(request, evar)
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

  rescue => evar
    Log.add_error(request, evar)

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

      if @login_user.nil?
        check_login
      else
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
      end
      return
    end

    render(:partial => 'show_detail', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    render(:partial => 'show_detail', :layout => false)
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

  rescue => evar
    Log.add_error(request, evar)

    redirect_to(:action => 'day')
  end

  #=== index
  #
  #Shows Schedules for specified diplay type.
  #
  def index
    if params[:action] == 'index'
      Log.add_info(request, params.inspect)
    end

    if params[:display].blank?

    else
      case params[:display]
        when 'month', 'week', 'day'
          params[:action] = params[:display]
        else
          display_type = params[:display].split('_')[0]
          display_id = params[:display].split('_')[1]
          params[:action] = display_type
          params[:id] = display_id
      end
      self.send(params[:action])
      render(:action => params[:action])
=begin
      # 2013-01-13
      # Very long POST data causes Internal Server Error,
      # because Redirection supports only GET method.
      #
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
=end
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

    if params[:user_id].blank?
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
      overlap_h = {}
      equip_ary.each do |equip_id|
        schedule_ary = Schedule.get_equipment_day(equip_id, @date)
        overlaps = Schedule.check_overlap_equipment(equip_id, schedule_ary, @date)
        unless overlaps.empty?
          overlap_h[equip_id] = overlaps
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

    @user_schedule_hash = {}
    unless group_users.nil?
      @holidays = Schedule.get_holidays
      group_users.each do |user|
        @user_schedule_hash[user.id.to_s] = Schedule.get_somebody_week(@login_user, user.id, @date, @holidays)
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
    rescue => evar
      Log.add_error(request, evar)
    end

    @user_schedule_hash = {}
    unless team_users.nil?
      @holidays = Schedule.get_holidays
      team_users.each do |user_id|
        @user_schedule_hash[user_id] = Schedule.get_somebody_week(@login_user, user_id, @date, @holidays)
      end
    end

    params[:display] = params[:action] + '_' + params[:id]
  end

  #=== select_users
  #
  #<Ajax>
  #Shows popup-window to select Users on Groups-Tree.
  #
  def select_users
    Log.add_info(request, params.inspect)

    render(:partial => 'select_users', :layout => false)
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
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    submit_url = url_for(:controller => 'schedules', :action => 'get_group_users')
    render(:partial => 'common/select_users', :layout => false, :locals => {:target_attr => :id, :submit_url => submit_url})
  end

  #=== select_equipment
  #
  #<Ajax>
  #Shows popup-window to select Equipment on Groups-Tree.
  #
  def select_equipment
    Log.add_info(request, params.inspect)

    render(:partial => 'select_equipment', :layout => false)
  end

  #=== get_group_equipment
  #
  #<Ajax>
  #Gets Equipment in specified Group.
  #
  def get_group_equipment
    Log.add_info(request, params.inspect)

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    submit_url = url_for(:controller => 'schedules', :action => 'get_group_equipment')
    render(:partial => 'common/select_equipment', :layout => false, :locals => {:target_attr => :id, :submit_url => submit_url})
  end

  #=== select_items
  #
  #<Ajax>
  #Shows popup-window to select Items on Folders-Tree.
  #
  def select_items
    Log.add_info(request, params.inspect)

    render(:partial => 'select_items', :layout => false)
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
    rescue => evar
      Log.add_error(request, evar)
    end

    submit_url = url_for(:controller => 'schedules', :action => 'get_folder_items')
    render(:partial => 'common/select_items', :layout => false, :locals => {:target_attr => :id, :submit_url => submit_url})
  end
end
