#
#= ZeptairPostController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about ZeptairPost.
#
#== Note:
#
#* 
#
class ZeptairPostController < ApplicationController

  require 'csv'

  before_filter :check_login


  #=== upload
  #
  #Uploads a attachment file.
  #
  def upload
    Log.add_info(request, '')   # Not to show passwords.

    if params[:file].nil? or params[:file].size <= 0
      render(:text => '')
      return
    end

    login_user = session[:login_user]

    post_item = ZeptairPostHelper.get_item_for(login_user)

    Attachment.create(params, post_item, 0)

    post_item.update_attribute(:updated_at, Time.now)

    render(:text => t('file.uploaded'))
  end

  #=== download
  #
  #Downloads a attachment file.
  #
  def download
    Log.add_info(request, '')   # Not to show passwords.

    attach = Attachment.find(params[:id])

    login_user = session[:login_user]

    post_item = ZeptairPostHelper.get_item_for(login_user)

    if post_item.id != attach.item_id
      render(:text => 'ERROR:' + t('msg.system_error'))
      return
    end

    if attach.location == Attachment::LOCATION_DIR

      filepath = AttachmentsHelper.get_path(attach)

      send_file(filepath, :filename => attach.name, :stream => true, :disposition => 'attachment')
    else
      send_data(attach.content, :type => (attach.content_type || 'application/octet-stream')+';charset=UTF-8', :disposition => 'attachment;filename="'+attach.name+'"')
    end
  end

  #=== query
  #
  #Queries available post entries.
  #
  def query
    Log.add_info(request, '')   # Not to show passwords.

    login_user = session[:login_user]

    unless login_user.admin?(User::AUTH_ZEPTAIR)
      render(:text => 'ERROR:' + t('msg.need_to_be_admin'))
      return
    end

    target_user = nil

    unless params[:user_id].nil? or params[:user_id].empty?
      target_user = User.find(params[:user_id])
    end

    unless params[:zeptair_id].nil? or params[:zeptair_id].empty?
      target_user = User.find(:first, :conditions => ['zeptair_id=?', params[:zeptair_id]])
    end

    if target_user.nil?

      if params[:group_id].nil? or params[:group_id].empty?
        sql = 'select distinct Item.* from items Item, attachments Attachment'
        sql << " where Item.xtype='#{Item::XTYPE_ZEPTAIR_POST}' and Item.id=Attachment.item_id"
        sql << ' order by Item.user_id ASC'
      else
        group_ids = [params[:group_id]]

        if params[:recursive] == 'true'
          group_ids += Group.get_childs(params[:group_id], true, false)
        end

        groups_con = []
        group_ids.each do |group_id|
          groups_con << "(User.groups like '%|#{group_id}|%')"
        end
        sql = 'select distinct Item.* from items Item, attachments Attachment, users User'
        sql << " where Item.xtype='#{Item::XTYPE_ZEPTAIR_POST}' and Item.id=Attachment.item_id"
        sql << " and (Item.user_id=User.id and (#{groups_con.join(' or ')}))"
        sql << ' order by Item.user_id ASC'
      end

      @post_items = Item.find_by_sql(sql)
    else
      @post_item = ZeptairPostHelper.get_item_for(target_user)
    end

  rescue StandardError => err
    Log.add_error(request, err)
    render(:text => 'ERROR:' + t('msg.system_error'))
  end

  #=== delete_attachment
  #
  #Deletes Attachment.
  #
  def delete_attachment
    Log.add_info(request, '')   # Not to show passwords.

    login_user = session[:login_user]

    target_user = nil

    unless params[:user_id].nil? or params[:user_id].empty?
      if login_user.admin?(User::AUTH_ZEPTAIR) or login_user.id.to_s == params[:user_id].to_s
        target_user = User.find(params[:user_id])
      end
    end

    unless params[:zeptair_id].nil? or params[:zeptair_id].empty?

      target_user = User.find(:first, :conditions => ['zeptair_id=?', params[:zeptair_id]])

      unless login_user.admin?(User::AUTH_ZEPTAIR) or login_user.id == target_user.id
        target_user = nil
      end
    end

    if target_user.nil?
      if params[:attachment_id].nil? or params[:attachment_id].empty?

        query
        unless @post_items.nil?
          @post_items.each do |post_item|
            post_item.attachments_without_content.each do |attach|
              attach.destroy
            end
            post_item.update_attribute(:updated_at, Time.now)
          end
        end

      else
        attach = Attachment.find(params[:attachment_id])

        item = Item.find(attach.item_id)

        if !login_user.admin?(User::AUTH_ZEPTAIR) and item.user_id != login_user.id
          raise t('msg.need_to_be_owner')
        end

        if item.xtype != Item::XTYPE_ZEPTAIR_POST
          raise t('msg.system_error')
        end

        attach.destroy

        item.update_attribute(:updated_at, Time.now)
      end
    else

      post_item = ZeptairPostHelper.get_item_for(target_user)
      post_item.attachments_without_content.each do |attach|
        attach.destroy
      end
      post_item.update_attribute(:updated_at, Time.now)
    end

    render(:text => t('msg.delete_success'))

  rescue StandardError => err
    Log.add_error(request, err)
    render(:text => 'ERROR:' + t('msg.system_error'))
  end
end
