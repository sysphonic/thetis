#
#= InquiryController
#
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Handles inquiries from client applications.
#
#== Note:
#
#* 
#
class InquiryController < ApplicationController

  require 'csv'

  before_filter :check_login


  #=== auth
  #
  #Gets authorities of the User.
  #
  def auth
    Log.add_info(request, '')   # Not to show passwords.

    render(:text => @login_user.auth)
  end

  #=== groups
  #
  #Gets groups list.
  #
  def groups
    Log.add_info(request, '')   # Not to show passwords.

    ary = []
    groups = Group.where(nil).to_a
    unless groups.nil?
      groups_cache = {}
      group_obj_cache = Group.build_cache(groups)
      groups.each do |group|
        ary << group.id.to_s + ':' + Group.get_path(group.id, groups_cache, group_obj_cache)
      end
    end

    render(:text => ary.join("\n"))
  end

  #=== users
  #
  #Gets users list.
  #
  def users
    Log.add_info(request, '')   # Not to show passwords.

    if params[:group_id].nil?
      group_id = TreeElement::ROOT_ID.to_s
    else
      group_id = params[:group_id]
    end

    ary = []

    users = Group.get_users(group_id)
    unless users.nil?
      users.each do |user|
        ary << user.id.to_s + ':' + user.get_name
      end
    end

    if params[:recursive] == 'true'
      child_ids = Group.get_childs(group_id, true, false)

      child_ids.each do |child_id|
        users = Group.get_users(child_id)
        unless users.nil?
          users.each do |user|
            ary << user.id.to_s + ':' + user.get_name
          end
        end
      end
    end

    render(:text => ary.join("\n"))
  end

  #=== recent_items
  #
  #Gets recent items.
  #
  def recent_items
    Log.add_info(request, '')   # Not to show passwords.

    add_con = "((Item.xtype in ('#{Item::XTYPE_INFO}','#{Item::XTYPE_PROJECT}')) or ((Item.xtype = '#{Item::XTYPE_WORKFLOW}') and (Item.original_by is not null)))"
    sql = ItemsHelper.get_list_sql(@login_user, nil, nil, nil, nil, 10, false, add_con)
    @items = Item.find_by_sql(sql)
  end
end
