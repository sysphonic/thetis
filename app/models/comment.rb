#
#= Comment
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Comment represents each response to an Item, and has partly different means by Item's type(=Item.xtype).
#
class Comment < ApplicationRecord
  public::PERMIT_BASE = [:user_id, :item_id, :message, :xtype]

  belongs_to(:item)

  has_many(:attachments, ->(rec) {order('attachments.xorder asc')}, {:dependent => :destroy})

  public::XTYPE_MSG = 'msg'
  public::XTYPE_ACK = 'ack'
  public::XTYPE_NAK = 'nak'
  public::XTYPE_APPLY = 'apply'
  public::XTYPE_DIST_ACK = 'dist_ack'

  #=== self.get_xtype_name
  #
  #Gets String which represents specified xtype.
  #
  #return:: String which represents specified xtype.
  #
  def self.get_xtype_name(xtype)

    xtype_names = {
      XTYPE_MSG => I18n.t('comment.xtype.msg'),
      XTYPE_ACK => I18n.t('comment.xtype.ack'),
      XTYPE_NAK => I18n.t('comment.xtype.nak'),
      XTYPE_APPLY => I18n.t('comment.xtype.apply'),
      XTYPE_DIST_ACK => I18n.t('comment.xtype.dist_ack'),
    }
    return xtype_names[xtype]
  end

  #=== get_xtype_name
  #
  #Gets String which represents xtype of the Comment.
  #
  #return:: String which represents xtype of the Comment.
  #
  def get_xtype_name

    return Comment.get_xtype_name(self.xtype)
  end

  #=== copy
  #
  #Copies the Comment.
  #
  #_item_id_:: New Item-ID.
  #return:: Instance of the copied Comment.
  #
  def copy(item_id)

    comment = Comment.new
    comment.user_id = self.user_id
    comment.message = self.message
    comment.updated_at = self.updated_at
    comment.xtype = self.xtype
    comment.attachments = self.attachments
    comment.item_id = item_id

    class << comment
      def record_timestamps; false; end
    end

    comment.save!

    class << comment
      remove_method :record_timestamps
    end

    return comment
  end

  #=== attachments_without_content
  #
  #Gets Attachments related to this Comment without content.
  #
  #return:: Array of Attachments without content.
  #
  def attachments_without_content

    return [] if self.id.nil?

    sql = 'select id, title, memo, name, size, content_type, comment_id, xorder, location from attachments'
    sql << ' where comment_id=' + self.id.to_s
    sql << ' order by xorder ASC'
    begin
      attachments = Attachment.find_by_sql(sql)
    rescue => evar
      Log.add_error(nil, evar)
    end
    return (attachments || [])
  end

  #=== self.get_toys
  #
  #Gets Toys (desktop items) of specified User.
  #
  #_user_:: Target User.
  #return:: Toys (desktop items) of specified User.
  #
  def self.get_toys(user)

    toys = []
    sql = CommentsHelper.get_list_sql(user)
    unless sql.nil?
      Comment.find_by_sql(sql).each do |comment|
        toys << Toy.copy(nil, comment)
      end
    end

    return toys
  end

  #=== self.get_feeds
  #
  #Gets Web feeds of specified User.
  #
  #_user_:: Target User.
  #_root_url_:: Root URL.
  #_users_cache_:: Hash to accelerate response. {user_id, user_name}
  #return:: Array of FeedEntry.
  #
  def self.get_feeds(user, root_url, users_cache = nil)

    entries = []
    sql = CommentsHelper.get_list_sql(user)

    return entries if sql.nil?

    Comment.find_by_sql(sql).each do |comment|
      feed_entry  = FeedEntry.new
      feed_entry.updated_at  = comment.updated_at
      feed_entry.link        = root_url + ApplicationHelper.url_for(:controller => 'frames', :action => 'index', :default => ApplicationHelper.url_for(:controller => 'items', :action => 'show', :id => comment.item_id, :a_name => "comment_#{comment.id}"))
      feed_entry.guid        = FeedEntry.create_guid(comment, ApplicationHelper.get_timestamp(comment))
      feed_entry.content     = (comment.message.nil?)?'':(comment.message.gsub(/^(.{0,200}).*/m,"\\1"))
      xtype_name = comment.get_xtype_name
      feed_entry.title           = '['+I18n.t('comment.name')+'] '+Item.get_title(comment.item_id)+': '+ xtype_name + I18n.t('comment.from') + User.get_name(comment.user_id, users_cache)

      if (YamlHelper.get_value($thetis_config, 'feed.feed_content', nil) == '1') \
          and !comment.message.nil?
        feed_entry.content_encoded = "<![CDATA[#{comment.message}]]>"
      end
      entries << feed_entry
    end
    return entries
  end
end
