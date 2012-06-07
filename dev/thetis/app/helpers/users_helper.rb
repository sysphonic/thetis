#
#= UsersHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about Users.
#
#== Note:
#
#*
#
module UsersHelper

  require 'digest/md5'

  #=== self.get_initialized_user
  #
  #Gets a new User initialized with the specified attributes.
  #
  #_attrs_:: Attributes to apply to the new User.
  #return:: New User initialized with the specified attributes.
  #
  def self.get_initialized_user(attrs=nil)

    user = User.new(attrs)

    user.created_at = Time.now

    # Official title and order to display
    titles = User.get_config_titles
    if !titles.nil? and titles.include?(user.title)
      user.xorder = titles.index(user.title)
    end

    return user
  end

  #=== self.get_groups_info
  #
  #Gets Groups information of the specified User.
  #
  #_user_id_:: Target User-ID.
  #_user_groups_:: Hash used to pop-up User Groups information.
  #_users_cache_:: Cache with {User-ID, User name}.
  #_user_obj_cache_:: Cache with {User-ID, User}.
  #_groups_cache_:: Cache with {Group-ID, Group path}.
  #_group_obj_cache_:: Cache with {Group-ID, Group}.
  #return:: Array of [User name, Group-IDs, User's figure].
  #
  def self.get_groups_info(user_id, user_groups, users_cache, user_obj_cache, groups_cache, group_obj_cache)

    user = User.find_with_cache(user_id, user_obj_cache)
    u_groups = []
    unless user.nil?
      user.get_groups_a(false, group_obj_cache).each do |group_id|
        if user_groups[group_id].nil?
          user_groups[group_id] = Group.get_path(group_id, groups_cache, group_obj_cache)
        end
        u_groups << group_id
      end
    end
    user_name = User.get_name(user_id, users_cache, user_obj_cache)

    return [user_name, u_groups, (user.nil?)?(nil):user.get_figure]
  end

  #=== self.generate_password
  #
  #Generates password.
  #
  #return:: Password.
  #
  def self.generate_password

    chars = ('a'..'z').to_a + ('1'..'9').to_a
    newpass = Array.new(8, '').collect{chars[rand(chars.size)]}.join

    return newpass
  end

  #=== self.generate_digest_pass
  #
  #Generates digest of the password.
  #
  #_user_name_:: User name.
  #_password_:: Password.
  #return:: Digest of the password.
  #
  def self.generate_digest_pass(user_name, password)

    return Digest::MD5.hexdigest([user_name, THETIS_REALM, password].join(':'))
  end

  #=== self.send_notification
  #
  #Sends notification to specified Users.
  #
  #_users_hash_:: Users hash which has User-ID as key and flag to notify as value.
  #_message_:: Message of notification. The first line will be subject of E-mail, and the rest body.
  #_root_url_:: Root URL.
  #return:: Count of sent notifications.
  #
  def self.send_notification(users_hash, message, root_url)

    count = 0

    if users_hash.nil?
      return count
    end

    lines = message.strip.to_a
    subject = lines[0].strip
    if lines.length > 1
      lines.shift
      body = lines.join
    else
      body = subject
    end

    users_hash.each do |user_id, value|
      if value == '1'

        begin
          user = User.find(user_id)

          NoticeMailer.deliver_notice(user, subject, body, root_url)
          count += 1
        rescue => evar
          Log.add_error(nil, evar)
        end
      end
    end

    return count
  end
end
