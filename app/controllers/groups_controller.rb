#
#= GroupsController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class GroupsController < ApplicationController
  layout('base')

  before_action(:check_login)
  before_action :except => [:get_tree, :ajax_get_tree, :get_workflows, :get_map] do |controller|
    controller.check_auth(User::AUTH_GROUP)
  end
  before_action :only => [:get_workflows] do |controller|
    controller.check_auth(User::AUTH_WORKFLOW)
  end
  before_action :only => [:get_map] do |controller|
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

    @group_tree = Group.get_tree(Hash.new, nil, TreeElement::ROOT_ID.to_s)
  end

  #=== ajax_get_tree
  #
  #Gets Group tree by Ajax.
  #
  def ajax_get_tree
    Log.add_info(request, params.inspect)

    get_tree
    render(:partial => 'ajax_group_tree', :layout => false)
  end

  #=== create
  #
  #Creates Group.
  #Receives Group name from ThetisBox.
  #
  def create
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:thetisBoxEdit].blank?
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
  #Renames Group.
  #Receives Group name from ThetisBox.
  #
  def rename
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @group = Group.find(params[:id])
    unless params[:thetisBoxEdit].blank?
      @group.rename(params[:thetisBoxEdit])
    end
    render(:partial => 'ajax_group_name', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_group_name', :layout => false)
  end

  #=== destroy
  #
  #Deletes Group.
  #
  def destroy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    SqlHelper.validate_token([params[:id]])
    begin
      Group.destroy(params[:id])
    rescue => evar
      Log.add_error(request, evar)
    end
    render(:plain => '')
  end

  #=== move
  #
  #Moves Group.
  #Receives target Group-ID from access-path and destination Group-ID from ThetisBox.
  #params[:tree_node_id] keeps selected id of <a>-tag like "tree_node_id-1:<selected-id>". 
  #
  def move
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @group = Group.find(params[:id])

    unless params[:tree_node_id].blank?

      parent_id = params[:tree_node_id]

      childs = @group.get_childs(true, false)
      if childs.include?(parent_id) or (@group.id == parent_id.to_i)
        flash[:notice] = 'ERROR:' + t('group.cannot_be_parent')
        redirect_to(:action => 'show_tree')
        return
      end

      @group.parent_id = parent_id
      @group.xorder = nil
      @group.save
    end
    redirect_to(:action => 'show_tree')

  rescue => evar
    Log.add_error(request, evar)
    redirect_to(:action => 'show_tree')
  end

  #=== ajax_exclude_users
  #
  #Excludes specified Users.
  #
  def ajax_exclude_users
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    group_id = params[:id]
    SqlHelper.validate_token([group_id])

    unless params[:check_user].blank?
      count = 0
      params[:check_user].each do |user_id, value|
        if (value == '1')

          begin
            user = User.find(user_id)
            user.exclude_from(group_id)
            user.save!
          rescue => evar
            user = nil
            Log.add_error(request, evar)
          end

          count += 1
        end
      end
      flash[:notice] = t('msg.update_success')
    end

    get_users
  end

  #=== ajax_move_users
  #
  #Moves specified Users.
  #
  def ajax_move_users
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    org_group_id = params[:id]
    group_id = params[:tree_node_id]
    SqlHelper.validate_token([org_group_id, group_id])

    unless params[:check_user].blank?

      count = 0
      params[:check_user].each do |user_id, value|
        if (value == '1')

          begin
            user = User.find(user_id)
            user.exclude_from(org_group_id)
            user.add_to(group_id)
            user.save!
          rescue => evar
            user = nil
            Log.add_error(request, evar)
          end

          count += 1
        end
      end
      flash[:notice] = t('msg.move_success')
    end

    get_users
  end

  #=== get_users
  #
  #Gets Users in the specified Group.
  #
  def get_users
    if (params[:action] == 'get_users')
      Log.add_info(request, params.inspect)
    end

    @group_id = params[:id]
    SqlHelper.validate_token([@group_id])

=begin
#    @users = Group.get_users(params[:id])
=end

# FEATURE_PAGING_IN_TREE >>>
    con = ['User.id > 0']

    unless @group_id.nil?
      if (@group_id == TreeElement::ROOT_ID.to_s)
        con << "((groups like '%|#{@group_id}|%') or (groups is null))"
      else
        con << SqlHelper.get_sql_like([:groups], "|#{@group_id}|")
      end
    end

    unless params[:keyword].blank?
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        con << SqlHelper.get_sql_like([:name, :email, :fullname, :address, :organization, :tel1, :tel2, :tel3, :fax, :url, :postalcode, :title], key)
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
      @sort_col = 'OfficialTitle.xorder'
      @sort_type = 'ASC'
    end

    SqlHelper.validate_token([@sort_col, @sort_type], ['.'])
    order_by = @sort_col + ' ' + @sort_type

    if (@sort_col == 'OfficialTitle.xorder')
      order_by = '(OfficialTitle.xorder is null) ' + @sort_type + ', ' + order_by
    else
      order_by << ', (OfficialTitle.xorder is null) ASC, OfficialTitle.xorder ASC'
    end
    if (@sort_col != 'name')
      order_by << ', name ASC'
    end

    sql = 'select User.* from (users User left join user_titles UserTitle on User.id=UserTitle.user_id)'
    sql << ' left join official_titles OfficialTitle on UserTitle.official_title_id=OfficialTitle.id'

    sql << where + ' order by ' + order_by

    @user_pages, @users, @total_num = paginate_by_sql(User, sql, 50)
# FEATURE_PAGING_IN_TREE <<<

    session[:group_id] = @group_id
    session[:group_option] = 'user'

    render(:partial => 'ajax_group_users', :layout => false)
  end

  #=== get_groups_order
  #
  #Gets child Groups' order in specified Group.
  #
  def get_groups_order
    Log.add_info(request, params.inspect)

    @group_id = params[:id]
    SqlHelper.validate_token([@group_id])

    if (@group_id != TreeElement::ROOT_ID.to_s)
      @group = Group.find(@group_id)
    end

    @groups = Group.get_childs(@group_id, false, true)

    session[:group_id] = @group_id
    session[:group_option] = 'groups_order'

    render(:partial => 'ajax_groups_order', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_groups_order', :layout => false)
  end

  #=== update_groups_order
  #
  #Updates groups' order by Ajax.
  #
  def update_groups_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    order_arr = params[:groups_order]

    groups = Group.get_childs(params[:id], false, false)
    # groups must be ordered by xorder ASC.

    groups.sort! { |id_a, id_b|

      idx_a = order_arr.index(id_a)
      idx_b = order_arr.index(id_b)

      if (idx_a.nil? or idx_b.nil?)
        idx_a = groups.index(id_a)
        idx_b = groups.index(id_b)
      end

      idx_a - idx_b
    }

    idx = 1
    groups.each do |group_id|
      begin
        group = Group.find(group_id)
        group.update_attribute(:xorder, idx)
        idx += 1
      rescue => evar
        group = nil
        Log.add_error(request, evar)
      end
    end

    render(:plain => '')
  end

  #=== get_official_titles
  #
  #Gets OfficialTitles which belong to the specified Group.
  #
  def get_official_titles
    Log.add_info(request, params.inspect)

    @group_id = (params[:id] || TreeElement::ROOT_ID.to_s)
    SqlHelper.validate_token([@group_id])

    session[:group_id] = params[:id]
    session[:group_option] = 'official_title'

    render(:partial => 'ajax_official_titles', :layout => false)
  end

  #=== get_workflows
  #
  #Gets Workflows which belong to the specified Group.
  #
  def get_workflows
    Log.add_info(request, params.inspect)

    @group_id = (params[:id] || TreeElement::ROOT_ID.to_s)
    SqlHelper.validate_token([@group_id])

    arr = TemplatesHelper.get_tmpl_folder

    unless arr.nil? or arr.empty?
      @tmpl_workflows_folder = arr[2]
    end

    session[:group_id] = params[:id]
    session[:group_option] = 'workflow'

    render(:partial => 'ajax_workflows', :layout => false)
  end

  #=== get_map
  #
  #Gets OfficeMap related to the specified Group.
  #
  def get_map
    Log.add_info(request, params.inspect)

    @group_id = (params[:id] || TreeElement::ROOT_ID.to_s)
    SqlHelper.validate_token([@group_id])

    @office_map = OfficeMap.get_for_group(@group_id)

    session[:group_id] = params[:id]
    session[:group_option] = 'office_map'

    render(:partial => 'ajax_map', :layout => false)
  end
end
