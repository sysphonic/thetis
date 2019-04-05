#
#= FoldersController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class FoldersController < ApplicationController
  layout('base')

  if YamlHelper.get_value($thetis_config, 'menu.req_login_items', nil) == '1'
    before_action(:check_login)
  else
    before_action(:check_login, :except => [:show_tree, :show_url, :get_items, :get_tree, :ajax_get_tree])
  end

  #=== show_tree
  #
  #Shows Folder tree.
  #
  def show_tree
    Log.add_info(request, params.inspect)

    if (!@login_user.nil? and @login_user.admin?(User::AUTH_FOLDER))

      @group_id = nil
      if !params[:tree_node_id].nil?
        @group_id = params[:tree_node_id]
      elsif !params[:group_id].blank?
        @group_id = params[:group_id]
      end
      SqlHelper.validate_token([@group_id])

      @folder_tree = Folder.get_tree_by_group_for_admin(@group_id || TreeElement::ROOT_ID.to_s)
    else
      @folder_tree = Folder.get_tree_for(@login_user)
    end
  end

  #=== ajax_get_tree
  #
  #Gets Folder tree by Ajax.
  #
  def ajax_get_tree
    Log.add_info(request, params.inspect)

    admin = false

    @folder_tree = Folder.get_tree_for(@login_user, admin)

    render(:partial => 'ajax_get_tree', :layout => false)
  end

  #=== create
  #
  #Creates Folder.
  #Receives Folder name from ThetisBox.
  #
  def create
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    parent_id = params[:selectedFolderId]

    unless Folder.check_user_auth(parent_id, @login_user, 'w', true)
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_modify')
      render(:partial => 'ajax_folder_entry', :layout => false)
      return
    end

    if params[:thetisBoxEdit].blank?
      @folder = nil
    else
      @folder = Folder.new
      @folder.name = params[:thetisBoxEdit]
      @folder.xorder = Folder.get_order_max(parent_id) + 1
      @folder.parent_id = parent_id
      @folder.inherit_parent_auth
      @folder.save!
    end
    render(:partial => 'ajax_folder_entry', :layout => false)
  end

  #=== rename
  #
  #Renames Folder.
  #Receives Folder name from ThetisBox.
  #
  def rename
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @folder = Folder.find(params[:id])

    unless Folder.check_user_auth(@folder.id, @login_user, 'w', true)
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_modify')
      render(:partial => 'ajax_folder_name', :layout => false)
      return
    end

    unless params[:thetisBoxEdit].blank?
      @folder.name = params[:thetisBoxEdit]
      @folder.save
    end
    render(:partial => 'ajax_folder_name', :layout => false)
  end

  #=== destroy
  #
  #Deletes Folder.
  #
  def destroy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @folder = Folder.find(params[:id])

    unless Folder.check_user_auth(@folder.id, @login_user, 'w', true)
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_modify')
      render(:partial => 'common/flash_notice', :layout => false)
      return
    end

    if @folder.count_items(true) > 0
      flash[:notice] = 'ERROR:' + t('folder.cannot_delete_with_items')
      render(:partial => 'common/flash_notice', :layout => false)
      return
    end

    @folder.force_destroy
    @folder = nil
    render(:plain => '')
  end

  #=== move
  #
  #Moves Folder.
  #Receives target Folder-ID from access-path and destination Folder-ID from ThetisBox.
  #params[:tree_node_id] keeps selected ID of <a>-tag like "tree_node_id-1:<selected-id>". 
  #
  def move
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @folder = Folder.find(params[:id])

    if params[:tree_node_id].blank?
      redirect_to(:action => 'show_tree')
      return
    end

    parent_id = params[:tree_node_id]

    check = true

    unless Folder.check_user_auth(parent_id, @login_user, 'w', true)
      check = false
    end

    unless Folder.check_user_auth(@folder.id, @login_user, 'w', true)
      check = false
    end

    unless check
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_modify')
      redirect_to(:action => 'show_tree')
      return
    end

    # Check if specified parent is not one of subfolders.
    childs = Folder.get_childs(@folder.id, nil, true, true, false)
    if childs.include?(parent_id) or (@folder.id == parent_id.to_i)
      flash[:notice] = 'ERROR:' + t('folder.cannot_be_parent')
      redirect_to(:action => 'show_tree')
      return
    end

    @folder.parent_id = parent_id
    @folder.xorder = Folder.get_order_max(parent_id) + 1
    @folder.save
    redirect_to(:action => 'show_tree')
  end

  #=== get_path
  #
  #Gets path-string of specified Folder.
  #
  def get_path
    Log.add_info(request, params.inspect)

    if params[:tree_node_id].blank?
      @folder_path = '/' + t('paren.unknown')
      render(:partial => 'ajax_folder_path', :layout => false)
      return
    end

    @selected_id = params[:tree_node_id]
    SqlHelper.validate_token([@selected_id])

    @folder_path = Folder.get_path(@selected_id)

    render(:partial => 'ajax_folder_path', :layout => false)
  end

  #=== get_items
  #
  #Gets Items in specified Folder.
  #
  def get_items
    if (params[:action] == 'get_items')
      Log.add_info(request, params.inspect)
    end

    @folder_id = params[:id]
    SqlHelper.validate_token([@folder_id])

    if Folder.check_user_auth(@folder_id, @login_user, 'r', true)
=begin
#      if (!@login_user.nil? and @login_user.admin?(User::AUTH_ITEM))
#        @items = Folder.get_items_admin(@folder_id)
#      else
#        @items = Folder.get_items(@login_user, @folder_id)
#      end
=end

# FEATURE_PAGING_IN_TREE >>>
      @sort_col = params[:sort_col]
      @sort_type = params[:sort_type]

      if (@sort_col.blank? or @sort_type.blank?)
        @sort_col, @sort_type = FoldersHelper.get_sort_params(@folder_id)
      end
      SqlHelper.validate_token([@sort_col, @sort_type], ['.'])

      folder_ids = nil
      add_con = nil

      if @folder_id.nil? and (params[:find_in] != Item::FOLDER_ALL)
        add_con = "(Item.folder_id != 0) and (Folder.disp_ctrl like '%|#{Folder::DISPCTRL_BBS_TOP}|%')"
      else
        case params[:find_in]
          when Item::FOLDER_ALL
            ;
          when Item::FOLDER_CURRENT
            folder_ids = [@folder_id]
          when Item::FOLDER_LOWER
            folder_ids = Folder.get_childs(@folder_id, nil, true, false, false)
            folder_ids.unshift(@folder_id)
          else
            folder_ids = [@folder_id]
        end
        unless folder_ids.nil?
          del_arr = []
          folder_ids.each do |folder_id|
            unless Folder.check_user_auth(folder_id, @login_user, 'r', true)
              del_arr << folder_id
            end
          end
          folder_ids -= del_arr unless del_arr.empty?
        end
      end

      is_admin = ((!@login_user.nil?) and @login_user.admin?(User::AUTH_ITEM))
      sql = ItemsHelper.get_list_sql(@login_user, params[:keyword], folder_ids, @sort_col, @sort_type, 0, is_admin, add_con)
      @item_pages, @items, @total_num = paginate_by_sql(Item, sql, 10)
# FEATURE_PAGING_IN_TREE <<<

    else
      @items = []

      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_read')
    end

    session[:folder_id] = @folder_id

    render(:partial => 'ajax_folder_items', :layout => false)
  end

  #=== get_items_order
  #
  #Gets Items' order in specified Folder.
  #
  def get_items_order
    Log.add_info(request, params.inspect)

    @folder_id = params[:id]
    SqlHelper.validate_token([@folder_id])

    if (@folder_id != TreeElement::ROOT_ID.to_s)
      begin
        @folder = Folder.find(@folder_id)
      rescue => evar
        @folder = nil
        Log.add_error(request, evar)
      end
    end

    if Folder.check_user_auth(@folder_id, @login_user, 'r', true)
      if (!@login_user.nil? and @login_user.admin?(User::AUTH_ITEM))
        @items = Folder.get_items_admin(@folder_id, 'xorder ASC')
      else
        @items = Folder.get_items(@login_user, @folder_id, 'xorder ASC')
      end
    end

    session[:folder_id] = @folder_id

    render(:partial => 'ajax_items_order', :layout => false)
  end

  #=== update_items_order
  #
  #Updates Items' order by Ajax.
  #
  def update_items_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    folder_id = params[:id]

    if Folder.check_user_auth(folder_id, @login_user, 'w', true)

      order_arr = params[:items_order]

      if (!@login_user.nil? and @login_user.admin?(User::AUTH_ITEM))
        items = Folder.get_items_admin(folder_id)
      else
        items = Folder.get_items(@login_user, folder_id)
      end
      items.each do |item|
        item.update_attribute(:xorder, order_arr.index(item.id.to_s) + 1)
      end
    else
      Log.add_error(request, nil, 'No Authority Error')
    end

    render(:plain => '')
  end

  #=== get_folders_order
  #
  #Gets child Folders' order in specified Folder.
  #
  def get_folders_order
    Log.add_info(request, params.inspect)

    @folder_id = params[:id]
    @group_id = params[:group_id]
    SqlHelper.validate_token([@folder_id, @group_id])

    if (@folder_id != TreeElement::ROOT_ID.to_s)
      @folder = Folder.find(@folder_id)
    end

    @folders = Folder.get_childs_for(@login_user, @folder_id, false, nil, true)

    if (@folder_id == TreeElement::ROOT_ID.to_s)
      del_arr = FoldersHelper.get_except_top_for_admin(@folders, @group_id)
      @folders -= del_arr
    end

    session[:folder_id] = @folder_id

    render(:partial => 'ajax_folders_order', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_folders_order', :layout => false)
  end

  #=== update_folders_order
  #
  #Updates folders' order by Ajax.
  #
  def update_folders_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    order_arr = params[:folders_order]

    folders = Folder.get_childs(params[:id], nil, false, true, false)
    # folders must be ordered by xorder ASC.

    folders.sort! {|id_a, id_b|

      idx_a = order_arr.index(id_a)
      idx_b = order_arr.index(id_b)

      if (idx_a.nil? or idx_b.nil?)
        idx_a = folders.index(id_a)
        idx_b = folders.index(id_b)
      end

      idx_a - idx_b
    }

    idx = 1
    folders.each do |folder_id|
      begin
        folder = Folder.find(folder_id)
        folder.update_attribute(:xorder, idx)
        idx += 1
      rescue => evar
        folder = nil
        Log.add_error(request, evar)
      end
    end

    render(:plain => '')
  end

  #=== get_disp_ctrl
  #
  #Gets display control of specified Folder.
  #
  def get_disp_ctrl
    Log.add_info(request, params.inspect)

    folder_id = params[:id]
    SqlHelper.validate_token([folder_id])

    if (folder_id != TreeElement::ROOT_ID.to_s)
      begin
        @folder = Folder.find(folder_id)
      rescue => evar
        @folder = nil
      end
    end

    session[:folder_id] = folder_id

    render(:partial => 'ajax_disp_ctrl', :layout => false)
  end

  #=== set_disp_ctrl
  #
  #Sets display control of specified Folder.
  #
  def set_disp_ctrl
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    folder_id = params[:id]
    SqlHelper.validate_token([folder_id])

    if Folder.check_user_auth(folder_id, @login_user, 'w', true)

      @folder = Folder.find(folder_id)

      disp_ctrls = []
      check_bbs_top = params[:check_bbs_top]
      if (check_bbs_top == '1')
        disp_ctrls << Folder::DISPCTRL_BBS_TOP
      end

      select_sorting = params[:select_sorting]
      unless select_sorting.nil?
        disp_ctrls << Folder::DISPCTRL_DEF_SORT+'='+select_sorting
      end

      if disp_ctrls.empty?
        @folder.update_attribute(:disp_ctrl, nil)
      else
        @folder.update_attribute(:disp_ctrl, ApplicationHelper.a_to_attr(disp_ctrls))
      end

      flash[:notice] = t('msg.update_success')
    else
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_modify')
    end

    render(:partial => 'ajax_disp_ctrl', :layout => false)
  end

  #=== get_auth_users
  #
  #Gets authorities of specified Folder.
  #
  def get_auth_users
    Log.add_info(request, params.inspect)

    folder_id = params[:id]
    SqlHelper.validate_token([folder_id])

    begin
      @folder = Folder.find(folder_id)
    rescue
      @folder = nil
    end

    @users = []

    session[:folder_id] = folder_id

    if !@login_user.nil? and (@login_user.admin?(User::AUTH_FOLDER) or (!@folder.nil? and @folder.in_my_folder_of?(@login_user.id)))
      render(:partial => 'ajax_auth_users', :layout => false)
    else
      render(:partial => 'ajax_auth_disp', :layout => false)
    end
  end

  #=== get_group_users
  #
  #Gets Users in specified Group.
  #
  def get_group_users
    Log.add_info(request, params.inspect)

    SqlHelper.validate_token([params[:id]])
    begin
      @folder = Folder.find(params[:id])
    rescue => evar
      @folder = nil
      Log.add_error(request, evar)
    end

    @group_id = nil
    if !params[:tree_node_id].nil?
      @group_id = params[:tree_node_id]
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    @users = Group.get_users(@group_id)

    render(:partial => 'ajax_select_users', :layout => false)
  end

  #=== set_auth_users
  #
  #Sets authorities of specified Folder.
  #
  def set_auth_users
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @folder = Folder.find(params[:id])

    if Folder.check_user_auth(@folder.id, @login_user, 'w', true)

      read_users = []
      write_users = []
      users_auth = params[:users_auth]
      unless users_auth.nil?
        users_auth.each do |auth_param|
          user_id = auth_param.split(':').first
          auths = auth_param.split(':').last.split('+')
          if auths.include?('r')
            read_users << user_id
          end
          if auths.include?('w')
            write_users << user_id
          end
        end
      end

      user_id = @folder.get_my_folder_owner
      if !user_id.nil? and (!read_users.include?(user_id.to_s) or !write_users.include?(user_id.to_s))
        flash[:notice] = 'ERROR:' + t('folder.my_folder_without_auth_owner')
      else
        @folder.set_read_users(read_users)
        @folder.set_write_users(write_users)

        @folder.save

        flash[:notice] = t('msg.register_success')
      end
    else
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_modify')
    end

    @group_id = params[:group_id]
    SqlHelper.validate_token([@group_id])

    if @group_id.blank?
      @users = []
    else
      @users = Group.get_users(@group_id)
    end
    render(:partial => 'ajax_auth_users', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_auth_users', :layout => false)
  end

  #=== get_auth_groups
  #
  #Gets authorities of specified Folder.
  #
  def get_auth_groups
    Log.add_info(request, params.inspect)

    folder_id = params[:id]
    SqlHelper.validate_token([folder_id])

    begin
      @folder = Folder.find(folder_id)
    rescue
      @folder = nil
    end

    @groups = Group.where(nil).to_a

    session[:folder_id] = folder_id

    render(:partial => 'ajax_auth_groups', :layout => false)
  end

  #=== set_auth_groups
  #
  #Sets authorities of specified Folder.
  #
  def set_auth_groups
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @folder = Folder.find(params[:id])

    if Folder.check_user_auth(@folder.id, @login_user, 'w', true)
      read_groups = []
      write_groups = []
      groups_auth = params[:groups_auth]
      unless groups_auth.nil?
        groups_auth.each do |auth_param|
          user_id = auth_param.split(':').first
          auths = auth_param.split(':').last.split('+')
          if auths.include?('r')
            read_groups << user_id
          end
          if auths.include?('w')
            write_groups << user_id
          end
        end
      end

      @folder.set_read_groups(read_groups)
      @folder.set_write_groups(write_groups)

      @folder.save

      flash[:notice] = t('msg.register_success')
    else
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_modify')
    end

    @groups = Group.where(nil).to_a
    render(:partial => 'ajax_auth_groups', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_auth_groups', :layout => false)
  end

  #=== get_auth_teams
  #
  #Gets authorities of specified Folder.
  #
  def get_auth_teams
    Log.add_info(request, params.inspect)

    folder_id = params[:id]
    SqlHelper.validate_token([folder_id])

    begin
      @folder = Folder.find(folder_id)
    rescue
      @folder = nil
    end

    target_user_id = (@login_user.admin?(User::AUTH_TEAM))?(nil):(@login_user.id)
    @teams = Team.get_for(target_user_id, true)

    session[:folder_id] = folder_id

    render(:partial => 'ajax_auth_teams', :layout => false)
  end

  #=== set_auth_teams
  #
  #Sets authorities of specified Folder.
  #
  def set_auth_teams
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @folder = Folder.find(params[:id])

    if Folder.check_user_auth(@folder.id, @login_user, 'w', true)
      read_teams = []
      write_teams = []
      teams_auth = params[:teams_auth]
      unless teams_auth.nil?
        teams_auth.each do |auth_param|
          user_id = auth_param.split(':').first
          auths = auth_param.split(':').last.split('+')
          if auths.include?('r')
            read_teams << user_id
          end
          if auths.include?('w')
            write_teams << user_id
          end
        end
      end

      @folder.set_read_teams(read_teams)
      @folder.set_write_teams(write_teams)

      @folder.save

      flash[:notice] = t('msg.register_success')
    else
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_modify')
    end

    target_user_id = (@login_user.admin?(User::AUTH_TEAM))?(nil):(@login_user.id)
    @teams = Team.get_for(target_user_id, true)
    render(:partial => 'ajax_auth_teams', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_auth_teams', :layout => false)
  end

  #=== ajax_delete_items
  #
  #Deletes specified Items.
  #
  def ajax_delete_items
    Log.add_info(request, params.inspect)

    unless params[:check_item].blank?
      is_admin = @login_user.admin?(User::AUTH_ITEM)

      count = 0
      params[:check_item].each do |item_id, value|
        next if (value != '1')

        item = nil
        begin
          item = Item.find(item_id)
          next if !is_admin and (item.user_id != @login_user.id)

          item.destroy
        rescue => evar
          Log.add_error(request, evar)
        end
        count += 1
      end
      flash[:notice] = t('item.deleted', :count => count)
    end

    get_items
  end

  #=== ajax_move_items
  #
  #Moves specified Items.
  #
  def ajax_move_items
    Log.add_info(request, params.inspect)

    folder_id = params[:tree_node_id]
    SqlHelper.validate_token([folder_id])

    unless Folder.check_user_auth(folder_id, @login_user, 'w', true)
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_write_in')
      get_items
      return
    end

    unless params[:check_item].blank?
      is_admin = @login_user.admin?(User::AUTH_ITEM)

      count = 0
      params[:check_item].each do |item_id, value|
        next if (value != '1')

        item = nil
        begin
          item = Item.find(item_id)
          next if !is_admin and (item.user_id != @login_user.id)

          item.update_attribute(:folder_id, folder_id)
        rescue => evar
          Log.add_error(request, evar)
        end
        count += 1
      end
      flash[:notice] = t('item.moved', :count => count)
    end

    get_items
  end
end
