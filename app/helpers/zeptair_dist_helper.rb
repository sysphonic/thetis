#
#= ZeptairDistHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about Zeptair Distribution feature.
#
#== Note:
#
#* 
#
module ZeptairDistHelper

  public::ACK_CLASS_SEP = '#'
  public::ACK_ID_SEP = '='
  public::ACK_TS_SEP = ':'

  public::STATUS_NO_REPLY = 'no_reply'
  public::STATUS_REPLIED = 'replied'
  public::STATUS_COMPLETE = 'complete'

  public::ENTRY_STATUS_SAVED = 'saved'
  public::ENTRY_STATUS_EXECUTED = 'executed'
  public::ENTRY_STATUS_ERROR = 'error'

  public::MARK_NA = '--'


  #=== self.get_ack_entry_for
  #
  #Gets the master ACK entry for the specified record.
  #
  #_target_:: Target record.
  #return:: Master ACK entry for the specified record.
  #
  def self.get_ack_entry_for(target)

    return nil if target.nil? or target.updated_at.nil?

    completed_status = ''
    if target.instance_of?(Attachment)
      completed_status = ENTRY_STATUS_SAVED
    elsif target.instance_of?(ZeptairCommand)
      completed_status = ENTRY_STATUS_EXECUTED
    end
    timestamp = ApplicationHelper.get_timestamp(target)
    return "#{target.class}#{ZeptairDistHelper::ACK_CLASS_SEP}#{target.id}#{ACK_ID_SEP}#{timestamp}#{ZeptairDistHelper::ACK_TS_SEP}#{completed_status}"
  end

  #=== self.get_comment_of
  #
  #Gets the reply of the specified User to the Distribution.
  #
  #_item_id_:: Item-ID of Zeptair Distribution.
  #_user_id_:: Target User-ID.
  #return:: Reply as Comment.
  #
  def self.get_comment_of(item_id, user_id)

    SqlHelper.validate_token([item_id, user_id])
    begin
      comment = Comment.where("(user_id=#{user_id}) and (item_id=#{item_id}) and (xtype='#{Comment::XTYPE_DIST_ACK}')").first
    rescue => evar
      Log.add_error(nil, evar)
    end

    return comment
  end

  #=== self.get_ack_array_of
  #
  #Gets the ACK entries of the specified Comment.
  #
  #_comment_:: Target Comment.
  #return:: Array of the ACK entries.
  #
  def self.get_ack_array_of(comment)

    return nil if comment.nil?

    if comment.message.nil?
      entries = []
    else
      entries = comment.message.split("\n")
    end

    return entries
  end

  #=== self.completed_ack_message
  #
  #Gets the message which Users should reply currently
  #when completely distributed.
  #
  #_item_id_:: Target Item-ID.
  #return:: Master ACK message when completely distributed.
  #
  def self.completed_ack_message(item_id)

    SqlHelper.validate_token([item_id])

    msg = ''

    sql = 'select id, updated_at from attachments'
    sql << " where item_id=#{item_id} order by id ASC"
    begin
      attachments = Attachment.find_by_sql(sql)
    rescue => evar
      Log.add_error(nil, evar)
    end

    unless attachments.nil?
      attachments.each do |attach|
        msg << ZeptairDistHelper.get_ack_entry_for(attach) + "\n"
      end
    end

    sql = 'select id, updated_at from zeptair_commands'
    sql << " where item_id=#{item_id} order by id ASC"
    begin
      zept_cmds = ZeptairCommand.find_by_sql(sql)
    rescue => evar
      Log.add_error(nil, evar)
    end

    unless zept_cmds.nil?
      zept_cmds.each do |zept_cmd|
        msg << ZeptairDistHelper.get_ack_entry_for(zept_cmd) + "\n"
      end
    end

    return msg
  end

  #=== self.count_ack_users
  #
  #Gets the number of ACK messages to the specified Distribution Item.
  #
  #_item_id_:: Target Item-ID.
  #return:: The number of ACK messages to the specified Distribution Item.
  #
  def self.count_ack_users(item_id)
    SqlHelper.validate_token([item_id])
    return Comment.where("(item_id=#{item_id}) and (xtype='#{Comment::XTYPE_DIST_ACK}')").count
  end

  #=== self.count_completed_users
  #
  #Gets the number of completed users of the specified Distribution Item.
  #
  #_item_id_:: Target Item-ID.
  #return:: The number of completed users of the specified Distribution Item.
  #
  def self.count_completed_users(item_id)
    SqlHelper.validate_token([item_id])
    ack_msg = ZeptairDistHelper.completed_ack_message(item_id)
    return Comment.where("(item_id=#{item_id}) and (xtype='#{Comment::XTYPE_DIST_ACK}') and (message='#{ack_msg}')").count
  end

  #=== self.get_feeds
  #
  #Gets Web feeds of specified User.
  #
  #_user_:: The target User.
  #_root_url_:: Root URL.
  #_admins_:: Array of admin names to be accepted by the client.
  #_users_cache_:: Hash to accelerate response. {user_id, user_name}
  #return:: Array of FeedEntry.
  #
  def self.get_feeds(user, root_url, admins, users_cache=nil)

    entries = []
    user_obj_cache = {}

    add_con = "(Item.xtype='#{Item::XTYPE_ZEPTAIR_DIST}')"

    unless admins.nil? or admins.empty?
      SqlHelper.validate_token([admins])

      admin_ids = []
      admins.each do |admin_name|
        begin
          admin_user = User.where("name='#{admin_name}'").first
        rescue
        end
        unless admin_user.nil?
          admin_ids << admin_user.id
          user_obj_cache[admin_user.id] = admin_user
        end
      end
      unless admin_ids.empty?
        add_con << "and (Item.user_id in (#{admin_ids.join(',')}))"
      end
    end

    sql = ItemsHelper.get_list_sql(user, nil, nil, nil, nil, 10, false, add_con)
    Item.find_by_sql(sql).each do |item|
      owner = User.find_with_cache(item.user_id, user_obj_cache)
      next if owner.nil?

      feed_entry  = FeedEntry.new
      feed_entry.created_at      = item.created_at
      feed_entry.updated_at      = item.updated_at
      feed_entry.author          = item.disp_registered_by(users_cache, user_obj_cache) + ':' + owner.name
      feed_entry.link            = root_url + ApplicationHelper.url_for(:controller => 'frames', :action => 'index', :default => ApplicationHelper.url_for(:controller => 'items', :action => 'show', :id => item.id))
      feed_entry.guid            = FeedEntry.create_guid(item, ApplicationHelper.get_timestamp(item))
      feed_entry.title           = item.title
      content = nil
      zept_cmd = item.zeptair_command
      unless zept_cmd.nil?
        if zept_cmd.enabled
          content = '<#ID:' + zept_cmd.id.to_s + "\n"
          content << '<#Timestamp:' + ApplicationHelper.get_timestamp(zept_cmd) + "\n"
          if zept_cmd.confirm_exec
            content << '<#ConfirmExecute' + "\n"
          end
          content << zept_cmd.commands
        end
      end
      feed_entry.content         = content
      feed_entry.content_encoded = "<![CDATA[#{item.description}]]>"

      attachments = item.attachments_without_content
      if !attachments.nil? and attachments.length > 0
        feed_entry.enclosures = []
        attachments.each do |attach|
          feed_enclosure = FeedEntry::FeedEnclosure.new
          feed_enclosure.url = root_url + ApplicationHelper.url_for(:controller => 'items', :action => 'get_attachment', :id => attach.id, :ts => ApplicationHelper.get_timestamp(attach))
          feed_enclosure.type = attach.content_type
          feed_enclosure.length = attach.size
          feed_enclosure.id = attach.id
          feed_enclosure.name = attach.name
          feed_enclosure.title = attach.title
          feed_enclosure.updated_at = ApplicationHelper.get_timestamp(attach)
          feed_enclosure.digest_md5 = attach.digest_md5
          feed_entry.enclosures << feed_enclosure
        end
      end
      entries << feed_entry
    end
    return entries
  end
end
