#
#= TimecardsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Timecards.
#
#== Note:
#
#* 
#
class TimecardsController < ApplicationController
  layout 'base', :except => [:export]

  before_filter :check_login
  before_filter :only => [:configure, :update_config, :update_default_break, :delete_default_break, :paidhld_update, :paidhld_update_multi, :search, :users] do |controller|
    controller.check_auth(User::AUTH_TIMECARD)
  end

  require ::Rails.root.to_s+'/lib/util/util_datetime'


  #=== month
  #
  #Shows timecards of the specified User by month.
  #
  def month
    if params[:action] == 'month'
      Log.add_info(request, params.inspect)
    end

    if !params[:display].nil? and params[:display].split('_').first == 'group'
      @group_id = params[:display].split('_').last
    end

    if params[:user_id].nil?
      @selected_user = @login_user
    else
      @selected_user = User.find(params[:user_id])

      if @selected_user.id != @login_user.id and !@login_user.admin?(User::AUTH_TIMECARD)
        if (@selected_user.get_groups_a & @login_user.get_groups_a).empty?
          Log.add_check(request, '[User::AUTH_TIMECARD]'+request.to_s)
          redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
          return
        end
      end
    end

    year_begins_from, month_begins_at = TimecardsHelper.get_fiscal_params

    date_s = params[:date]

    if date_s.nil? or date_s.empty?
      date = Date.today
    else
      date_params = date_s.split('-')
      if date_params.length == 2
        @year = date_params.first.to_i
        @month = date_params.last.to_i
        date = TimecardsHelper.get_first_day_in_fiscal_month(@year, @month, month_begins_at)
      else
        date = Date.parse date_s
      end
    end

    @fiscal_year = TimecardsHelper.get_fiscal_year(date, year_begins_from, month_begins_at)
    fiscal_month = TimecardsHelper.get_fiscal_month(date, month_begins_at)

    if @year.nil? or @month.nil?
      @month = fiscal_month

      if fiscal_month < date.month and fiscal_month == 1
        @year = date.year + 1
      elsif fiscal_month > date.month and fiscal_month == 12
        @year = date.year - 1
      else
        @year = date.year
      end
    end

    @start_date, @end_date = TimecardsHelper.get_month_span(date, month_begins_at)

    @timecards = Timecard.find_term(@selected_user.id, @start_date, @end_date)

    @paid_holiday = PaidHoliday.get_for(@selected_user.id, @fiscal_year)

    year_start, year_end = TimecardsHelper.get_year_span(@fiscal_year, year_begins_from, month_begins_at)
    @applied_paid_hlds = Timecard.applied_paid_hlds(@selected_user.id, year_start, @start_date - 1)
  end

  #=== export
  #
  #Exports timecards of the specified User by month.
  #
  def export
    Log.add_info(request, '')   # Not to show passwords.

    unless params[:user_id].nil?
      if params[:user_id] != @login_user.id.to_s and !@login_user.admin?(User::AUTH_TIMECARD)
        Log.add_check(request, '[User::AUTH_TIMECARD]'+request.to_s)
        render(:text => 'ERROR:' + t('msg.need_auth_to_access'))
        return
      end
    end

    month
  end

  #=== edit
  #
  #Shows the form to edit Timecard.
  #
  def edit
    Log.add_info(request, params.inspect)

    date_s = params[:date]

    if date_s.blank?
      @date = Date.today
      date_s = @date.strftime(Schedule::SYS_DATE_FORM)
    else
      @date = Date.parse(date_s)
    end

    if params[:user_id].nil?
      @selected_user = @login_user
    else
      @selected_user = User.find(params[:user_id])
    end

    @timecard = Timecard.get_for(@selected_user.id, date_s)

    if @selected_user == @login_user
      @schedules = Schedule.get_user_day(@login_user, @date)
    end

    if !params[:display].nil? and params[:display].split('_').first == 'group'
      @group_id = params[:display].split('_').last
    end
  end

  #=== update
  #
  #<Ajax>
  #Updates timecard.
  #
  def update
    Log.add_info(request, params.inspect)

    if params[:id].nil? or params[:id].empty?
      @timecard = Timecard.new
    else
      @timecard = Timecard.find(params[:id])
    end

    options = params[:timecard]['options']
    if options.nil?
      params[:timecard]['options'] = nil
    else
      params[:timecard]['options'] = '|' + options.join('|') + '|'
    end

    if params[:user_id].nil? or params[:user_id].empty?
      @selected_user = @login_user
    elsif @login_user.id.to_s == params[:user_id]
      @selected_user = @login_user
    else
      unless @login_user.admin?(User::AUTH_TIMECARD)
        Log.add_check(request, '[User::AUTH_TIMECARD]'+request.to_s)
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
        return
      end

      @selected_user = User.find(params[:user_id])
    end

    if Timecard.off?(params[:timecard]['workcode'])
      params[:timecard]['start'] = nil
      params[:timecard]['end'] = nil
      params[:timecard]['options'] = nil
    else

      breaks = @timecard.get_breaks_a
      unless breaks.empty?
        check_error = false

        unless params[:timecard]['start'].nil? or params[:timecard]['start'].empty?
          start_t = UtilDateTime.parse(params[:timecard]['start']).to_time
          check_error = true if breaks.first.first < start_t
        end

        unless params[:timecard]['end'].nil? or params[:timecard]['end'].empty?
          end_t = UtilDateTime.parse(params[:timecard]['end']).to_time
          check_error = true if end_t < breaks.last.last
        end

        if check_error
          flash[:notice] = 'ERROR:' + t('timecard.break_out_of_labor')
          render(:partial => 'ajax_update_break', :layout => false)
          return
        end
      end
    end

    if (@login_user.id.to_s != params[:timecard][:user_id] and !@login_user.admin?(User::AUTH_TIMECARD)) \
        or (!@timecard.user_id.nil? and @timecard.user_id.to_s != params[:timecard][:user_id])
      Log.add_check(request, '[User::AUTH_TIMECARD]'+request.to_s)
      redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
      return
    end

    if @timecard.update_attributes(params.require(:timecard).permit(Timecard::PERMIT_BASE))

      if @timecard.off? and !@timecard.get_breaks_a.empty?
        @timecard.update_breaks(nil)
      end

      flash[:notice] = t('msg.update_success')

      unless @timecard.start.nil? or @timecard.end.nil?
        @timecard.set_default_breaks
      end
    end

    render(:partial => 'ajax_update_break', :layout => false)
  end

  #=== destroy
  #
  #Deletes timecard.
  #
  def destroy
    Log.add_info(request, params.inspect)

    begin
      timecard = Timecard.find(params[:id])

      if timecard.user_id != @login_user.id and !@login_user.admin?(User::AUTH_TIMECARD)
        Log.add_check(request, '[User::AUTH_TIMECARD]'+request.to_s)
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
        return
      end

      date = timecard.date
      timecard.destroy unless timecard.nil?
    rescue => evar
    end

    flash[:notice] = t('msg.delete_success')

    prms = ApplicationHelper.get_fwd_params(params)
    prms.delete(:id)
    prms[:action] = 'edit'
    prms[:date] = date unless date.nil?

    redirect_to(prms)
  end

  #=== recent_descriptions
  #
  #<Ajax>
  #Gets recent descriptions to select.
  #
  def recent_descriptions
    Log.add_info(request, params.inspect)

    sql = "select distinct comment from timecards where user_id=#{@login_user.id} order by updated_at DESC limit 0,10"
    @timecards = Timecard.find_by_sql(sql)

    render(:partial => 'ajax_recent_descriptions', :layout => false)
  end

  #=== update_break
  #
  #<Ajax>
  #Updates break.
  #
  def update_break
    Log.add_info(request, params.inspect)

    unless params[:user_id].nil?
      @selected_user = User.find(params[:user_id])

      if @selected_user.id != @login_user.id and !@login_user.admin?(User::AUTH_TIMECARD)
        Log.add_check(request, '[User::AUTH_TIMECARD]'+request.to_s)
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
        return
      end
    end

    @timecard = Timecard.find(params[:id])

    @date = Date.parse params[:date]
    start_dt = UtilDateTime.new(@date.year, @date.month, @date.day, params[:start_hour].to_i, params[:start_min].to_i)
    end_dt = UtilDateTime.new(@date.year, @date.month, @date.day, params[:end_hour].to_i, params[:end_min].to_i)

    if start_dt == end_dt
      flash[:notice] = 'ERROR:' + t('timecard.break_without_span')
      render(:partial => 'ajax_update_break', :layout => false)
      return
    end

    org_start_t = start_dt.to_time
    org_end_t = end_dt.to_time

    if org_end_t < org_start_t
      end_dt += 1
    else
      if (@timecard.end.nil? or @timecard.start.day != @timecard.end.day) and org_end_t <= @timecard.start
        start_dt += 1
        end_dt += 1
      end
    end

    start_t = start_dt.to_time
    end_t = end_dt.to_time

    if @timecard.start <= start_t and (@timecard.end.nil? or end_t <= @timecard.end)

      if params[:org_start].nil?
        org_start = nil
      else
        org_start = UtilDateTime.parse(params[:org_start]).to_time
      end

      unless @timecard.update_break(org_start, start_t, end_t)
        flash[:notice] = 'ERROR:' + t('timecard.break_overlap')
      end

    else

      flash[:notice] = 'ERROR:' + t('timecard.break_out_of_labor')
    end

    render(:partial => 'ajax_update_break', :layout => false)
  end

  #=== delete_break
  #
  #<Ajax>
  #Deletes break.
  #
  def delete_break
    Log.add_info(request, params.inspect)

    @timecard = Timecard.find(params[:id])

    if params[:org_start].nil?
      org_start = nil
    else
      org_start = UtilDateTime.parse(params[:org_start]).to_time
    end

    @timecard.delete_break(org_start)

    unless params[:user_id].nil?
      @selected_user = User.find(params[:user_id])

      if @selected_user.id != @login_user.id and !@login_user.admin?(User::AUTH_TIMECARD)
        Log.add_check(request, '[User::AUTH_TIMECARD]'+request.to_s)
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
        return
      end
    end

    render(:partial => 'ajax_update_break', :layout => false)
  end

  #=== group
  #
  #Shows Timecards of Users of the specified Group.
  #
  def group
    Log.add_info(request, params.inspect)

    date_s = params[:date]

    if date_s.nil? or date_s.empty?
      @date = Date.today
      date_s = @date.strftime(Schedule::SYS_DATE_FORM)
    else
      @date = Date.parse date_s
    end

    if params[:display] == 'mine'
      redirect_to(:action => 'month')
    else
      display_type = params[:display].split('_').first
      display_id = params[:display].split('_').last

      @selected_users = Group.get_users(display_id)
      @group_id = display_id

      if !@login_user.get_groups_a.include?(@group_id.to_s) and !@login_user.admin?(User::AUTH_TIMECARD)
        Log.add_check(request, '[User.get_groups_a.include?]'+request.to_s)
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
        return
      end
    end
  end

  #=== users
  #
  #Shows Users list.
  #
  def users
    if params[:action] == 'users'
      Log.add_info(request, params.inspect)
    end

    con = ['User.id > 0']
    unless params[:keyword].blank?
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        con << SqlHelper.get_sql_like([:name, :email, :fullname, :address, :organization, :tel1, :tel2, :tel3, :fax, :url, :postalcode, :title], key)
      end
    end

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    unless @group_id.nil?
      if @group_id == '0'
        con << "((groups like '%|0|%') or (groups is null))"
      else
        con << SqlHelper.get_sql_like([:groups], "|#{@group_id}|")
      end
    end

    where = ''
    unless con.empty?
      where = ' where ' + con.join(' and ')
    end

    order_by = nil
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if @sort_col.blank? or @sort_type.blank?
      @sort_col = "xorder"
      @sort_type = "ASC"
    end

    if @sort_col == 'name' and $thetis_config[:user]['by_full_name'] == '1'
      @sort_col == 'fullname'
    end

    SqlHelper.validate_token([@sort_col, @sort_type])
    order_by = ' order by ' + @sort_col + ' ' + @sort_type

    if @sort_col != 'xorder'
      order_by << ', xorder ASC'
    end
    if @sort_col != 'name'
      order_by << ', name ASC'
    end

    sql = 'select distinct User.* from users User'
    sql << where + order_by

    @user_pages, @users, @total_num = paginate_by_sql(User, sql, 50)
  end

  #=== paidhld_list
  #
  #<Ajax>
  #Shows list of paid holidays of the specified User.
  #
  def paidhld_list
    Log.add_info(request, params.inspect)

    @year_begins_from, @month_begins_at = TimecardsHelper.get_fiscal_params

    if params[:user_id].nil?
      @selected_user = @login_user
    else
      @selected_user = User.find(params[:user_id])

      if @selected_user.id != @login_user.id and !@login_user.admin?(User::AUTH_TIMECARD)
        Log.add_check(request, '[User::AUTH_TIMECARD]'+request.to_s)
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
        return
      end
    end

    @paid_holidays = PaidHoliday.get_for(@selected_user.id)

    render(:partial => 'ajax_paidhld_list', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    render(:partial => 'ajax_paidhld_list', :layout => false)
  end

  #=== paidhld_update
  #
  #Updates number of paid holidays of specified User and year.
  #
  def paidhld_update
    Log.add_info(request, params.inspect)

    year = params[:year].to_i
    num = params[:num].to_f

    user = User.find(params[:user_id])

    unless user.nil?
      PaidHoliday.update_for(user.id, year, num)
    end

    flash[:notice] = t('msg.update_success')

    paidhld_list

  rescue => evar
    Log.add_error(request, evar)

    paidhld_list
  end

  #=== paidhld_update_multi
  #
  #Updates number of paid holidays of specified Users.
  #
  def paidhld_update_multi
    Log.add_info(request, params.inspect)

    year = params[:year].to_i
    num = params[:num].to_f

    group_id = params[:group_id]
    users_hash = (params[:check_user] || {})
    done = false
    users_hash.each do |user_id, value|
      if value == '1'
        PaidHoliday.update_for(user_id, year, num)
        done = true
      end
    end

    unless done
      if group_id.blank?
        users = (User.find_all || [])
      else
        users = Group.get_users(group_id)
      end

      users.each do |user|
        PaidHoliday.update_for(user.id, year, num)
      end
    end
    flash[:notice] = t('msg.update_success')

    self.users
    render(:action => 'users')

  rescue => evar
    Log.add_error(request, evar)
    flash[:notice] = 'ERROR:' + evar.to_s

    self.users
    render(:action => 'users')
  end

  #=== search
  #
  #Searches Users.
  #
  def search
    Log.add_info(request, params.inspect)

    self.users
    render(:action => 'users')
  end

  #=== configure
  #
  #Shows form of configuration.
  #
  def configure
    Log.add_info(request, params.inspect)

    yaml = ApplicationHelper.get_config_yaml
    @yaml_timecard = yaml[:timecard]
    @yaml_timecard = Hash.new if @yaml_timecard.nil?
  end

  #=== update_config
  #
  #<Ajax>
  #Updates configuration about timecards.
  #
  def update_config
    Log.add_info(request, params.inspect)

    yaml = ApplicationHelper.get_config_yaml

    unless params[:timecard].nil? or params[:timecard].empty?
      yaml[:timecard] = Hash.new if yaml[:timecard].nil?
      
      params[:timecard].each do |key, val|
        yaml[:timecard][key] = val
      end
      ApplicationHelper.save_config_yaml(yaml)
    end

    @yaml_timecard = yaml[:timecard]
    @yaml_timecard = Hash.new if @yaml_timecard.nil?

    flash[:notice] = t('msg.update_success')
    render(:action => 'configure')
  end

  #=== update_default_break
  #
  #<Ajax>
  #Updates default break.
  #
  def update_default_break
    Log.add_info(request, params.inspect)

    start_t = Time.local(2000, 1, 1, params[:start_hour].to_i, params[:start_min].to_i)
    end_t = Time.local(2000, 1, 1, params[:end_hour].to_i, params[:end_min].to_i)

    if start_t == end_t
      flash[:notice] = 'ERROR:' + t('timecard.break_without_span')
      render(:partial => 'ajax_config_break', :layout => false)
      return
    end

    if params[:org_start].nil?
      org_start = nil
    else
      org_start = UtilDateTime.parse(params[:org_start]).to_time
    end

    yaml = ApplicationHelper.get_config_yaml

    yaml[:timecard] = Hash.new if yaml[:timecard].nil?
    spans = yaml[:timecard]['default_breaks']
    spans = [] if spans.nil?

    found = false
    spans.each do |span|
      if span.first == org_start
        span[0] = start_t
        span[1] = end_t
        found = true
        break
      end
    end
    unless found
      spans << [start_t, end_t]
    end

    begin
      spans = Timecard.sort_breaks(spans)

      yaml[:timecard]['default_breaks'] = spans

      ApplicationHelper.save_config_yaml(yaml)

    rescue
      yaml = ApplicationHelper.get_config_yaml
      flash[:notice] = 'ERROR:' + t('timecard.break_overlap')
    end

    @yaml_timecard = yaml[:timecard]
    @yaml_timecard = Hash.new if @yaml_timecard.nil?

    render(:partial => 'ajax_config_break', :layout => false)
  end

  #=== delete_default_break
  #
  #<Ajax>
  #Deletes default break.
  #
  def delete_default_break
    Log.add_info(request, params.inspect)

    unless params[:org_start].nil?
      org_start = UtilDateTime.parse(params[:org_start]).to_time

      yaml = ApplicationHelper.get_config_yaml

      unless yaml[:timecard].nil? or yaml[:timecard]['default_breaks'].nil?

        yaml[:timecard]['default_breaks'].each do |span|
          if span.first == org_start
            yaml[:timecard]['default_breaks'].delete(span)
            ApplicationHelper.save_config_yaml(yaml)
            break
          end
        end
      end
    end

    @yaml_timecard = yaml[:timecard]
    @yaml_timecard = Hash.new if @yaml_timecard.nil?

    render(:partial => 'ajax_config_break', :layout => false)
  end
end
