#
#= EquipmentController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Equipment.
#
#== Note:
#
#* 
#
class EquipmentController < ApplicationController
  layout 'base'

  include LoginChecker

  if $thetis_config[:menu]['req_login_equipment'] == '1'
    before_filter :check_login
  end

  before_filter :except => [:show, :list, :schedule_all] do |controller|
    controller.check_auth(User::AUTH_EQUIPMENT)
  end


  #=== new
  #
  #Does nothing about showing empty form to create Equipment.
  #
  def new
    Log.add_info(request, params.inspect)
  end

  #=== create
  #
  #Creates Equipment.
  #
  def create
    Log.add_info(request, params.inspect)

    @equipment = Equipment.new(params[:equipment])

    begin
      @equipment.save!
    rescue StandardError => err
      Log.add_error(request, err)
      render(:controller => 'equipment', :action => 'new')
      return
    end

    flash[:notice] = t('msg.register_success')
    redirect_to(:controller => 'equipment', :action => 'list')
  end

  #=== edit
  #
  #Shows form to edit Equipment's information.
  #
  def edit
    Log.add_info(request, params.inspect)

    @equipment = Equipment.find(params[:id])
  end

  #=== show
  #
  #Shows Equipment information.
  #
  def show
    Log.add_info(request, params.inspect)

    @equipment = Equipment.find(params[:id])
    if @equipment.nil?
      flash[:notice] = t('equipment.already_deleted')
    end
  end

  #=== update
  #
  #Updates Equipment information.
  #
  def update
    Log.add_info(request, params.inspect)

    @equipment = Equipment.find(params[:id])
    if @equipment.update_attributes(params[:equipment])
      # flash[:notice] = t('msg.register_success')
      redirect_to(:controller => 'equipment', :action => 'list')
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

    conditions = nil

    order_by = nil
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if @sort_col.nil? or @sort_type.nil?
      @sort_col = "id"
      @sort_type = "ASC"
    end
    order_by = ' order by ' + @sort_col + ' ' + @sort_type

    sql = 'select distinct Equipment.* from equipment Equipment'
    sql << order_by

    @equipment_pages, @equipment, @total_num = paginate_by_sql(Equipment, sql, 20)
  end

  #=== destroy
  #
  #Deletes Equipment.
  #
  def destroy
    Log.add_info(request, params.inspect)
  
    if params[:check_equipment].nil?
      list
      render(:action => 'list')
      return
    end
    
    count = 0
    params[:check_equipment].each do |equipment_id, value|
      if value == '1'
        Equipment.delete(equipment_id)

        count += 1
      end
    end
    flash[:notice] = count.to_s + t('equipment.deleted')
    redirect_to(:action => 'list')
  end

  #=== schedule_all
  #
  #Shows all Equipment's Schedules.
  #
  def schedule_all
    Log.add_info(request, params.inspect)

    date_s = params[:date]
    if date_s.nil? or date_s.empty?
      @date = Date.today
    else
      @date = Date.parse date_s
    end

    equipment = Equipment.find(:all)

    @equip_schedule_hash = PseudoHash.new
    unless equipment.nil?
      holidays = Schedule.get_holidays
      equipment.each do |equip|
        @equip_schedule_hash[equip.id.to_s, true] = Schedule.get_equipment_week(equip.id, @date, holidays)
      end
    end

    params[:display] = 'all'
  end
end
