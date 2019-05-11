#
#= WorkflowsController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class WorkflowsController < ApplicationController
  layout('base')

  before_action(:check_login)
  before_action(:check_owner, :only => [:move, :destroy])

  #=== list
  #
  #Shows list of Workflows.
  #
  def list
    Log.add_info(request, params.inspect)

    @tmpl_folder, @tmpl_workflows_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_WORKFLOWS)

    my_wf_folder = WorkflowsHelper.get_my_wf_folder(@login_user.id)

    sql = WorkflowsHelper.get_list_sql(@login_user.id, my_wf_folder.id)
    @workflows = Workflow.find_by_sql(sql)

    @received_wfs = Workflow.get_received_list(@login_user.id, 'id DESC')

  rescue => evar
    Log.add_error(request, evar)
  end

  #=== create
  #
  #Creates a Workflow Item in 'My Folder/$Workflows'.
  #
  def create
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    my_wf_folder = WorkflowsHelper.get_my_wf_folder(@login_user.id)

    tmpl_item = Item.find(params[:select_workflow])

    item = tmpl_item.copy(@login_user.id, my_wf_folder.id)

    attrs = ActionController::Parameters.new({title: tmpl_item.title + t('msg.colon') + User.get_name(@login_user.id), public: false})
    item.update_attributes(Item.permit_base(attrs))

    item.workflow.update_attribute(:status, Workflow::STATUS_NOT_ISSUED)

    sql = WorkflowsHelper.get_list_sql(@login_user.id, my_wf_folder.id)
    @workflows = Workflow.find_by_sql(sql)

    render(:partial => 'ajax_workflow', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_workflow', :layout => false)
  end

  #=== destroy
  #
  #Destroys specified local template.
  #
  def destroy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    workflow = Workflow.find(params[:id])

    begin
      workflow.item.destroy
    rescue => evar
      Log.add_error(nil, evar)
    end

    my_wf_folder = WorkflowsHelper.get_my_wf_folder(@login_user.id)

    sql = WorkflowsHelper.get_list_sql(@login_user.id, my_wf_folder.id)
    @workflows = Workflow.find_by_sql(sql)

    render(:partial => 'ajax_workflow', :layout => false)
  end

  #=== move
  #
  #Moves Workflow to the specified Folder.
  #
  def move
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    unless params[:tree_node_id].nil?
      folder_id = params[:tree_node_id]
      SqlHelper.validate_token([folder_id])

      workflow = Workflow.find(params[:id])

      workflow.item.update_attribute(:folder_id, folder_id)

      flash[:notice] = t('msg.move_success')
    end

    my_wf_folder = WorkflowsHelper.get_my_wf_folder(@login_user.id)

    sql = WorkflowsHelper.get_list_sql(@login_user.id, my_wf_folder.id)
    @workflows = Workflow.find_by_sql(sql)

    render(:partial => 'ajax_workflow', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    flash[:notice] = 'ERROR:' + evar.to_s[0, 64]
    render(:partial => 'ajax_workflow', :layout => false)
  end

 private
  #=== check_owner
  #
  #Filter method to check if the current User is owner of the specified Workflow.
  #
  def check_owner
    return if (params[:id].blank? or @login_user.nil?)

    begin
      owner_id = Workflow.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    if !@login_user.admin?(User::AUTH_WORKFLOW) and owner_id != @login_user.id
      Log.add_check(request, '[check_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
