#
#= Folder
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Folder contains Items and sub Folders.
#Each Folder can be specified read/write authorities to Users/Groups/Teams.
#
#== Note:
#
#* Root Folder has no records in DB, and its ID is '0'.
#* Folder names which start with '$' are reserved by the system, and also cannot include character '/'.
#
class Folder < ApplicationRecord

  extend CachedRecord
  include TreeElement

  public::DISPCTRL_BBS_TOP = 'bbs_top'
  public::DISPCTRL_DEF_SORT = 'def_sort'

  public::XTYPE_USER = 'user'
  public::XTYPE_GROUP = 'group'
  public::XTYPE_TEAM = 'team'
  public::XTYPE_SYSTEM = 'system'

  #=== get_icons
  #
  #Get icons by types of the Folder.
  #
  #return:: Array of the path of icons ([normal, open, close]).
  #
  def get_icons
    return Folder.get_icons(self.xtype, self.locked?, self.bbs_top?)
  end

  #=== self.get_icons
  #
  #Get icons related with the specified xtype.
  #
  #_xtype_:: Target xtype.
  #_locked_:: If the Folder is specified any authorities.
  #_bbs_top_:: If the Folder is set to be shown in BBS Top.
  #return:: Array of the path of icons ([normal, open, close]).
  #
  def self.get_icons(xtype, locked, bbs_top)

    img_root = THETIS_RELATIVE_URL_ROOT + '/images/'

    if bbs_top
      if locked
        normal = img_root + 'folder/bbs_lock_folder.png'
        open = img_root + 'folder/bbs_lock_folder_open.png'
        close = img_root + 'folder/bbs_lock_folder_close.png'
      else
        normal = img_root + 'folder/bbs_folder.png'
        open = img_root + 'folder/bbs_folder_open.png'
        close = img_root + 'folder/bbs_folder_close.png'
      end
    else
      case xtype
        when Folder::XTYPE_USER
          normal = img_root + 'folder/my_folder.png'
          open = img_root + 'folder/my_folder_open.png'
          close = img_root + 'folder/my_folder_close.png'
        when Folder::XTYPE_GROUP
          normal = img_root + 'folder/group_folder.png'
          open = img_root + 'folder/group_folder_open.png'
          close = img_root + 'folder/group_folder_close.png'
        when Folder::XTYPE_TEAM
          normal = img_root + 'folder/team_folder.png'
          open = img_root + 'folder/team_folder_open.png'
          close = img_root + 'folder/team_folder_close.png'
        when Folder::XTYPE_SYSTEM
          normal = img_root + 'folder/system_folder.png'
          open = img_root + 'folder/system_folder_open.png'
          close = img_root + 'folder/system_folder_close.png'
        else
          if locked
            normal = img_root + 'folder/lock_folder.png'
            open = img_root + 'folder/lock_folder_open.png'
            close = img_root + 'folder/lock_folder_close.png'
          else
            normal = img_root + 'folder/folder.png'
            open = img_root + 'folder/tree_folder_open.png'
            close = img_root + 'folder/tree_folder_close.png'
          end
      end
    end
    return [normal, open, close]
  end

  #=== self.sort_tree
  #
  #Sorts Folder tree.
  #
  #_folder_tree_:: Folder tree.
  #return:: Folder tree.
  #
  def self.sort_tree(folder_tree)

    return folder_tree if folder_tree.nil? or folder_tree.empty?

    folder_tree[TreeElement::ROOT_ID.to_s].sort! { |folder_a, folder_b|

      if (folder_a.xtype == folder_b.xtype)

        if folder_a.xorder.nil? or folder_b.xorder.nil?
          idx_a = folder_a.id
          idx_b = folder_b.id
        else
          idx_a = folder_a.xorder
          idx_b = folder_b.xorder
        end
      else
        case folder_a.xtype
          when Folder::XTYPE_USER;    idx_a = 1;
          when Folder::XTYPE_GROUP;   idx_a = 2;
          when Folder::XTYPE_TEAM;    idx_a = 3;
          when Folder::XTYPE_SYSTEM;  idx_a = 5;
          else;                       idx_a = 4;
        end
        case folder_b.xtype
          when Folder::XTYPE_USER;    idx_b = 1;
          when Folder::XTYPE_GROUP;   idx_b = 2;
          when Folder::XTYPE_TEAM;    idx_b = 3;
          when Folder::XTYPE_SYSTEM;  idx_b = 5;
          else;                       idx_b = 4;
        end
      end

      idx_a - idx_b
    }

    return folder_tree
  end

  #=== self.get_condtions_for
  #
  #Gets conditions parameter for specified User.
  #
  #_user_:: Target User.
  #_admin_:: Specify administrative authority if necessary.
  #return:: Conditions.
  #
  def self.get_condtions_for(user, admin=nil)
    if user.nil?

      admin = false if admin.nil?

    else

      admin = user.admin?(User::AUTH_FOLDER) if admin.nil?

      unless admin
        where_users = SqlHelper.get_sql_like([:read_users, :write_users], "|#{user.id}|")

        arr = []
        group_obj_cache = {}
        groups = user.get_groups_a(true, group_obj_cache)
        groups.each do |group_id|
          arr << SqlHelper.get_sql_like([:read_groups, :write_groups], "|#{group_id}|")
        end
        where_groups = arr.join(' or ')

        arr = []
        teams = user.get_teams_a
        teams.each do |team_id|
          arr << SqlHelper.get_sql_like([:read_teams, :write_teams], "|#{team_id}|")
        end
        where_teams = arr.join(' or ')

        arr = []
        arr << '('+where_users+')' unless where_users.empty?
        arr << '('+where_groups+')' unless where_groups.empty?
        arr << '('+where_teams+')' unless where_teams.empty?
        restrict = arr.join(' or ')
      end
    end

    if admin
      con = nil
    else
      arr = []
      unless restrict.nil? or restrict.empty?
        arr << '('+restrict+')'
      end
      arr << '((read_users is null) and (read_groups is null) and (read_teams is null))'
      arr << '((write_users is null) and (write_groups is null) and (write_teams is null))'
      con = '(' + arr.join(' or ') + ')'
    end

    return con
  end

  #=== self.get_tree_for
  #
  #Gets Folder tree for specified User.
  #
  #_user_:: Target User.
  #_admin_:: Specify administrative authority if necessary.
  #return:: Folder tree.
  #
  def self.get_tree_for(user, admin=nil)

    if admin.nil?
      if user.nil?
        admin = false
      else
        admin = user.admin?(User::AUTH_FOLDER)
      end
    end

    con = Folder.get_condtions_for(user, admin)

    folder_tree = Folder.get_tree(Hash.new, con, TreeElement::ROOT_ID.to_s, admin)
    return Folder.sort_tree(folder_tree)
  end

  #=== self.get_tree_by_group_for_admin
  #
  #Gets Folder tree by Group-ID for administrators.
  #
  #_group_id_:: Target Group-ID.
  #return:: Folder tree.
  #
  def self.get_tree_by_group_for_admin(group_id)

    SqlHelper.validate_token([group_id])

    folder_tree = {}
    tree_id = TreeElement::ROOT_ID.to_s

    if (group_id.to_s == TreeElement::ROOT_ID.to_s)
      sql = 'select distinct * from folders'

      where = " where (parent_id=#{tree_id.to_i})"
      where << " and ((xtype is null) or not((xtype='#{XTYPE_GROUP}') or (xtype='#{XTYPE_USER}')))"

      order_by = ' order by xorder ASC, id ASC'
    else
      sql = 'select distinct Folder.* from folders Folder, users User'

      where = " where (Folder.parent_id=#{tree_id.to_i})"
      where << ' and ('
      where <<      "((Folder.xtype='#{XTYPE_GROUP}') and (Folder.owner_id=#{group_id.to_i}))"
      where <<      ' or '
      where <<      "((Folder.xtype='#{XTYPE_USER}') and (Folder.owner_id=User.id) and #{SqlHelper.get_sql_like(['User.groups'], "|#{group_id}|")})"
      where <<     ' )'

      order_by = ' order by Folder.xorder ASC, Folder.id ASC'
    end

    sql << where + order_by

    folder_tree[tree_id] = Folder.find_by_sql(sql)

    folder_tree[tree_id].each do |folder|
      folder_tree = Folder.get_tree(folder_tree, nil, folder, true)
    end

    return Folder.sort_tree(folder_tree)
  end

  #=== self.get_tree
  #
  #Gets Folder tree.
  #Called recursive.
  #
  #_folder_tree_:: Folder tree.
  #_conditions_:: Conditions.
  #_tree_id_:: Tree-ID.
  #_admin_:: Administrator flag.
  #return:: Folder tree.
  #
  def self.get_tree(folder_tree, conditions, parent, admin)

    if parent.instance_of?(Folder)
      tree_id = parent.id.to_s
    else
      tree_id = parent.to_s
      parent = nil
      if (tree_id != TreeElement::ROOT_ID.to_s)
        begin
          parent = Folder.find(tree_id)
        rescue
        end
        return folder_tree if parent.nil?
      end
    end

    group_obj_cache = {}
    folder_tree[tree_id] = []
    if !parent.nil? and (parent.xtype == Folder::XTYPE_GROUP)
      Group.get_childs(parent.owner_id, false, true).each do |group|
        group_obj_cache[group.id] = group
        con = Marshal.load(Marshal.dump(conditions)) unless conditions.nil?
        if con.nil?
          con = ''
        else
          con << ' and '
        end
        con << "(xtype='#{Folder::XTYPE_GROUP}') and (owner_id=#{group.id})"
        begin
          group_folder = Folder.where(con).first
        rescue => evar
          Log.add_error(nil, evar)
        end
        unless group_folder.nil?
          folder_tree[tree_id] << group_folder
        end
      end
    end

    con = Marshal.load(Marshal.dump(conditions)) unless conditions.nil?
    if con.nil?
      con = ''
    else
      con << ' and '
    end
    con << "parent_id=#{tree_id.to_i}"
    folder_tree[tree_id] += Folder.where(con).order('xorder ASC, id ASC').to_a

    delete_arr = []

    folder_tree[tree_id].each do |folder|

      if !admin and (folder.xtype == Folder::XTYPE_SYSTEM)
        delete_arr << folder
        next
      end

      if (tree_id == TreeElement::ROOT_ID.to_s) and (folder.xtype == Folder::XTYPE_GROUP)
        group = Group.find_with_cache(folder.owner_id, group_obj_cache)
        unless group.nil?
          if (group.parent_id != TreeElement::ROOT_ID)
            delete_arr << folder
            next
          end
        end
      end

      folder_tree = Folder.get_tree(folder_tree, conditions, folder, admin)
    end

    folder_tree[tree_id] -= delete_arr

    return folder_tree
   end

  #=== self.delete_tree
  #
  #Deletes nodes in the Folder tree.
  #Called recursive.
  #
  #_folder_tree_:: Folder tree.
  #_parent_id_:: Parent Folder-ID.
  #_delete_arr_:: Array of Folders to remove.
  #return:: Folder tree.
  #
  def self.delete_tree(folder_tree, parent_id, delete_arr)

    return folder_tree if delete_arr.nil? or delete_arr.empty?

    delete_arr.each do |folder|
      folder_tree = Folder.delete_tree(folder_tree, folder.id, folder_tree[folder.id.to_s])
      folder_tree.delete folder.id.to_s
    end

    folder_tree[parent_id.to_s] -= delete_arr

    return folder_tree
  end

  #=== self.get_order_max
  #
  #Gets the maximum order value of the specified (parent) Folder.
  #
  #_parent_id_:: Parent Folder-ID.
  #return:: Current maximum order.
  #
  def self.get_order_max(parent_id)

    SqlHelper.validate_token([parent_id])

    begin
      max_order = Folder.count_by_sql("SELECT MAX(xorder) FROM folders where parent_id=#{parent_id}")
    rescue => evar
      Log.add_error(nil, evar)
    end

    max_order = 0 if max_order.nil?

    return max_order
  end

  #=== self.get_name
  #
  #Gets the name of the specified Folder.
  #
  #_folder_id_:: Folder-ID.
  #return:: Folder name. If not found, prearranged string.
  #
  def self.get_name(folder_id)

    return '(root)' if (folder_id.to_s == TreeElement::ROOT_ID.to_s)

    begin
      folder = Folder.find(folder_id)
    rescue => evar
      Log.add_error(nil, evar)
    end
    if folder.nil?
      return folder_id.to_s + ' '+ I18n.t('paren.deleted')
    else
      return folder.name
    end
  end

  #=== self.get_path
  #
  #Gets path-string which represents location of specified Folder.
  #
  #_folder_id_:: Folder-ID.
  #_folders_cache_:: Hash to accelerate response. {folder.id, path}
  #_folder_obj_cache_:: Hash to accelerate response. {folder.id, folder}
  #return:: Folder path like "/parent_name1/parent_name2/this_name".
  #
  def self.get_path(folder_id, folders_cache=nil, folder_obj_cache=nil)

    unless folders_cache.nil?
      path = folders_cache[folder_id.to_i]
      if path.nil?
        id_arr = []
        name_arr = []
      else
        return path
      end
    end

    if folder_id.to_s == TreeElement::ROOT_ID.to_s
      path = '/(root)'
      folders_cache[folder_id.to_i] = path unless folders_cache.nil?
      return path
    end

    path = ''
    cached_path = nil

    while folder_id.to_s != TreeElement::ROOT_ID.to_s

      unless folders_cache.nil?
        cached_path = folders_cache[folder_id.to_i]
        unless cached_path.nil?
          path = cached_path + path
          break
        end
      end

      folder = Folder.find_with_cache(folder_id, folder_obj_cache)

      id_arr.unshift(folder_id.to_i) unless folders_cache.nil?

      if folder.nil?
        path = '/' + I18n.t('paren.deleted') + path
        name_arr.unshift(I18n.t('paren.deleted')) unless folders_cache.nil?
        break
      else
        path = '/' + folder.name + path
        name_arr.unshift(folder.name) unless folders_cache.nil?
      end

      folder_id = folder.parent_id
    end

    unless folders_cache.nil?
      path_to_cache = ''
      unless cached_path.nil?
        path_to_cache << cached_path
      end
      id_arr.each_with_index do |f_id, idx|
        path_to_cache << '/' + name_arr[idx]

        folders_cache[f_id] = path_to_cache.dup
      end
    end

    return path
  end

  #=== self.check_user_auth
  #
  #Checks user authority to read or write contents
  #in the specified folder.
  #
  #_folder_id_:: Folder-ID.
  #_user_:: Target User.
  #_rxw_:: Specify 'r' to check read-authority, 'w' write-authority.
  #_check_admin_:: Flag to consider about User's authority.
  #return:: true if specified user has authority, false otherwise.
  #
  def self.check_user_auth(folder_id, user, rxw, check_admin)

    if user.nil? and (rxw == 'w')
      return false
    end

    if check_admin and !user.nil? and user.admin?(User::AUTH_FOLDER)
      return true
    end

    return true if (folder_id.to_s == TreeElement::ROOT_ID.to_s)

    begin
      folder = Folder.find(folder_id)
    rescue => evar
      Log.add_error(nil, evar)
      return false
    end

    if (rxw == 'r')
      users = folder.get_read_users_a
      groups = folder.get_read_groups_a
      teams = folder.get_read_teams_a
    else
      users = folder.get_write_users_a
      groups = folder.get_write_groups_a
      teams = folder.get_write_teams_a
    end

    # If set no authorities, it will be public.
    if users.empty? and groups.empty? and teams.empty?
      return true
    elsif user.nil?
      return false
    end

    # user auth
    if users.include?(user.id.to_s)
      return true
    end

    # group auth
    user_groups = user.get_groups_a(true)
    user_groups.each do |group_id|
      return true if groups.include?(group_id)
    end

    # team auth
    user_teams = user.get_teams_a
    user_teams.each do |team_id|
      return true if teams.include?(team_id)
    end

    return false
  end

  #=== get_path
  #
  #Gets path-string which represents location of this folder.
  #
  #_folders_cache_:: Hash to accelerate response. {folder.id, path}
  #_folder_obj_cache_:: Hash to accelerate response. {folder.id, folder}
  #return:: Folder path like "/parent_name1/parent_name2/this_name".
  #
  def get_path(folders_cache=nil, folder_obj_cache=nil)

    return Folder.get_path(self.id, folders_cache, folder_obj_cache)
  end

  #=== inherit_parent_auth
  #
  #Inherits authorities of parent Folder.
  #Required parent_id to be set in advance.
  #
  def inherit_parent_auth

    return if self.parent_id == 0

    begin
      parent = Folder.find(self.parent_id)

      self.read_users = parent.read_users
      self.write_users = parent.write_users
      self.read_groups = parent.read_groups
      self.write_groups = parent.write_groups
      self.read_teams = parent.read_teams
      self.write_teams = parent.write_teams

    rescue => evar
      Log.add_error(nil, evar)
    end
  end

  #=== self.get_childs_for
  #
  #Gets child nodes array of the Folder for specified User.
  #Implemented as a class-method because of considering about root Folder
  #which has no record in DB.
  #
  #_user_:: Target User.
  #_folder_id_:: Folder-ID.
  #_recursive_:: Specify true if recursive search is required.
  #_admin_:: Administrator flag.
  #_ret_obj_:: Flag to require Folder instances by return.
  #return:: Array of child Folder-IDs, or Folders if ret_obj is true.
  #
  def self.get_childs_for(user, folder_id, recursive, admin, ret_obj)

    if admin.nil?
      if user.nil?
        admin = false
      else
        admin = user.admin?(User::AUTH_FOLDER)
      end
    end

    con = Folder.get_condtions_for(user, admin)

    return Folder.get_childs(folder_id, con, recursive, admin, ret_obj)
  end

  #=== self.get_childs
  #
  #Gets child nodes array of the Folder.
  #Implemented as a class-method because of considering about root Folder
  #which has no record in DB.
  #
  #_folder_id_:: Folder-ID.
  #_conditions_:: Conditions. Specify nil if not required.
  #_recursive_:: Specify true if recursive search is required.
  #_admin_:: Administrator flag.
  #_ret_obj_:: Flag to require Folder instances by return.
  #return:: Array of child Folder-IDs, or Folders if ret_obj is true.
  #
  def self.get_childs(folder_id, conditions, recursive, admin, ret_obj)

    SqlHelper.validate_token([folder_id])
    arr = []

    if recursive

      folder_tree = Folder.get_tree(Hash.new, conditions, folder_id, admin)
      return [] if folder_tree.nil?

      folder_tree.each do |parent_id, childs|
        if ret_obj
          arr |= childs
        else
          childs.each do |folder|
            folder_id = folder.id.to_s
            arr << folder_id unless arr.include?(folder_id)
          end
        end
      end

    else

      con = Marshal.load(Marshal.dump(conditions))
      if con.nil?
        con = ''
      else
        con << ' and '
      end
      con << "parent_id=#{folder_id.to_i}"

      unless admin
        con << " and (xtype is null or not (xtype='#{Folder::XTYPE_SYSTEM}'))"
      end

      folders = Folder.where(con).order('xorder ASC').to_a
      if ret_obj
        arr = folders
      else
        folders.each do |folder|
          arr << folder.id.to_s
        end
      end
    end

    return arr
  end

  #=== self.get_items
  #
  #Gets Items in specified Folder.
  #Implemented as a class-method because of considering about root Folder
  #which has no record in DB.
  #
  #_user_:: User for whom list will be made.
  #_folder_id_:: Target Folder-ID.
  #_order_by_:: Order. ex. 'xorder ASC'
  #return:: Items in the Folder.
  #
  def self.get_items(user, folder_id, order_by=nil)

    sort_field, sort_direction = FoldersHelper.get_sort_params(folder_id, order_by)

    sql = ItemsHelper.get_list_sql(user, nil, folder_id, sort_field, sort_direction, 0, false, nil)
    return Item.find_by_sql(sql)
  end

  #=== self.get_items_admin
  #
  #Get items in specified Folder for Administrators.
  #Implemented as a class-method because of considering about root Folder
  #which has no record in DB.
  #
  #_folder_id_:: Target Folder-ID.
  #_order_by_:: Order. ex. 'xorder ASC'
  #_add_con_:: Additional condition.
  #return:: Items in the Folder.
  #
  def self.get_items_admin(folder_id, order_by=nil, add_con=nil)

    sort_field, sort_direction = FoldersHelper.get_sort_params(folder_id, order_by)

    sql = ItemsHelper.get_list_sql(nil, nil, folder_id, sort_field, sort_direction, 0, true, add_con)
    return Item.find_by_sql(sql)
  end

  #=== count_items
  #
  #Counts the items in this Folder as Administrator and returns the value.
  #
  #_recursive_:: Specify true if recursive search is required.
  #return:: Count of Items.
  #
  def count_items(recursive)

    count = Item.count_by_sql("SELECT COUNT(*) FROM items WHERE folder_id="+self.id.to_s)

    childs = Folder.get_childs(self.id, nil, recursive, true, false)
    childs.each do |child_id|
      count = count + Item.count_by_sql("SELECT COUNT(*) FROM items WHERE folder_id="+child_id)
    end

    return count
  end

  #=== force_destroy
  #
  #Destroys with all sub Folders and their Items.
  #
  def force_destroy

    childs = Folder.get_childs(self.id, nil, true, true, true)

    childs.each do |folder|
      begin
        folder.destroy
      rescue => evar
        Log.add_error(nil, evar)
      end

      items = Item.where("folder_id=#{folder.id}").to_a
      items.each do |item|
        item.destroy
      end
    end

    items = Item.where("folder_id=#{self.id}").to_a
    items.each do |item|
      item.destroy
    end

    self.destroy
  end

  #=== get_disp_ctrl_h
  #
  #Gets hash of the display controll parameters of this Folder.
  #
  #return:: display controll hash.
  #
  def get_disp_ctrl_h

    return {} if self.disp_ctrl.blank?

    ret = {}

    arr = ApplicationHelper.attr_to_a(self.disp_ctrl)
    arr.each do |param|
      if param.include?('=')
        kv = param.split('=')
        key = kv.first
        value = kv.last
      else
        key = param
        value = ''
      end

      ret[key] = value
    end

    return ret
  end

  #=== bbs_top?
  #
  #Gets whether this Folder is set to be shown in BBS Top.
  #
  #return:: true if this Folder is set to be shown in BBS Top, false otherwise.
  #
  def bbs_top?
    disp_ctrl = self.get_disp_ctrl_h
    return disp_ctrl.keys.include?(Folder::DISPCTRL_BBS_TOP)
  end

  #=== in_my_folder_of?
  #
  #Gets whether this Folder is My Folder of specified User or one of its sub Folders.
  #
  #_user_id_:: User-ID.
  #return:: true if My Folder or its sub Folder, false otherwise.
  #
  def in_my_folder_of?(user_id)

    my_folder = User.get_my_folder(user_id)
    return false if my_folder.nil?

    return true if (my_folder.id == self.id)

    return self.get_parents(false).include?(my_folder.id.to_s)
  end

  #=== get_my_folder_owner
  #
  #Gets owner of My Folder or one of its sub Folders.
  #
  #return:: User-ID of My Folder. If this is not My Folder or one of its sub Folders, returns nil.
  #
  def get_my_folder_owner

    return self.owner_id if self.my_folder?

    user_id = nil
    self.get_parents(true).each do |folder|
      # Returns last owner_id
      user_id = folder.owner_id if folder.my_folder?
    end
    return user_id
  end

  #=== my_folder?
  #
  #Gets if this is My Folder.
  #
  #return:: true if this is My Folder, false otherwise.
  #
  def my_folder?

    return (self.xtype == Folder::XTYPE_USER)
  end

  #=== get_read_users_a
  #
  #Gets Users who have reading authority in this Folder.
  #
  #return:: Users array who have reading authority in this Folder.
  #
  def get_read_users_a

    return ApplicationHelper.attr_to_a(self.read_users)
  end

  #=== get_write_users_a
  #
  #Gets Users who have writing authority in this Folder.
  #
  #_include_parents_:: Specify true if it is required to take parents authorities into consideration (AND).
  #return:: Users array who have writing authority in this Folder.
  #
  def get_write_users_a(include_parents=false)

    arr = []

    if include_parents
      parents = self.get_parents(true)
      parents.each do |folder|
        users = folder.get_write_users_a(false)
        next if users.nil? or users.length <= 0

        if (arr.length <= 0)
          arr = users
        else
          arr = arr & users
        end
      end

      users = self.get_write_users_a(false)
      if (arr.length <= 0)
        arr = users
      else
        arr = arr & users
      end

    else

      arr = ApplicationHelper.attr_to_a(self.write_users)
    end

    return arr
  end

  #=== set_read_users
  #
  #Sets Users who have reading authority in this Folder.
  #
  #_users_:: Array of User-IDs.
  #
  def set_read_users(users)

    users = users.to_a unless users.nil?

    if users.nil? or users.empty?
      self.read_users = nil
      return
    end

    self.read_users = ApplicationHelper.a_to_attr(users.uniq)
  end

  #=== set_write_users
  #
  #Sets Users who have writing authority in this Folder.
  #
  #_users_:: Array of User-IDs.
  #
  def set_write_users(users)

    users = users.to_a unless users.nil?

    if users.nil? or users.empty?
      self.write_users = nil
      return
    end

    self.write_users = ApplicationHelper.a_to_attr(users.uniq)
  end

  #=== get_read_groups_a
  #
  #Get Groups who have reading authority in this Folder.
  #
  #return:: Groups array which have reading authority in this Folder.
  #
  def get_read_groups_a

    return ApplicationHelper.attr_to_a(self.read_groups)
  end

  #=== get_write_groups_a
  #
  #Get Groups who has writing authority in this Folder.
  #
  #_include_parents_:: Specify true if it is required to take parents authorities into consideration (AND).
  #return:: Groups array which have writing authority in this Folder.
  #
  def get_write_groups_a(include_parents=false)

    arr = []

    if include_parents
      parents = self.get_parents(true)
      parents.each do |folder|
        groups =folder.get_write_groups_a(false)
        next if groups.nil? or groups.length <= 0

        if (arr.length <= 0)
          arr = groups
        else
          arr = arr & groups
        end
      end

      groups = self.get_write_groups_a(false)
      if (arr.length <= 0)
        arr = groups
      else
        arr = arr & groups
      end

    else

      arr = ApplicationHelper.attr_to_a(self.write_groups)
    end

    return arr
  end

  #=== set_read_groups
  #
  #Set Groups which have reading authority in this Folder.
  #
  #_groups_:: Array of Group-IDs.
  #
  def set_read_groups(groups)

    groups = groups.to_a unless groups.nil?

    if groups.nil? or groups.empty?
      self.read_groups = nil
      return
    end

    self.read_groups = ApplicationHelper.a_to_attr(groups.uniq)
  end

  #=== set_write_groups
  #
  #Set Groups which have writing authority in this Folder.
  #
  #_groups_:: Array of Group-IDs.
  #
  def set_write_groups(groups)

    groups = groups.to_a unless groups.nil?

    if groups.nil? or groups.empty?
      self.write_groups = nil
      return
    end

    self.write_groups = ApplicationHelper.a_to_attr(groups.uniq)
  end

  #=== get_read_teams_a
  #
  #Get Teams who have reading authority in this Folder.
  #
  #return:: Teams array which have reading authority in this Folder.
  #
  def get_read_teams_a

    return ApplicationHelper.attr_to_a(self.read_teams)
  end

  #=== get_write_teams_a
  #
  #Get Teams who have writing authority in this Folder.
  #
  #_include_parents_:: Specify true if it is required to take parents authorities into consideration (AND).
  #return:: Teams array which have writing authority in this Folder.
  #
  def get_write_teams_a(include_parents=false)

    arr = []

    if include_parents
      parents = self.get_parents(true)
      parents.each do |folder|
        teams = folder.get_write_teams_a(false)
        next if teams.nil? or (teams.length <= 0)

        if (arr.length <= 0)
          arr = teams
        else
          arr = arr & teams
        end
      end

      teams = self.get_write_teams_a(false)
      if (arr.length <= 0)
        arr = teams
      else
        arr = arr & teams
      end

    else

      arr = ApplicationHelper.attr_to_a(self.write_teams)
    end

    return arr
  end

  #=== set_read_teams
  #
  #Set Teams which have reading authority in this Folder.
  #
  #_teams_:: Array of Team-IDs.
  #
  def set_read_teams(teams)

    teams = teams.to_a unless teams.nil?

    if teams.nil? or teams.empty?
      self.read_teams = nil
      return
    end

    self.read_teams = ApplicationHelper.a_to_attr(teams.uniq)
  end

  #=== set_write_teams
  #
  #Set Teams which have writing authority in this Folder.
  #
  #_teams_:: Array of Team-IDs.
  #
  def set_write_teams(teams)

    teams = teams.to_a unless teams.nil?

    if teams.nil? or teams.empty?
      self.write_teams = nil
      return
    end

    self.write_teams = ApplicationHelper.a_to_attr(teams.uniq)
  end

  #=== remove_auth_user
  #
  #Removes authority of specified Users.
  #
  #_user_::Target User.
  #
  def remove_auth_user(user)

    user_id = user.id.to_s

    arr = self.get_read_users_a
    arr.delete(user_id)
    self.set_read_users(arr)

    arr = self.get_write_users_a
    arr.delete(user_id)
    self.set_write_users(arr)
  end

  #=== slice_auth_group
  #
  #Slices authority of specified Group into those of Users.
  #
  #_group_::Target Group.
  #
  def slice_auth_group(group)

    group_id = group.id.to_s

    read_updated = false
    write_updated = false

    arr = self.get_read_groups_a
    if arr.include?(group_id)
      arr.delete(group_id)
      self.set_read_groups(arr)
      read_updated = true
    end

    arr = self.get_write_groups_a
    if arr.include?(group_id)
      arr.delete(group_id)
      self.set_write_groups(arr)
      write_updated = true
    end

    members = Group.get_users(group.id).collect {|user| user.id.to_s}

    unless members.empty?
      self.set_read_users(self.get_read_users_a | members) if read_updated
      self.set_write_users(self.get_write_users_a | members) if write_updated
    end
  end

  #=== slice_auth_team
  #
  #Slices authority of specified Team into those of Users.
  #
  #_team_::Target Team.
  #
  def slice_auth_team(team)

    team_id = team.id.to_s

    read_updated = false
    write_updated = false

    arr = self.get_read_teams_a
    if arr.include?(team_id)
      arr.delete(team_id)
      self.set_read_teams(arr)
      read_updated = true
    end

    arr = self.get_write_teams_a
    if arr.include?(team_id)
      arr.delete(team_id)
      self.set_write_teams(arr)
      write_updated = true
    end

    members = team.get_users_a

    unless members.empty?
      self.set_read_users(self.get_read_users_a | members) if read_updated
      self.set_write_users(self.get_write_users_a | members) if write_updated
    end
  end

  #=== locked?
  #
  #Gets if this Folder is applied any authorities.
  #
  #return::True if this Folder is locked, false otherwise.
  #
  def locked?

   return (self.get_read_users_a.length > 0 or self.get_write_users_a.length > 0 or self.get_read_groups_a.length > 0 or self.get_write_groups_a.length > 0 or self.get_read_teams_a.length > 0 or self.get_write_teams_a.length > 0)
  end

  #=== self.exists?
  #
  #Gets if the specified Folder exists.
  #
  #_folder_id_:: Target Folder_ID.
  #return::True if it exists. false otherwise.
  #
  def self.exists?(folder_id)

    return false if folder_id.nil?

    return true if (folder_id.to_s == TreeElement::ROOT_ID.to_s)

    folder = nil
    begin
      folder = Folder.find(folder_id)
    rescue
    end

    return (!folder.nil?)
  end

  #=== exists?
  #
  #Gets if the Folder exists.
  #
  #return::True if it exists. false otherwise.
  #
  def exists?
    return Folder.exists?(self.id)
  end

end
