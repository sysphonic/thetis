#
#= LocationsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Desktop.
#
#== Note:
#
#* 
#
class LocationsController < ApplicationController
  layout 'base'

  before_filter :check_login
  before_filter :check_owner, :only => [:drop_on_exit, :on_moved]

  before_filter :only => [:update_map, :delete_map] do |controller|
    controller.check_auth(User::AUTH_LOCATION)
  end


  #=== open_map
  #
  #<Ajax>
  #Gets Locations of Users.
  #
  def open_map
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].nil? and !params[:group_id].empty?
      group_id = params[:group_id]
    end

    @location = Location.get_for(login_user)
    unless @location.nil?
      group_id ||= @location.group_id
    end

    group_ids = []
    group_obj_cache = {}
    if group_id.nil?
      group_ids = login_user.get_groups_a(true, group_obj_cache)
      group_ids << '0'  # '0' for ROOT
    else
      group_ids << group_id
      if group_id != 0
        group = Group.find_with_cache(group_id, group_obj_cache)
        group_ids |= group.get_parents(false, group_obj_cache)
      end
    end

    @group_id = nil
    group_ids.each do |group_id|
      @office_map = OfficeMap.get_for_group(group_id)
      if @office_map.img_enabled and (@office_map.img_size > 0)
        @group_id = @office_map.group_id
        break
      end
    end

    @locations = Location.get_for_group(@group_id)

    @location = nil if !@location.nil? and (@location.group_id != @group_id)

    render(:partial => 'ajax_get_map', :layout => false)
  end

  #=== get_image
  #
  #Gets the background image of the Desktop.
  #
  def get_image

    login_user = session[:login_user]

    begin
      office_map = OfficeMap.find(params[:id])
    rescue
      office_map = nil
    end

    if office_map.nil?
      render(:text => '')
      return
    end

=begin
# Too much striction
    if !office_map.group_id.nil? and (office_map.group_id != 0)
      unless User.belongs_to_group?(login_user, office_map.group_id, true)
        render(:text => 'ERROR:' + t('msg.need_auth_to_access'))
        return
      end
    end
=end
    response.headers["Content-Type"] = office_map.img_content_type
    response.headers["Content-Disposition"] = "inline"
    render(:text => office_map.img_content)
  end

  #=== update_map
  #
  #Updates OfficeMap.
  #
  def update_map
    Log.add_info(request, params.inspect)

    group_id = params[:group_id]

    @office_map = OfficeMap.get_for_group(group_id, true)

    params[:office_map].delete(:group_id)

    @office_map.update_attributes(params[:office_map])

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

    group_id = params[:group_id]

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
  #<Ajax>
  #Receives dropped event on the exit by Ajax.
  #
  def drop_on_exit
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    unless login_user.nil?
      Location.destroy(params[:id])
    end

    render(:text => params[:id])
  end

  #=== on_moved
  #
  #<Ajax>
  #Saves Locations' new position by Ajax.
  #
  def on_moved
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]
    location_id = params[:id]

    if location_id.nil? or location_id.empty?
      location = Location.get_for(login_user)
      if location.nil?
        location = Location.new
        location.user_id = login_user.id
      end
    else
      begin
        location = Location.find(location_id)
      rescue
      end
    end

    unless location.nil?
      group_id = params[:group_id]
      group_id = nil if group_id.empty?
      location.update_attributes({:group_id => group_id, :x => params[:x], :y => params[:y]})
    end

    render(:text => (location.nil?)?'':location.id.to_s)
  end

 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of the specified Location.
  #
  def check_owner
    return if params[:id].nil? or params[:id].empty? or session[:login_user].nil?

    begin
      owner_id = Location.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    login_user = session[:login_user]
    if !login_user.admin?(User::AUTH_LOCATION) and owner_id != login_user.id
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
