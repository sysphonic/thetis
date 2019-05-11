#
#= Group
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
#== Note:
#
#* Root Group has no records in DB, and its ID is '0'.
#
class Group < ApplicationRecord

  has_many(:official_titles, {:dependent => :destroy})

  extend(CachedRecord)
  include(TreeElement)

  before_destroy do |rec|
    # Group Folder
    folder = Group.get_group_folder(rec.id)

    unless folder.nil?

      if (folder.count_items(true) <= 0)
        folder.force_destroy
      else
        folder.slice_auth_group(rec)
        folder.owner_id = 0
        folder.xtype = nil
        folder.save
      end
    end

    # General Folders
    con = SqlHelper.get_sql_like([:read_groups, :write_groups], "|#{rec.id}|")
    folders = Folder.where(con).to_a

    unless folders.nil?
      folders.each do |folder|
        folder.slice_auth_group(rec)
        folder.save
      end
    end

    # Users
    users = Group.get_users(rec.id)
    unless users.nil?
      users.each do |user|
        user.exclude_from(rec.id)
        user.save
      end
    end

    # Subgroups
    rec.get_childs(false, true).each do |group|
      group.destroy
    end

    # Schedules
    Schedule.trim_on_destroy_member(:group, rec.id)

    # Locations and OfficeMaps
    Location.where("(group_id=#{rec.id})").destroy_all
    OfficeMap.where("(group_id=#{rec.id})").destroy_all

    # Settings
    Setting.where("(group_id=#{rec.id})").destroy_all
  end

  #=== rename
  #
  #Renames Group.
  #
  #_new_name_:: New name.
  #
  def rename(new_name)

    self.update_attribute(:name, new_name)

    folder = self.get_group_folder

    unless folder.nil?
      folder.update_attribute(:name, new_name)
    end
  end

  #=== self.get_path
  #
  #Gets path-string which represents the position of this Group in the organization.
  #
  #_group_id_:: Target Group-ID.
  #_groups_cache_:: Hash to accelerate response. {group.id, path}
  #_group_obj_cache_:: Hash to accelerate response. {group.id, group}
  #return:: Group path like "/parent_name1/parent_name2/this_name".
  #
  def self.get_path(group_id, groups_cache=nil, group_obj_cache=nil)

    unless groups_cache.nil?
      path = groups_cache[group_id.to_i]
      if path.nil?
        id_arr = []
        name_arr = []
      else
        return path
      end
    end

    if (group_id.to_s == TreeElement::ROOT_ID.to_s)
      path = '/(root)'
      groups_cache[group_id.to_i] = path unless groups_cache.nil?
      return path
    end

    path = ''
    cached_path = nil

    while group_id.to_s != TreeElement::ROOT_ID.to_s

      unless groups_cache.nil?
        cached_path = groups_cache[group_id.to_i]
        unless cached_path.nil?
          path = cached_path + path
          break
        end
      end

      group = Group.find_with_cache(group_id, group_obj_cache)

      id_arr.unshift(group_id.to_i) unless groups_cache.nil?

      if group.nil?
        path = '/' + I18n.t('paren.deleted') + path
        name_arr.unshift(I18n.t('paren.deleted')) unless groups_cache.nil?
        break
      else
        path = '/' + group.name + path
        name_arr.unshift(group.name) unless groups_cache.nil?
      end

      group_id = group.parent_id
    end

    unless groups_cache.nil?
      path_to_cache = ''
      unless cached_path.nil?
        path_to_cache << cached_path
      end
      id_arr.each_with_index do |f_id, idx|
        path_to_cache << '/' + name_arr[idx]

        groups_cache[f_id] = path_to_cache.dup
      end
    end

    return path
  end

  #=== self.get_users
  #
  #Gets Users in specified Group.
  #
  #_recursive_:: Specify true if recursive search is required.
  #return:: Users in specified Group.
  #
  def self.get_users(group_id, recursive=false)

    return [] if group_id.nil?

    users = []

    if recursive
      Group.get_childs(group_id, recursive, false).each do |child_id|
        users |= Group.get_users(child_id, false)
      end
    end

    group_id = group_id.to_s

    if (group_id == TreeElement::ROOT_ID.to_s)
      con = "((groups like '%|#{TreeElement::ROOT_ID}|%') or (groups is null))"
    else
      con = SqlHelper.get_sql_like([:groups], "|#{group_id}|")
    end

    users |= User.find_all(con)

    return OfficialTitlesHelper.sort_users(users, :asc, group_id)
  end

  #=== self.get_equipment
  #
  #Gets Equipment in specified Group.
  #
  #return:: Equipment in specified Group.
  #
  def self.get_equipment(group_id)

    return [] if group_id.nil?

    group_id = group_id.to_s

    if (group_id == TreeElement::ROOT_ID.to_s)
      con = "((groups like '%|#{TreeElement::ROOT_ID}|%') or (groups is null))"
    else
      con = SqlHelper.get_sql_like([:groups], "|#{group_id}|")
    end

    return Equipment.where(con).to_a
  end

  #=== get_path
  #
  #Gets path-string which represents the position of this Group in the organization.
  #
  #_groups_cache_:: Hash to accelerate response. {group.id, path}
  #_group_obj_cache_:: Hash to accelerate response. {group.id, group}
  #return:: Group path like "/parent_name1/parent_name2/this_name".
  #
  def get_path(groups_cache=nil, group_obj_cache=nil)

    return Group.get_path(self.id, groups_cache, group_obj_cache)
  end

  #=== self.get_tree
  #
  #Gets tree of Groups.
  #Called recursive.
  #
  def self.get_tree(group_tree, conditions, tree_id)

    return TreeElement.get_tree(self, group_tree, conditions, tree_id, 'xorder ASC, id ASC')
  end

  #=== self.get_childs
  #
  #Gets child nodes array of the specified Group.
  #
  #_group_id_:: Target Group-ID.
  #_recursive_:: Specify true if recursive search is required.
  #_ret_obj_:: Flag to require Group instances by return.
  #return:: Array of child Group-IDs, or Groups if ret_obj is true.
  #
  def self.get_childs(group_id, recursive, ret_obj)

    return TreeElement.get_childs(self, group_id, recursive, ret_obj)
  end

  #=== self.get_branches
  #
  #Gets Array of Group branches to which the User belongs.
  #
  #_grp_ids_:: Array of Groups to build branches of.
  #_group_id_:: Target Group-ID.
  #_group_obj_cache_:: Hash to accelerate response. {group_id, group}
  #return:: Array of Group branches.
  #
  def self.get_branches(grp_ids, group_id=nil, group_obj_cache=nil)

    return [] if (grp_ids.nil? or grp_ids.empty?)

    group_branches = []
    grp_ids.sort{|a, b| a.to_i <=> b.to_i}.each do |grp_id|
      group = Group.find_with_cache(grp_id, group_obj_cache)

      unless group.nil?
        branch = group.get_parents(false, group_obj_cache)
        branch << grp_id
        group_branches << branch
      end
    end

    if group_id.nil?
    elsif (group_id.to_s == TreeElement::ROOT_ID.to_s)
      group_branches = [[]]
    else
      target_group = Group.find_with_cache(group_id, group_obj_cache)
      return [] if target_group.nil?

      target_branch = target_group.get_parents(false, group_obj_cache)
      target_branch << group_id.to_s

      group_branches.map!{|group_branch| target_branch & group_branch}
      max_branch = []
      group_branches.each do |group_branch|
        if (max_branch.length < group_branch.length)
          max_branch = group_branch
        end
      end
      group_branches = [max_branch]
    end

    return group_branches
  end

  #=== count_users
  #
  #Gets count of Users.
  #
  #_recursive_:: Specify true if recursive search is required.
  #return:: Count of users.
  #
  def count_users(recursive)

    count = User.count_by_sql('SELECT COUNT(*) FROM users WHERE '+SqlHelper.get_sql_like([:groups], "|#{self.id}|"))

    childs = get_childs(recursive, false)
    childs.each do |child_id|
      count = count + Item.count_by_sql('SELECT COUNT(*) FROM users WHERE'+SqlHelper.get_sql_like([:groups], "|#{child_id}|"))
    end

    return count
  end

  #=== self.get_name
  #
  #Gets the name of the specified Group.
  #
  #return:: Group name. If not found, prearranged string.
  #
  def self.get_name(group_id)

    return '(root)' if (group_id.to_s == TreeElement::ROOT_ID.to_s)

    begin
      group = Group.find(group_id)
    rescue
    end
    if group.nil?
      return group_id.to_s + ' '+ I18n.t('paren.deleted')
    else
      return group.name
    end
  end

  #=== get_group_folder
  #
  #Gets Group Folder.
  #
  #return:: Folder object of the Group.
  #
  def get_group_folder

    Group.get_group_folder(self.id)
  end

  #=== self.get_group_folder
  #
  #Gets Group Folder of specified Group-ID.
  #
  #_group_id_:: Target Group-ID.
  #return:: Folder object of the Group.
  #
  def self.get_group_folder(group_id)

    SqlHelper.validate_token([group_id])
    begin
      return Folder.where("(owner_id=#{group_id.to_i}) and (xtype='#{Folder::XTYPE_GROUP}')").first
    rescue => evar
      Log.add_error(nil, evar)
      return nil
    end
  end

  #=== create_group_folder
  #
  #Creates Group Folder.
  #
  #return:: Folder object of the Group.
  #
  def create_group_folder

    folder = Folder.new
    folder.name = self.name
    folder.parent_id = 0
    folder.owner_id = self.id
    folder.xtype = Folder::XTYPE_GROUP
    folder.read_groups = ApplicationHelper.a_to_attr([self.id])
    folder.write_groups = ApplicationHelper.a_to_attr([self.id])
    folder.save!

    return folder
 end
end
