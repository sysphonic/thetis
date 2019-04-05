#
#= LoginHelper
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
module LoginHelper

  #=== self.on_login
  #
  #Does Login procedure for the specified User.
  #
  #_user_:: Login User.
  #_session_:: Session.
  #return:: Login User.
  #
  def self.on_login(user, session)

    return nil if user.nil?

    user.update_attribute(:login_at, Time.now)
    Team.check_req_to_del_for(user.id)

    session[:login_user_id] = user.id
    session[:settings] = Setting.get_for(user.id) || {}

    return user
  end
end
