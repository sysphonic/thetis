#
#= ZeptairPostController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class ZeptairPostController < ApplicationController

  require('csv')

  before_action(:check_login)

  #=== upload
  #
  #Uploads a attachment file.
  #
  def upload
    Log.add_info(request, '')   # Not to show passwords.

    raise(RequestPostOnlyException) unless request.post?

    if (params[:file].nil? or params[:file].size <= 0)
      render(:plain => '')
      return
    end

    post_item = ZeptairPostHelper.get_item_for(@login_user)

    Attachment.create(params, post_item, 0)

    post_item.update_attribute(:updated_at, Time.now)

    render(:plain => t('file.uploaded'))
  end

  #=== download
  #
  #Downloads a attachment file.
  #
  def download
    Log.add_info(request, '')   # Not to show passwords.

    attach = Attachment.find(params[:id])

    post_item = ZeptairPostHelper.get_item_for(@login_user)

    if (post_item.id != attach.item_id)
      render(:plain => 'ERROR:' + t('msg.system_error'))
      return
    end

    if (attach.location == Attachment::LOCATION_DIR)

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

    unless @login_user.admin?(User::AUTH_ZEPTAIR)
      render(:plain => 'ERROR:' + t('msg.need_to_be_admin'))
      return
    end

    target_user = nil

    user_id = params[:user_id]
    zeptair_id = params[:zeptair_id]
    group_id = params[:group_id]
    SqlHelper.validate_token([user_id, zeptair_id, group_id])

    unless user_id.blank?
      target_user = User.find(user_id)
    end

    unless zeptair_id.blank?
      target_user = User.where("zeptair_id=#{zeptair_id.to_i}").first
    end

    if target_user.nil?

      if group_id.blank?
        sql = 'select distinct Item.* from items Item, attachments Attachment'
        sql << " where Item.xtype='#{Item::XTYPE_ZEPTAIR_POST}' and Item.id=Attachment.item_id"
        sql << ' order by Item.user_id ASC'
      else
        group_ids = [group_id]

        if (params[:recursive] == 'true')
          group_ids += Group.get_childs(group_id, true, false)
        end

        groups_con = []
        group_ids.each do |grp_id|
          groups_con << SqlHelper.get_sql_like(['User.groups'], "|#{grp_id}|")
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

  rescue => evar
    Log.add_error(request, evar)
    render(:plain => 'ERROR:' + t('msg.system_error'))
  end

  #=== delete_attachment
  #
  #Deletes Attachment.
  #
  def delete_attachment
    Log.add_info(request, '')   # Not to show passwords.

    raise(RequestPostOnlyException) unless request.post?

    target_user = nil

    user_id = params[:user_id]
    zeptair_id = params[:zeptair_id]
    attachment_id = params[:attachment_id]
    SqlHelper.validate_token([user_id, zeptair_id, attachment_id])

    unless user_id.blank?
      if @login_user.admin?(User::AUTH_ZEPTAIR) or @login_user.id.to_s == user_id.to_s
        target_user = User.find(user_id)
      end
    end

    unless zeptair_id.blank?

      target_user = User.where("zeptair_id=#{zeptair_id.to_i}").first

      unless @login_user.admin?(User::AUTH_ZEPTAIR) or @login_user.id == target_user.id
        target_user = nil
      end
    end

    if target_user.nil?
      if attachment_id.blank?
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
        attach = Attachment.find(attachment_id)

        item = Item.find(attach.item_id)

        if !@login_user.admin?(User::AUTH_ZEPTAIR) and item.user_id != @login_user.id
          raise t('msg.need_to_be_owner')
        end

        if (item.xtype != Item::XTYPE_ZEPTAIR_POST)
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

    render(:plain => t('msg.delete_success'))

  rescue => evar
    Log.add_error(request, evar)
    render(:plain => 'ERROR:' + t('msg.system_error'))
  end
end
