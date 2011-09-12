#
#= GroupsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Groups.
#
#== Note:
#
#* 
#
class GroupsController < ApplicationController
  layout 'base'

  before_filter :check_login
  before_filter :except => [:get_tree, :ajax_get_tree, :get_path, :get_workflows, :get_map] do |controller|
    controller.check_auth(User::AUTH_GROUP)
  end
  before_filter :only => [:get_workflows] do |controller|
    controller.check_auth(User::AUTH_WORKFLOW)
  end
  before_filter :only => [:get_map] do |controller|
    controller.check_auth(User::AUTH_LOCATION)
  end


  #=== show_tree
  #
  #Shows Group tree.
  #
  def show_tree
    Log.add_info(request, params.inspect)

    get_tree
  end

  #=== get_tree
  #
  #Gets Group tree.
  #
  def get_tree
    Log.add_info(request, params.inspect)
    
    # '0' for ROOT
    @group_tree = Group.get_tree(PseudoHash.new, nil, '0')
  end

  #=== ajax_get_tree
  #
  #<Ajax>
  #Gets Group tree by Ajax.
  #
  def ajax_get_tree
    Log.add_info(request, params.inspect)

    get_tree
    render(:partial => 'ajax_group_tree', :layout => false)
  end

  #=== create
  #
  #<Ajax>
  #Creates Group.
  #Receives Group name from ThetisBox.
  #
  def create
     Log.add_info(request, params.inspect)

    if params[:thetisBoxEdit].nil? or params[:thetisBoxEdit].empty?
      @group = nil
    else
      @group = Group.new
      @group.name = params[:thetisBoxEdit]
      @group.parent_id = params[:selectedGroupId]
      @group.save!

      @group.create_group_folder
    end
    render(:partial => 'ajax_group_entry', :layout => false)
  end

  #=== rename
  #
  #<Ajax>
  #Renames Group.
  #Receives Group name from ThetisBox.
  #
  def rename
    Log.add_info(request, params.inspect)

    @group = Group.find(params[:id])
    unless params[:thetisBoxEdit].nil? or params[:thetisBoxEdit].empty?
      @group.rename params[:thetisBoxEdit]
    end
    render(:partial => 'ajax_group_name', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)
    render(:partial => 'ajax_group_name', :layout => false)
  end

  #=== destroy
  #
  #<Ajax>
  #Deletes Group.
  #
  def destroy
    Log.add_info(request, params.inspect)

    begin
      Group.destroy(params[:id])
    rescue StandardError => err
      Log.add_error(request, err)
    end
    render(:text => '')
  end

  #=== move
  #
  #Moves Group.
  #Receives target Group-ID from access-path and destination Group-ID from ThetisBox.
  #params[:thetisBoxSelKeeper] keeps selected id of <a>-tag like "thetisBoxSelKeeper-1:<selected-id>". 
  #
  def move
    Log.add_info(request, params.inspect)

    @group = Group.find(params[:id])

    unless params[:thetisBoxSelKeeper].nil? or params[:thetisBoxSelKeeper].empty?

      parent_id = params[:thetisBoxSelKeeper].split(':').last

      childs = @group.get_childs(true, false)
      if childs.include?(parent_id) or @group.id.to_s == parent_id
        flash[:notice] = 'ERROR:' + t('group.cannot_be_parent')
        redirect_to(:action => 'show_tree')
        return
      end
    
      @group.parent_id = parent_id
      @group.save
    end
    redirect_to(:action => 'show_tree')

  rescue StandardError => err
    Log.add_error(request, err)
    redirect_to(:action => 'show_tree')
  end

  #=== get_path
  #
  #<Ajax>
  #Gets path-string of group specified by id in access-path.
  #
  def get_path
    Log.add_info(request, params.inspect)

    if params[:thetisBoxSelKeeper].nil? or params[:thetisBoxSelKeeper].empty?
      @group_path = '/' + t('paren.unknown')
      render(:partial => 'ajax_group_path', :layout => false)
      return
    end

    @selected_id = params[:thetisBoxSelKeeper].split(':').last

    @group_path = Group.get_path(@selected_id)

    render(:partial => 'ajax_group_path', :layout => false)
  end

  #=== get_users
  #
  #<Ajax>
  #Gets Users in the specified Group.
  #
  def get_users
    Log.add_info(request, params.inspect)

    @users = Group.get_users(params[:id])

    session[:group_id] = params[:id]
    session[:group_option] = 'user'

    render(:partial => 'ajax_group_users', :layout => false)
  end

  #=== get_workflows
  #
  #<Ajax>
  #Gets Workflows which belong to the specified Group.
  #
  def get_workflows
    Log.add_info(request, params.inspect)

    @group_id = (params[:id] || '0')  # '0' for ROOT

    ary = TemplatesHelper.get_tmpl_folder

    unless ary.nil? or ary.empty?
      @tmpl_workflows_folder = ary[2]
    end

    session[:group_id] = params[:id]
    session[:group_option] = 'workflow'

    render(:partial => 'ajax_workflows', :layout => false)
  end

  #=== get_map
  #
  #<Ajax>
  #Gets OfficeMap related to the specified Group.
  #
  def get_map
    Log.add_info(request, params.inspect)

    @group_id = (params[:id] || '0')  # '0' for ROOT

    @office_map = OfficeMap.get_for_group(@group_id)

    session[:group_id] = params[:id]
    session[:group_option] = 'office_map'

    render(:partial => 'ajax_map', :layout => false)
  end
end
