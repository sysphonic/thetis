#
#= EquipmentController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class EquipmentController < ApplicationController
  layout('base')

  if YamlHelper.get_value($thetis_config, 'menu.req_login_equipment', nil) == '1'
    before_action(:check_login)
  end

  before_action :except => [:show, :list, :schedule_all] do |controller|
    controller.check_auth(User::AUTH_EQUIPMENT)
  end

  #=== new
  #
  #Does nothing about showing empty form to create Equipment.
  #
  def new
    Log.add_info(request, params.inspect)

    render(:action => 'edit', :layout => (!request.xhr?))
  end

  #=== create
  #
  #Creates Equipment.
  #
  def create
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    SqlHelper.validate_token([params[:groups], params[:teams]])

    if params[:groups].blank?
      params[:equipment][:groups] = nil
    else
      params[:equipment][:groups] = ApplicationHelper.a_to_attr(params[:groups])
    end

    if params[:teams].blank?
      params[:equipment][:teams] = nil
    else
      params[:equipment][:teams] = ApplicationHelper.a_to_attr(params[:teams])
    end

    @equipment = Equipment.new(Equipment.permit_base(params.require(:equipment)))

    begin
      @equipment.save!
    rescue => evar
      Log.add_error(request, evar)
      render(:controller => 'equipment', :action => 'edit')
      return
    end

    flash[:notice] = t('msg.register_success')

    list
    render(:action => 'list')
  end

  #=== edit
  #
  #Shows form to edit Equipment's information.
  #
  def edit
    Log.add_info(request, params.inspect)

    @equipment = Equipment.find(params[:id])

    render(:layout => (!request.xhr?))
  end

  #=== show
  #
  #Shows Equipment information.
  #
  def show
    Log.add_info(request, params.inspect)

    @equipment = Equipment.find(params[:id])

    render(:layout => (!request.xhr?))
  end

  #=== update
  #
  #Updates Equipment information.
  #
  def update
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    SqlHelper.validate_token([params[:groups], params[:teams]])

    @equipment = Equipment.find(params[:id])

    if params[:groups].blank?
      params[:equipment][:groups] = nil
    else
      params[:equipment][:groups] = ApplicationHelper.a_to_attr(params[:groups])
    end

    if params[:teams].blank?
      params[:equipment][:teams] = nil
    else
      params[:equipment][:teams] = ApplicationHelper.a_to_attr(params[:teams])
    end

    if @equipment.update_attributes(Equipment.permit_base(params.require(:equipment)))
      flash[:notice] = t('msg.update_success')
      list
      render(:action => 'list')
    else
      render(:controller => 'equipment', :action => 'edit', :id => params[:id])
    end
  end

  #=== list
  #
  #Shows Equipment list.
  #
  def list
    Log.add_info(request, params.inspect)

    con = []

    @group_id = nil
    if !params[:tree_node_id].nil?
      @group_id = params[:tree_node_id]
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    unless @group_id.nil?
      if (@group_id == TreeElement::ROOT_ID.to_s)
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

    if (@sort_col.blank? or @sort_type.blank?)
      @sort_col = 'id'
      @sort_type = 'ASC'
    end
    SqlHelper.validate_token([@sort_col, @sort_type], ['.'])
    order_by = ' order by ' + @sort_col + ' ' + @sort_type

    sql = 'select distinct Equipment.* from equipment Equipment'
    sql << where + order_by

    @equipment_pages, @equipment, @total_num = paginate_by_sql(Equipment, sql, 20)
  end

  #=== destroy
  #
  #Deletes Equipment.
  #
  def destroy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:check_equipment].nil?
      list
      render(:action => 'list')
      return
    end

    count = 0
    params[:check_equipment].each do |equipment_id, value|
      SqlHelper.validate_token([equipment_id])
      if (value == '1')
        Equipment.delete(equipment_id)

        count += 1
      end
    end
    flash[:notice] = count.to_s + t('equipment.deleted')
    list
    render(:action => 'list')
  end

  #=== schedule_all
  #
  #Shows all Equipment's Schedules.
  #
  def schedule_all
    Log.add_info(request, params.inspect)

    date_s = params[:date]
    if date_s.blank?
      @date = Date.today
    else
      @date = Date.parse(date_s)
    end

    if (@login_user.nil? or params[:display].nil? or params[:display] == 'all')
      params[:display] = 'all'
      con = EquipmentHelper.get_scope_condition_for(@login_user)
    else
      display_type = params[:display].split('_').first
      display_id = params[:display].split('_').last

      case display_type
       when 'group'
        if @login_user.get_groups_a(true).include?(display_id)
          con = SqlHelper.get_sql_like([:groups], "|#{display_id}|")
        end
       when 'team'
        if @login_user.get_teams_a.include?(display_id)
          con = SqlHelper.get_sql_like([:teams], "|#{display_id}|")
        end
      end
    end

    return if con.nil?

    equipment_a = Equipment.where(con).to_a
    @equip_obj_cache ||= Equipment.build_cache(equipment_a)

    @equip_schedule_hash = {}
    unless equipment_a.nil?
      @holidays = Schedule.get_holidays
      equipment_a.each do |equip|
        @equip_schedule_hash[equip.id.to_s] = Schedule.get_equipment_week(equip.id, @date, @holidays)
      end
    end
  end
end
