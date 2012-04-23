#
#= FoldersController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about templates of Items.
#
#== Note:
#
#* 
#
class TemplatesController < ApplicationController
  layout 'base'

  before_filter :check_login
  before_filter :except => [:copy, :ajax_get_tree] do |controller|
    controller.check_auth(User::AUTH_TEMPLATE)
  end


  #=== list
  #
  #Shows list of templates of Items.
  #
  def list
    Log.add_info(request, params.inspect)

    ary = TemplatesHelper.get_tmpl_folder

    unless ary.nil? or ary.empty?
      @tmpl_folder = ary[0]
      @tmpl_system_folder = ary[1]
      @tmpl_workflows_folder = ary[2]
      @tmpl_local_folder = ary[3]
      @tmpl_q_folder = ary[4]
    end
  end

  #=== create_workflow
  #
  #<Ajax>
  #Creates a template in 'Workflows' Folder with default name.
  #
  def create_workflow
    Log.add_info(request, params.inspect)

    @tmpl_folder, @tmpl_workflows_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_WORKFLOWS)

    @group_id = params[:group_id]

    if @group_id.nil? or @group_id.empty?
      @group_id = '0'   # '0' for ROOT
    elsif @group_id == '0'
      ;
    else
      group = nil
      begin
        group = Group.find(@group_id)
      rescue
      end
      if group.nil?
        render(:text => 'ERROR:' + t('msg.already_deleted', :name => Group.model_name.human))
        return
      end
    end

    unless @tmpl_workflows_folder.nil?
      item = Item.new_workflow(@tmpl_workflows_folder.id)
      item.title = t('workflow.new')
      item.user_id = 0
      item.save!

      workflow = Workflow.new
      workflow.item_id = item.id
      workflow.user_id = 0
      workflow.status = Workflow::STATUS_NOT_APPLIED
      if @group_id == '0'
        workflow.groups = nil
      else
        workflow.groups = '|' + @group_id + '|'
      end
      workflow.save!
    else
      Log.add_error(request, nil, '/'+TemplatesHelper::TMPL_ROOT+'/'+TemplatesHelper::TMPL_WORKFLOWS+' NOT found!')
    end

    render(:partial => 'groups/ajax_group_workflows', :layout => false)
  end

  #=== destroy_workflow
  #
  #<Ajax>
  #Destroys specified Workflow.
  #
  def destroy_workflow
    Log.add_info(request, params.inspect)

    Item.find(params[:id]).destroy

    @tmpl_folder, @tmpl_workflows_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_WORKFLOWS)

    @group_id = params[:group_id]

    if @group_id.nil? or @group_id.empty?
      @group_id = '0'   # '0' for ROOT
    end

    render(:partial => 'groups/ajax_group_workflows', :layout => false)
  end

  #=== create_local
  #
  #<Ajax>
  #Creates a template in 'Local' Folder with default name.
  #
  def create_local
    Log.add_info(request, params.inspect)

    @tmpl_folder, @tmpl_local_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_LOCAL)

    unless @tmpl_local_folder.nil?
      item = Item.new_info(@tmpl_local_folder.id)
      item.title = t('template.new')
      item.user_id = 0
      item.save!
    else
      Log.add_error(request, nil, '/'+TemplatesHelper::TMPL_ROOT+'/'+TemplatesHelper::TMPL_LOCAL+' NOT found!')
    end

    render(:partial => 'ajax_local', :layout => false)
  end

  #=== destroy_local
  #
  #<Ajax>
  #Destroys specified local template.
  #
  def destroy_local
    Log.add_info(request, params.inspect)

    begin
      Item.find(params[:id]).destroy
    rescue
    end

    # Get $Templates and its sub folders to update partial division.
    @tmpl_folder, @tmpl_local_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_LOCAL)

    render(:partial => 'ajax_local', :layout => false)
  end

  #=== copy
  #
  #Copies Template.
  #
  def copy
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    tmpl_id = params[:thetisBoxSelKeeper].split(':').last
    tmpl_item = Item.find(tmpl_id)

    item = tmpl_item.copy(login_user.id, login_user.get_my_folder.id)
    if item.public != false
      item.update_attribute(:public, false)
    end

    redirect_to(:controller => 'items', :action => 'edit', :id => item.id)

  rescue StandardError => err
    Log.add_error(request, err)

    redirect_to(:controller => 'items', :action => 'new')
  end

  #=== ajax_get_tree
  #
  #<Ajax>
  #Gets Template tree by Ajax.
  #
  def ajax_get_tree
    Log.add_info(request, params.inspect)

    @tmpl_folder, @tmpl_local_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_LOCAL)

    tmpl_items = Folder.get_items_admin(@tmpl_local_folder.id, 'xorder ASC')
    
    @tmpl_tree = PseudoHash.new
    
    unless tmpl_items.nil?
      tmpl_items.each do |item|
        @tmpl_tree[item.id.to_s, true] = []
      end
    end

    render(:partial => 'ajax_template_tree', :layout => false)
  end
end
