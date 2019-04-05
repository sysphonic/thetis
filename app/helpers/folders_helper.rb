#
#= FoldersHelper
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
module FoldersHelper

  #=== self.get_sort_params
  #
  #Get sorting parameters.
  #
  #_folder_id_:: Target Folder-ID.
  #_order_by_:: Order. ex. 'xorder ASC'
  #return:: Array of Sort-Field and Sort-Direction.
  #
  def self.get_sort_params(folder_id, order_by=nil)

    if order_by.nil?

      if folder_id.blank? or (folder_id.to_s == TreeElement::ROOT_ID.to_s)
        default_sort = nil
      else
        disp_ctrl = Folder.find(folder_id).get_disp_ctrl_h
        default_sort = disp_ctrl[Folder::DISPCTRL_DEF_SORT]
      end

      if default_sort.blank?
        sort_field = Item::SORT_FIELD_DEFAULT
        sort_direction = Item::SORT_DIRECTION_DEFAULT
      else
        sort_a = default_sort.split(' ')
        sort_field = sort_a.first
        sort_direction = sort_a.last
      end

    else
      arr = order_by.split(' ')

      sort_field = arr.first

      if (arr.length <= 1)
        sort_direction = 'ASC'
      else
        sort_direction = arr.last
      end
    end

    return [sort_field, sort_direction]
  end

  #=== self.get_except_top_for_admin
  #
  #_top_childs_:: Top level subfolders just under the root.
  #_group_id_:: Target Group-ID.
  #return:: Array of folders to except.
  #
  def self.get_except_top_for_admin(top_childs, group_id)

    return [] if top_childs.nil?

    delete_arr = []

    if group_id.nil?

      top_childs.each do |folder|
        if (folder.xtype == Folder::XTYPE_USER) or (folder.xtype == Folder::XTYPE_GROUP)
          delete_arr << folder
        end
      end

    else

      users_cache = {}
      all_users = User.where(nil).to_a
      unless all_users.nil?
        all_users.each do |user|
          users_cache[user.id] = user
        end
      end

      if (group_id == TreeElement::ROOT_ID.to_s)

        top_childs.each do |folder|
          if (folder.xtype == Folder::XTYPE_USER)

            user = users_cache.delete(folder.owner_id)

            unless user.nil? or user.get_groups_a.empty?
              delete_arr << folder
            end
          else
            delete_arr << folder
          end
        end

      else
        top_childs.each do |folder|
          if (folder.xtype == Folder::XTYPE_USER)

            user = users_cache.delete folder.owner_id

            unless user.nil? or user.get_groups_a.include?(group_id)
              delete_arr << folder
            end

          elsif (folder.xtype == Folder::XTYPE_GROUP)

            if (folder.owner_id.to_s != group_id)
              delete_arr << folder
            end
          else
            delete_arr << folder
          end
        end
      end
    end

    return delete_arr
  end
end
