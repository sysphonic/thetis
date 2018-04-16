#
#= Toy
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Toy class represents a desktop item.
#
class Toy < ApplicationRecord
  public::PERMIT_BASE = [:name, :xtype, :target_id, :address, :x, :y, :memo, :message]

  public::XTYPE_UNKNOWN = nil
  public::XTYPE_ITEM = 'item'
  public::XTYPE_COMMENT = 'comment'
  public::XTYPE_WORKFLOW = 'workflow'
  public::XTYPE_SCHEDULE = 'schedule'
  public::XTYPE_LABEL = 'label'
  public::XTYPE_POSTLABEL = 'postlabel'
  public::XTYPE_FOLDER = 'folder'

  #=== self.copy
  #
  #Copies or creates a Toy instance from the source object of each class.
  #
  #_dst_toy_:: Destination Toy instance. If nil, creates an instance.
  #_src_obj_:: Source instance.
  #return:: A Toy instance.
  #
  def self.copy(dst_toy, src_obj)

    toy = dst_toy
    toy = Toy.new if toy.nil?

    if src_obj.instance_of?(Item)

      item = src_obj
      toy.name = item.title
      toy.xtype = Toy::XTYPE_ITEM
      toy.target_id = item.id
      toy.address = ApplicationHelper.url_for(:controller => 'items', :action => 'show', :id => item.id)
      toy.memo = item.summary
      toy.message = ''
      toy.created_at = ''
      toy.updated_at = item.updated_at

    elsif src_obj.instance_of?(Comment)

      comment = src_obj
      if comment.xtype == Comment::XTYPE_MSG
        xtype_name = ''
      else
        xtype_name = comment.get_xtype_name + ': '
        if comment.xtype == Comment::XTYPE_APPLY
          xtype_name << Item.get_title(comment.item_id)
        end
      end
      comment_message = (comment.message.nil?)?'':comment.message
      toy.name = xtype_name + comment_message
      toy.xtype = Toy::XTYPE_COMMENT
      toy.target_id = comment.id
      toy.address = ApplicationHelper.url_for(:controller => 'items', :action => 'show', :id => comment.item_id, :a_name => "comment_#{comment.id}")
      toy.memo = ''
      toy.message = xtype_name + comment_message
      toy.created_at = ''
      toy.updated_at = comment.updated_at

    elsif src_obj.instance_of?(Workflow)

      workflow = src_obj
      toy.name = Item.get_title(workflow.item_id)
      toy.xtype = Toy::XTYPE_WORKFLOW
      toy.target_id = workflow.id
      toy.address = ApplicationHelper.url_for(:controller => 'items', :action => 'show', :id => workflow.item_id)
      toy.memo = workflow.item.summary
      toy.message = ''
      toy.created_at = ''
      toy.updated_at = workflow.item.updated_at

    elsif src_obj.instance_of?(Schedule)

      schedule = src_obj
      toy.name = schedule.title
      toy.xtype = Toy::XTYPE_SCHEDULE
      toy.target_id = schedule.id
      toy.address = ApplicationHelper.url_for(:controller => 'schedules', :action => 'show', :id => schedule.id, :from => 'desktop')
      toy.memo = ''
      toy.message = ''
      toy.created_at = schedule.created_at
      toy.updated_at = schedule.updated_at

    elsif src_obj.instance_of?(Folder)

      folder = src_obj
      toy.name = folder.name
      toy.xtype = Toy::XTYPE_FOLDER
      toy.target_id = folder.id
      toy.address = ApplicationHelper.url_for(:controller => 'items', :action => 'bbs', :folder_id => folder.id)
      toy.memo = ''
      toy.message = ''
      toy.created_at = ''#folder.created_at
      toy.updated_at = ''#folder.updated_at

    end

    return toy
  end

  #=== self.get_for_user
  #
  #Gets Toys (desktop items) of specified User.
  #
  #_user_:: The target User. If nil, returns empty array.
  #return:: Toys array (desktop items) of specified User.
  #
  def self.get_for_user(user)

    return [] if user.nil?

    toys = Toy.where("user_id=#{user.id}").to_a
    deleted_arr = []

    return [] if toys.nil?

    toys.each do |toy|
      case toy.xtype
        when Toy::XTYPE_ITEM
          item = Item.find_by_id(toy.target_id)
          if item.nil?
            deleted_arr << toy
            next
          end
          Toy.copy(toy, item)

        when Toy::XTYPE_COMMENT
          comment = Comment.find_by_id(toy.target_id)
          if comment.nil?
            deleted_arr << toy
            next
          end
          Toy.copy(toy, comment)

        when Toy::XTYPE_WORKFLOW
          workflow = Workflow.find_by_id(toy.target_id)
          if workflow.nil?
            deleted_arr << toy
            next
          end
          Toy.copy(toy, workflow)

        when Toy::XTYPE_SCHEDULE
          schedule = Schedule.find_by_id(toy.target_id)
          if schedule.nil?
            deleted_arr << toy
            next
          end
          Toy.copy(toy, schedule)

        when Toy::XTYPE_FOLDER
          folder = Folder.find_by_id(toy.target_id)
          if folder.nil?
            deleted_arr << toy
            next
          end
          Toy.copy(toy, folder)
      end
    end

    deleted_arr.each do |toy|
      toys.delete(toy)
      Toy.destroy(toy.id)
    end

    return toys
  end

  #=== self.on_desktop?
  #
  #Gets if specified object is on the desktop or not.
  #
  #_user_:: Target User.
  #_xtype_:: xtype-attribute of the object.
  #_target_id_:: Id of the target object.
  #return:: If specified object is on the desktop or not.
  #
  def self.on_desktop?(user, xtype, target_id)

    return false if user.nil? or xtype.nil? or target_id.nil?

    SqlHelper.validate_token([xtype, target_id])

    con = "(user_id=#{user.id}) and (xtype='#{xtype}') and (target_id=#{target_id.to_i})"

    begin
      toy = Toy.where(con).first
    rescue => evar
      Log.add_error(nil, evar)
    end

    return (!toy.nil?)
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
  def self.get_feeds(user, root_url, users_cache=nil)

    entries = []

    sql = "select * from toys where user_id=#{user.id} and xtype='#{Toy::XTYPE_POSTLABEL}'"

    Toy.find_by_sql(sql).each do |toy|
      feed_entry  = FeedEntry.new
      feed_entry.created_at      = toy.created_at
      feed_entry.updated_at      = toy.updated_at
      feed_entry.link            = root_url + ApplicationHelper.url_for(:controller => 'frames', :action => 'index', :default => ApplicationHelper.url_for(:controller => 'desktop', :action => 'show', :id => ''))
      # Updating position of PostLabel causes renew its timestamp!
      #   FeedEntry.create_guid(toy, ApplicationHelper.get_timestamp(toy))
      feed_entry.guid            = FeedEntry.create_guid(toy, nil)
      feed_entry.content         = (toy.message.nil?)?'':(toy.message.gsub(/^(.{0,200}).*/m,"\\1"))
      feed_entry.title           = '['+I18n.t('postlabel.name')+'] '+ I18n.t('postlabel.from') + User.get_name(toy.posted_by, users_cache)

      if (YamlHelper.get_value($thetis_config, 'feed.feed_content', nil) == '1') \
          and !toy.message.nil?
        feed_entry.content_encoded = "<![CDATA[#{toy.message}]]>"
      end
      entries << feed_entry
    end
    return entries
  end
end
