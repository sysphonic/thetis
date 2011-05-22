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

  #=== self.generate_htpasswd_pass
  #
  #Generates password for the htpasswd file for Basic Authentication for RSS.
  #<LEGACY CODE>
  #
  #_user_name_:: User name.
  #_password_:: Password.
  #return:: Encrypted password.
  #
  def self.generate_htpasswd_pass(user_name, password)

    return Digest::MD5::hexdigest([user_name, 'Thetis', password] * ":")
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
        rescue StandardError => err
          Log.add_error(nil, err)
        end
      end
    end

    return count
  end
end
