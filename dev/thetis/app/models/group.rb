#
#= Group
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Group contains Users and sub Groups, and represents the unit in the organization.
#
#== Note:
#
#* Root Group has no records in DB, and its ID is '0'.
#
class Group < ActiveRecord::Base

  extend CachedRecord
  include TreeElement

  #=== self.destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  #_id_:: Target Group-ID.
  #
  def self.destroy(id)

    id.is_a?(Array) ? id.each { |id| destroy(id) } : find(id).destroy
  end

  #=== destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  def destroy()

    # Group Folder
    folder = Group.get_group_folder(self.id)

    unless folder.nil?

      if folder.count_items(true) <= 0

        folder.force_destroy

      else

        folder.slice_auth_group(self)
        folder.owner_id = 0
        folder.xtype = nil
        folder.save
      end
    end

    # General Folders
    con = "(read_groups like '%|#{self.id}|%') or (write_groups like '%|#{self.id}|%')"
    folders = Folder.find(:all, :conditions => con)

    unless folders.nil?
      folders.each do |folder|
        folder.slice_auth_group(self)
        folder.save
      end
    end

    # Users
    users = Group.get_users(self.id)

    unless users.nil?
      users.each do |user|
        user.exclude_from(self.id)
        user.save
      end
    end

    # Subgroups
    self.get_childs(false, true).each do |group|
      group.destroy
    end

    # Schedules
    Schedule.trim_on_destroy_member(:group, self.id)

    super()
  end

  #=== self.delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  #_id_:: Target Group-ID.
  #
  def self.delete(id)

    Group.destroy(id)
  end

  #=== delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  def delete()

    Group.destroy(self.id)
  end

  #=== self.destroy_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.destroy_all(conditions = nil)

    raise 'Use Group.destroy() instead of Group.destroy_all()!'
  end

  #=== self.delete_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.delete_all(conditions = nil)

    raise 'Use Group.destroy() instead of Group.delete_all()!'
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
  #_groups_cache_:: Hash to accelerate response. {group_id, path}
  #_group_obj_cache_:: Hash to accelerate response. {group_id, group}
  #return:: Group path like "/parent_name1/parent_name2/this_name".
  #
  def self.get_path(group_id, groups_cache=nil, group_obj_cache=nil)

    unless groups_cache.nil?
      path = groups_cache[group_id.to_i]
      if path.nil?
        id_ary = []
        name_ary = []
      else
        return path
      end
    end

    if group_id.to_s == '0'  # '0' for ROOT
      path = '/(root)'
      groups_cache[group_id.to_i] = path unless groups_cache.nil?
      return path
    end

    path = ''
    cached_path = nil

    while group_id.to_s != '0'  # '0' for ROOT

      unless groups_cache.nil?
        cached_path = groups_cache[group_id.to_i]
        unless cached_path.nil?
          path = cached_path + path
          break
        end
      end

      group = Group.find_with_cache(group_id, group_obj_cache)

      id_ary.unshift(group_id.to_i) unless groups_cache.nil?

      if group.nil?
        path = '/' + I18n.t('paren.deleted') + path
        name_ary.unshift(I18n.t('paren.deleted')) unless groups_cache.nil?
        break
      else
        path = '/' + group.name + path
        name_ary.unshift(group.name) unless groups_cache.nil?
      end

      group_id = group.parent_id
    end

    unless groups_cache.nil?
      path_to_cache = ''
      unless cached_path.nil?
        path_to_cache << cached_path
      end
      id_ary.each_with_index do |f_id, idx|
        path_to_cache << '/' + name_ary[idx]

        groups_cache[f_id] = path_to_cache.dup
      end
    end

    return path
  end

  #=== self.get_users
  #
  #Gets Users in specified Group.
  #
  #return:: Users in specified Group.
  #
  def self.get_users(group_id)

    return [] if group_id.nil?

    group_id = group_id.to_s

    if group_id == '0'
      con = "((groups like '%|0|%') or (groups is null))"
    else
      con = "groups like '%|"+group_id+"|%'"
    end

    return User.find_all(con)
  end

  #=== get_path
  #
  #Gets path-string which represents the position of this Group in the organization.
  #
  #_groups_cache_:: Hash to accelerate response. {group_id, path}
  #return:: Group path like "/parent_name1/parent_name2/this_name".
  #
  def get_path(groups_cache = nil)

    return Group.get_path(self.id, groups_cache)
  end

  #=== self.get_tree
  #
  #Gets tree of Groups.
  #Called recursive.
  #
  def self.get_tree(group_tree, conditions, tree_id)

    return TreeElement.get_tree(self, group_tree, conditions, tree_id, nil)
  end

  #=== self.get_childs
  #
  #Gets childs array of the specified Group.
  #
  #_group_id_:: Target Group-ID.
  #_recursive_:: Specify true if recursive search is required.
  #_ret_obj_:: Flag to require Group instances by return.
  #return:: Array of child Group-IDs, or Groups if ret_obj is true.
  #
  def self.get_childs(group_id, recursive, ret_obj)

    return TreeElement.get_childs(self, group_id, recursive, ret_obj)
  end

  #=== count_users
  #
  #Gets count of Users.
  #
  #_recursive_:: Specify true if recursive search is required.
  #return:: Count of users.
  #
  def count_users(recursive)

    count = User.count_by_sql("SELECT COUNT(*) FROM users WHERE groups like %|"+self.id.to_s+"|%")

    childs = get_childs(recursive, false)
    childs.each do |child_id|
      count = count + Item.count_by_sql("SELECT COUNT(*) FROM users WHERE groups like %|"+child_id+"|%")
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

    return '(root)' if group_id.to_s == '0'

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

    begin
      return Folder.find(:first, :conditions => ['owner_id=? and xtype=?', group_id.to_i, Folder::XTYPE_GROUP])
    rescue StandardError => err
      Log.add_error(nil, err)
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
    folder.read_groups = '|'+self.id.to_s+'|'
    folder.write_groups = '|'+self.id.to_s+'|'
    folder.save!

    return folder
 end
end
