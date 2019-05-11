#
#= LocationsController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class LocationsController < ApplicationController
  layout('base')

  before_action(:check_login)
  before_action(:check_owner, :only => [:drop_on_exit, :on_moved])

  before_action :only => [:update_map, :delete_map] do |controller|
    controller.check_auth(User::AUTH_LOCATION)
  end

  #=== open_map
  #
  #Gets Locations of Users.
  #
  def open_map
    Log.add_info(request, params.inspect)

    @group_id = nil

    if !params[:tree_node_id].nil?
      @group_id = params[:tree_node_id]
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    unless params[:keyword].blank?
      con_prim = []
      con_second = []
      key_arr = params[:keyword].split(nil)
      key_arr.each do |key|
        key_quot = SqlHelper.quote(key)
        con_prim << "(name=#{key_quot} or fullname=#{key_quot} or email=#{key_quot})"
        con_second << SqlHelper.get_sql_like([:name, :fullname, :email], key)
      end
      [con_prim, con_second].each do |con|
        next if con.empty?

        begin
          @target_user = User.where(con.join(' and ')).first
        rescue
        end
        next if @target_user.nil?

        target_location = Location.get_for(@target_user)
        unless target_location.nil?
          @group_id ||= target_location.group_id
        end
        break
      end
    end

    @location = Location.get_for(@login_user)
    unless @location.nil?
      @group_id ||= @location.group_id
    end

    group_ids = []
    @group_obj_cache = {}
    if (@location.nil? and @group_id.nil?)
      group_ids = @login_user.get_groups_a(true, @group_obj_cache)
      group_ids << TreeElement::ROOT_ID.to_s
    elsif !@group_id.nil?
      group_ids << @group_id
      if (@group_id.to_i != TreeElement::ROOT_ID)
        group = Group.find_with_cache(@group_id, @group_obj_cache)
        group_ids |= group.get_parents(false, @group_obj_cache)
      end
    end

    @map_group_id = nil
    group_ids.each do |grp_id|
      @office_map = OfficeMap.get_for_group(grp_id)
      if @office_map.img_enabled and (@office_map.img_size > 0)
        @map_group_id = @office_map.group_id
        break
      end
    end

    @locations = Location.get_for_group(@map_group_id)

    unless @location.nil?
      if (@location.group_id == @map_group_id)
        @location.update_attribute(:updated_at, Time.now)
      else
        @location = nil
      end
    end
  end

  #=== get_image
  #
  #Gets the background image of the Desktop.
  #
  def get_image

    begin
      office_map = OfficeMap.find(params[:id])
    rescue
      office_map = nil
    end

    if office_map.nil?
      render(:plain => '')
      return
    end

=begin
# Too much restriction
    if !office_map.group_id.nil? and (office_map.group_id != 0)
      unless User.belongs_to_group?(@login_user, office_map.group_id, true)
        render(:plain => 'ERROR:' + t('msg.need_auth_to_access'))
        return
      end
    end
=end
    response.headers["Content-Type"] = office_map.img_content_type
    response.headers["Content-Disposition"] = "inline"
    render(:plain => office_map.img_content)
  end

  #=== update_map
  #
  #Updates OfficeMap.
  #
  def update_map
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    group_id = params[:group_id]
    SqlHelper.validate_token([group_id])

    @office_map = OfficeMap.get_for_group(group_id, true)
    params[:office_map].delete(:group_id)

    attrs = OfficeMap.permit_base(params.require(:office_map))

    unless params[:file].blank?
      params[:file].original_filename = params[:name] unless params[:name].blank?
      attrs = {:file => params[:file]}
      params.delete(:file)
    end

    @office_map.update_attributes(attrs)

    params.delete(:office_map)

    flash[:notice] = t('msg.update_success')
    render(:partial => 'groups/ajax_group_map', :layout => false)
  end

  #=== delete_map
  #
  #Deletes OfficeMap.
  #
  def delete_map
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    group_id = params[:group_id]
    SqlHelper.validate_token([group_id])

    @office_map = OfficeMap.get_for_group(group_id, false)

    begin
      @office_map.destroy
    rescue => evar
      Log.add_error(request, evar)
    end

    @office_map = OfficeMap.get_for_group(group_id, false)

    flash[:notice] = t('msg.delete_success')
    render(:partial => 'groups/ajax_group_map', :layout => false)
  end

  #=== drop_on_exit
  #
  #Receives dropped event on the exit by Ajax.
  #
  def drop_on_exit
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    SqlHelper.validate_token([params[:id]])

    unless @login_user.nil?
      Location.destroy(params[:id])
    end

    render(:plain => params[:id])
  end

  #=== on_moved
  #
  #Saves Locations' new position by Ajax.
  #
  def on_moved
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    location_id = params[:id]
    SqlHelper.validate_token([location_id])

    if location_id.blank?
      location = Location.get_for(@login_user)
      if location.nil?
        location = Location.new
        location.user_id = @login_user.id
      end
    else
      begin
        location = Location.find(location_id)
      rescue
        location = nil
      end
    end

    unless location.nil?
      group_id = params[:group_id]
      group_id = nil if group_id.empty?
      SqlHelper.validate_token([group_id])
      attrs = ActionController::Parameters.new({group_id: group_id, x: params[:x], y: params[:y]})
      location.update_attributes(Location.permit_base(attrs))
    end

    render(:plain => (location.nil?)?'':location.id.to_s)
  end

 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of the specified Location.
  #
  def check_owner
    return if (params[:id].blank? or @login_user.nil?)

    begin
      owner_id = Location.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    if !@login_user.admin?(User::AUTH_LOCATION) and owner_id != @login_user.id
      Log.add_check(request, '[check_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
