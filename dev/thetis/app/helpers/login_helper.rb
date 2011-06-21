#
#= LoginHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about LOGIN.
#
#== Note:
#
#* 
#
module LoginHelper

  #=== self.on_login
  #
  #Does Login procedure for the specified User.
  #
  #_user_:: Login User.
  #_session_:: Session.
  #
  def self.on_login(user, session)

    return if user.nil?

    user.update_attribute(:login_at, Time.now)
    Team.check_req_to_del_for(user.id)

    session[:login_user] = user
    session[:settings] = Setting.get_for(user.id) || {}
  end
end
