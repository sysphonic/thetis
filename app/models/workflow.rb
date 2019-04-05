#
#= Workflow
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Workflow is related to Item whose xtype attribute is XTYPE_WORKFLOW, and
#has information of its status and users to require confirmation.
#
class Workflow < ApplicationRecord
  public::PERMIT_BASE = [:status, :issued_at]

  belongs_to(:item)

  public::STATUS_NOT_APPLIED = 'N/A'
  public::STATUS_NOT_ISSUED = 'not_issued'
  public::STATUS_ACTIVE = 'active'
  public::STATUS_ACCEPTED = 'accepted'
  public::STATUS_DENIED = 'denied'

  #=== self.decided_inbox
  #
  #Gets the name of the inbox Folder for finished Workflows.
  #
  #return:: Name of the inbox Folder for finished Workflows.
  #
  def self.decided_inbox
    I18n.t('workflow.decided_inbox')
  end

  #=== get_status_name
  #
  #Gets String which represents status of the Workflow.
  #
  #return:: String which represents status of the Workflow.
  #
  def get_status_name
    case self.status
      when STATUS_NOT_APPLIED
        return I18n.t('workflow.status.not_applied')
      when STATUS_NOT_ISSUED
        return I18n.t('workflow.status.not_issued')
      when STATUS_ACTIVE
        return I18n.t('workflow.status.active')
      when STATUS_ACCEPTED
        return I18n.t('workflow.status.accepted')
      when STATUS_DENIED
        return I18n.t('workflow.status.denied')
    end
  end

  #=== decided?
  #
  #Checks if the Workflow has been decided.
  #
  #return:: true if the Workflow has been decided, false otherwise.
  #
  def decided?
    return (self.status == STATUS_DENIED or self.status == STATUS_ACCEPTED)
  end

  #=== accepted?
  #
  #Checks if the Workflow has been accepted.
  #
  #return:: true if the Workflow has been accepted, false otherwise.
  #
  def accepted?
    return (self.status == STATUS_ACCEPTED)
  end

  #=== denied?
  #
  #Checks if the Workflow has been denied.
  #
  #return:: true if the Workflow has been denied, false otherwise.
  #
  def denied?
    return (self.status == STATUS_DENIED)
  end

  #=== update_status
  #
  #Updates status of this Workflow.
  #
  #return:: true if status has been changed, false otherwise.
  #
  def update_status

    old_status = self.status

    unless self.decided?
      expected_users = self.get_current_expected

      if expected_users.nil?
        self.update_attribute(:status, Workflow::STATUS_DENIED)
        last_nak = self.get_last_nak
        unless last_nak.nil?
          self.update_attribute(:decided_at, last_nak.updated_at)
        end
      elsif  expected_users.empty?
        self.update_attribute(:status, Workflow::STATUS_ACCEPTED)
        last_ack = self.get_last_ack
        unless last_ack.nil?
          self.update_attribute(:decided_at, last_ack.updated_at)
        end
      end
    end

    return (old_status != self.status)
  end

  #=== copy
  #
  #Copies the Workflow.
  #
  #_user_id_:: New owner's ID.
  #_item_id_:: New Item-ID.
  #return:: Instance of the copied Workflow.
  #
  def copy(user_id, item_id)
    workflow = Workflow.new
    workflow.users = self.users
    workflow.status = self.status
    workflow.issued_at = self.issued_at
    workflow.decided_at = self.decided_at
    if (self.original_by.nil? and self.user_id != 0)
      workflow.original_by = self.user_id
    else
      workflow.original_by = self.original_by
    end
    workflow.item_id = item_id
    workflow.user_id = user_id

    workflow.save!

    return workflow
  end

  #=== distribute_cc
  #
  #Distributes carbon-copies of the finished Workflow.
  #
  def distribute_cc

    self.get_target_users.each do |user_id|
      next if (self.user_id == user_id)

      decided_inbox = WorkflowsHelper.get_decided_inbox(user_id)
      copied_item = self.item.copy(user_id, decided_inbox.id)
    end
  end

  #=== get_orders
  #
  #Gets Workflow orders.
  #
  #return:: Order array of hash which has User-ID as key and User name as value.
  #ex.
  #[0] (Order-1) = {'1' => 'Team Leader A', '2' => 'Team Leader B'}
  #[1] (Order-2) = {'3' => 'Group Leader'}
  #[2] (Order-3) = {'4' => 'Manager'}
  #
  def get_orders

    orders = []

    return orders if self.users.nil?

    self.users.split(',').each do |order|

      orders << {}
      users_a = ApplicationHelper.attr_to_a(order)
      users_a.each do |user_id|
        orders.last[user_id.to_i] = User.get_name(user_id)
      end
    end
    return orders
  end

  #=== get_target_users
  #
  #Gets all target Users of this Workflow.
  #
  #return:: Array of User-ID of the target Users.
  #
  def get_target_users

    users = []

    self.get_orders.each do |user_hash|

      user_ids = user_hash.keys

      users = users + user_ids unless user_ids.nil?
    end

    users.compact!

    return users
  end

  #=== get_current_expected
  #
  #Gets current response-expected Users.
  #
  #return:: Array of current response-expected User-IDs. If denied or not issued, returns nil. If accepted returns empty array.
  #
  def get_current_expected

    return nil if (self.item.nil? or self.status != STATUS_ACTIVE)

    orders = self.get_orders

    if self.item.comments.nil?
      if orders.empty?
        return nil
      else
        return orders.first.keys
      end

    else

      last_nak = self.get_last_nak

      if last_nak.nil?

        return _get_current_expected(orders, self.item.comments)

      else

        nak_order_idx = self.get_order_idx last_nak.user_id

        if (nak_order_idx <= 0)
          # Denied
          return nil
        else

          comments = self.item.comments
          comments.delete_if { |comment|
            (comment.updated_at <= last_nak.updated_at)
          }

          (nak_order_idx-1).times do
            orders.shift
          end

          return _get_current_expected(orders, comments)
        end
      end
    end

  end

 private
  #=== _get_current_expected
  #
  #Gets current response-expected Users.
  #
  #return:: Array of current response-expected User-IDs.
  #
  def _get_current_expected(orders, comments)

    orders.each do |user_hash|

      users = user_hash.keys

      if (users.nil? or users.empty?)

        next

      else

        self.item.comments.each do |comment|
          next unless comment.xtype == Comment::XTYPE_ACK
          users.delete comment.user_id
        end

        if users.empty?
          next
        else
          return users
        end

      end
    end

    # Accepted
    return []
  end

 public
  #=== get_last_comment
  #
  #Gets last Comment related to this Workflow.
  #
  #_xtype_:: Target xtype, if required to specify.
  #return:: Last Comment, or nil if not found.
  #
  def get_last_comment(xtype = nil)

    return nil if self.item.nil?

    if self.item.comments.nil?
      return nil
    else

      last_comment = nil

      self.item.comments.each do |comment|

        next if (xtype != nil and comment.xtype != xtype)

        if last_comment.nil?
          last_comment = comment
        else
          if (last_comment.updated_at < comment.updated_at)
            last_comment = comment
          end
        end
      end
    end

    return last_comment
  end

  #=== get_last_nak
  #
  #Gets last NAK Comment.
  #
  #return:: Last NAK Comment, or nil if not found.
  #
  def get_last_nak

    return self.get_last_comment(Comment::XTYPE_NAK)
  end

  #=== get_last_ack
  #
  #Gets last ACK Comment.
  #
  #return:: Last ACK Comment, or nil if not found.
  #
  def get_last_ack

    return self.get_last_comment(Comment::XTYPE_ACK)
  end

  #=== get_order_idx
  #
  #Gets order index to which specified User belongs.
  #
  #_user_id_:: Target User-ID.
  #return:: Order index to which specified User belongs. If not found, returns -1.
  #
  def get_order_idx(user_id)

    idx = 0

    self.get_orders.each do |user_hash|

      if user_hash.keys.include?(user_id)
        return idx
      end
      idx += 1
    end

    return -1
  end

  #=== get_received_list
  #
  #Gets list of received Workflows of specified User.
  #
  #_user_id_:: Target User-ID.
  #_order_by_:: Order. ex. 'id ASC'
  #return:: List of received Workflows.
  #
  def self.get_received_list(user_id, order_by=nil)

    con = "(status='#{STATUS_ACTIVE}') and " + SqlHelper.get_sql_like([:users], "|#{user_id}|")
    return Workflow.where(con).order(order_by).to_a
  end

  #=== expected_list_for
  #
  #Gets list of received Workflows expected to handle currently.
  #
  #_user_id_:: Target User-ID.
  #return:: List of Workflows.
  #
  def self.expected_list_for(user_id)

    workflows = []
    received_wfs = Workflow.get_received_list(user_id)
    unless received_wfs.nil?
      received_wfs.each do |workflow|
        item = workflow.item
        expected_users = workflow.get_current_expected
        if (!expected_users.nil? and expected_users.include?(user_id))
          workflows << workflow
        end
      end
    end

    return workflows
  end

  #=== self.get_toys
  #
  #Gets Toys (desktop items) of specified User.
  #
  #_user_:: The target User.
  #return:: Toys (desktop items) of specified User.
  #
  def self.get_toys(user)

    return [] if user.nil?

    toys = []

    workflows = Workflow.expected_list_for user.id

    workflows.each do |workflow|
      toys << Toy.copy(nil, workflow)
    end

    return toys
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
  def self.get_feeds(user, root_url, users_cache = nil)

    entries = []

    return entries if user.nil?

    workflows = Workflow.expected_list_for(user.id)

    workflows.each do |workflow|
      feed_entry  = FeedEntry.new
      feed_entry.created_at      = workflow.item.created_at
      feed_entry.updated_at      = workflow.item.updated_at
      feed_entry.link            = root_url + ApplicationHelper.url_for(:controller => 'frames', :action => 'index', :default => ApplicationHelper.url_for(:controller => 'items', :action => 'show', :id => workflow.item_id))
      feed_entry.guid            = FeedEntry.create_guid(workflow, ApplicationHelper.get_timestamp(workflow.item))
      feed_entry.content         = (workflow.item.summary.nil?)?'':(workflow.item.summary.gsub(/^(.{0,200}).*/m,"\\1"))
      feed_entry.title           = '['+I18n.t('workflow.name')+'] '+Item.get_title(workflow.item_id) + I18n.t('workflow.from') + User.get_name(workflow.item.user_id, users_cache)

      if (YamlHelper.get_value($thetis_config, 'feed.feed_content', nil) == '1') \
          and !workflow.item.description.nil?
        feed_entry.content_encoded = "<![CDATA[#{workflow.item.description}]]>"
      end
      entries << feed_entry
    end
    return entries
  end

  #=== self.get_comments_for
  #
  #Gets comments for specified User in the specified order.
  #
  #_orders_:: Array of orders returned from get_orders().
  #_comments_:: Array of Comments for a Workflow.
  #_user_id_:: Target User.
  #_order_:: Order index to which the specified User belongs.
  #return:: Comments for specified User.
  #
  def self.get_comments_for(orders, comments, user_id, order)

    return nil if (orders.nil? or comments.nil?)

    user_comments = comments.select{ |comment|
                        comment.user_id == user_id
                    }
    return nil if user_comments.nil?

    order_idx = 0
    user_cnt = 0
    order_cnt = 0
    orders.each do |user_hash|
      if user_hash.keys.include?(user_id)
        if (order_cnt < order)
          order_idx += 1
        end
        user_cnt += 1
      end
      order_cnt += 1
    end

    return [] if (user_cnt == 0)

    num = user_comments.length / user_cnt
    num += 1 if (user_comments.length % user_cnt) >= (order_idx + 1)

    arr = []
    num.times do |x|
      arr << user_comments[order_idx + x * user_cnt]
    end
    return arr
  end
end
