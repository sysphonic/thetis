#
#= GroupsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2013 MORITA Shintaro, Sysphonic. All rights reserved.
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
    @group_tree = Group.get_tree(Hash.new, nil, '0')
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

  rescue => evar
    Log.add_error(request, evar)
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
    rescue => evar
      Log.add_error(request, evar)
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

    unless params[:thetisBoxSelKeeper].blank?

      parent_id = params[:thetisBoxSelKeeper].split(':').last

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

  #=== ajax_exclude_users
  #
  #<Ajax>
  #Excludes specified Users.
  #
  def ajax_exclude_users
    Log.add_info(request, params.inspect)

    group_id = params[:id]

    unless params[:check_user].blank?
      count = 0
      params[:check_user].each do |user_id, value|
        if value == '1'

          begin
            user = User.find(user_id)
            user.exclude_from(group_id)
            user.save!
          rescue => evar
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
  #<Ajax>
  #Moves specified Users.
  #
  def ajax_move_users
    Log.add_info(request, params.inspect)

    org_group_id = params[:id]
    group_id = params[:thetisBoxSelKeeper].split(':').last

    unless params[:check_user].blank?

      count = 0
      params[:check_user].each do |user_id, value|
        if value == '1'

          begin
            user = User.find(user_id)
            user.exclude_from(org_group_id)
            user.add_to(group_id)
            user.save!
          rescue => evar
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
  #<Ajax>
  #Gets Users in the specified Group.
  #
  def get_users
    if params[:action] == 'get_users'
      Log.add_info(request, params.inspect)
    end

    @group_id = params[:id]

=begin
#    @users = Group.get_users(params[:id])
=end

# FEATURE_PAGING_IN_TREE >>>
    con = ['User.id > 0']

    unless @group_id.nil?
      if @group_id == '0'
        con << "((groups like '%|0|%') or (groups is null))"
      else
        con << "(groups like '%|#{@group_id}|%')"
      end
    end

    if params[:keyword]
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        key = '%' + key + '%'
        con << "(name like '#{key}' or email like '#{key}' or fullname like '#{key}' or address like '#{key}' or organization like '#{key}' or tel1 like '#{key}' or tel2 like '#{key}' or tel3 like '#{key}' or fax like '#{key}' or url like '#{key}' or postalcode like '#{key}' or title like '#{key}' )"
      end
    end

    where = ''
    unless con.empty?
      where = ' where ' + con.join(' and ')
    end

    order_by = nil
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if @sort_col.nil? or @sort_col.empty? or @sort_type.nil? or @sort_type.empty?
      @sort_col = 'OfficialTitle.xorder'
      @sort_type = 'ASC'
    end

    order_by = @sort_col + ' ' + @sort_type

    if @sort_col == 'OfficialTitle.xorder'
      order_by = '(OfficialTitle.xorder is null) ' + @sort_type + ', ' + order_by
    else
      order_by << ', (OfficialTitle.xorder is null) ASC, OfficialTitle.xorder ASC'
    end
    if @sort_col != 'name'
      order_by << ', name ASC'
    end

    sql = 'select distinct User.* from (users User left join user_titles UserTitle on User.id=UserTitle.user_id)'
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
  #<Ajax>
  #Gets child Groups' order in specified Group.
  #
  def get_groups_order
    Log.add_info(request, params.inspect)

    @group_id = params[:id]

    if @group_id != '0'
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
  #<Ajax>
  #Updates groups' order by Ajax.
  #
  def update_groups_order
    Log.add_info(request, params.inspect)

    order_ary = params[:groups_order]

    groups = Group.get_childs(params[:id], false, false)
    # groups must be ordered by xorder ASC.

    groups.sort! { |id_a, id_b|

      idx_a = order_ary.index(id_a)
      idx_b = order_ary.index(id_b)

      if idx_a.nil? or idx_b.nil?
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
        Log.add_error(request, evar)
      end
    end

    render(:text => '')
  end

  #=== get_official_titles
  #
  #<Ajax>
  #Gets OfficialTitles which belong to the specified Group.
  #
  def get_official_titles
    Log.add_info(request, params.inspect)

    @group_id = (params[:id] || '0')  # '0' for ROOT

    session[:group_id] = params[:id]
    session[:group_option] = 'official_title'

    render(:partial => 'ajax_official_titles', :layout => false)
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
