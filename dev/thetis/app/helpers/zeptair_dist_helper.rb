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

  public::ACK_ID_SEP = '='
  public::ACK_TIMESTAMP_FORM = '%Y%m%d_%H%M%S'

  public::STATUS_NO_REPLY = 'no_reply'
  public::STATUS_REPLIED = 'replied'
  public::STATUS_COMPLETE = 'complete'

  public::MARK_NA = '--'


  #=== self.get_ack_entry_for
  #
  #Gets the master ACK entry for the specified Attachment.
  #
  #_attach_:: Target Attachment.
  #return:: Master ACK entry for the specified Attachment.
  #
  def self.get_ack_entry_for(attach)

    return nil if attach.nil? or attach.updated_at.nil?

    timestamp = attach.updated_at.utc.strftime(ACK_TIMESTAMP_FORM)
    return "#{attach.id}#{ACK_ID_SEP}#{timestamp}"
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

    begin
      comment = Comment.find(:first, :conditions => ['user_id=? and item_id=? and xtype=?', user_id, item_id, Comment::XTYPE_DIST_ACK])
    rescue StandardError => err
      Log.add_error(nil, err)
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

    sql = 'select id, updated_at from attachments'
    sql << " where item_id=#{item_id}"
    sql << ' order by id ASC'
    begin
      attachments = Attachment.find_by_sql(sql)
    rescue StandardError => err
      Log.add_error(nil, err)
    end

    return nil if attachments.nil?

    msg = ''
    attachments.each do |attach|
      entry = ZeptairDistHelper.get_ack_entry_for(attach)
      msg << "#{entry}\n"
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
    return Comment.count(:id, :conditions => ['item_id=? and xtype=?', item_id, Comment::XTYPE_DIST_ACK])
  end

  #=== self.count_completed_users
  #
  #Gets the number of completed users of the specified Distribution Item.
  #
  #_item_id_:: Target Item-ID.
  #return:: The number of completed users of the specified Distribution Item.
  #
  def self.count_completed_users(item_id)
    ack_msg = ZeptairDistHelper.completed_ack_message(item_id)
    return Comment.count(:id, :conditions => ['item_id=? and xtype=? and message=?', item_id, Comment::XTYPE_DIST_ACK, ack_msg])
  end

  #=== self.get_feeds
  #
  #Gets Web feeds of specified User.
  #
  #_user_:: The target User.
  #_root_url_:: Root URL.
  #_users_cache_:: Hash to accelerate response. {user_id, user_name}
  #return:: Array of FeedEntry.
  #
  def self.get_feeds(user, root_url, users_cache=nil)

    entries = []

    add_con = "(Item.xtype='#{Item::XTYPE_ZEPTAIR_DIST}')"
    sql = ItemsHelper.get_list_sql(user, nil, nil, nil, nil, 10, false, add_con)
    Item.find_by_sql(sql).each do |item|
      feed_entry  = FeedEntry.new
      feed_entry.created_at      = item.created_at
      feed_entry.updated_at      = item.updated_at
      feed_entry.author          = item.disp_registered_by(users_cache)
      feed_entry.link            = root_url + ApplicationHelper.url_for(:controller => 'frames', :action => 'index', :default => ApplicationHelper.url_for(:controller => 'items', :action => 'show', :id => item.id))
      feed_entry.guid            = FeedEntry.create_guid(item, ApplicationHelper.get_timestamp(item))
      feed_entry.title           = '['+Item.human_name+'] '+item.title
      feed_entry.content     = (item.summary.nil?)?'(No summary)':(item.summary.gsub(/^(.{0,200}).*/m,"\\1"))
      if $thetis_config[:feed]['feed_content'] == '1' and !item.description.nil?
        feed_entry.content << "\n#{item.description}"
        feed_entry.content_encoded = "<![CDATA[#{item.description}]]>"
      end

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
          timestamp = attach.updated_at.utc.strftime(ACK_TIMESTAMP_FORM)
          feed_enclosure.updated_at = timestamp
          feed_enclosure.digest_md5 = attach.digest_md5
          feed_entry.enclosures << feed_enclosure
        end
      end
      entries << feed_entry
    end
    return entries
  end
end
