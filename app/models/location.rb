#
#= Location
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class Location < ApplicationRecord
  public::PERMIT_BASE = [:group_id, :x, :y, :memo]

  #=== self.get_for
  #
  #Gets Location of the specified User.
  #
  #_user_:: Target User.
  #return:: Location of the specified User.
  #
  def self.get_for(user)

    location = Location.where("user_id=#{user.id}").first

    if (!location.nil? and location.expired?)
      location.destroy
      location = nil
    end

    return location
  end

  #=== self.get_for_group
  #
  #Gets Locations related to the specified Group.
  #
  #_group_id_:: Target Group-ID.
  #return:: Locations related to the specified Group.
  #
  def self.get_for_group(group_id)

    SqlHelper.validate_token([group_id])
    if group_id.nil?
      con = 'group_id is null'
    else
      con = "group_id=#{group_id.to_i}"
    end

    Location.do_expire(con)

    return Location.where(con).to_a
  end

  #=== self.do_expire
  #
  #Removes expired Locations.
  #
  #_add_con_:: Additional condition.
  #
  def self.do_expire(add_con=nil)

    con = "(updated_at < '#{(Time.now.utc - 24*60*60).strftime('%Y-%m-%d %H:%M:%S')}')"

    unless add_con.nil? or add_con.empty?
      con << ' and (' + add_con + ')'
    end

    Location.where(con).destroy_all
  end

  #=== expired?
  #
  #Gets if this Location has been expired.
  #
  def expired?

    return (self.updated_at.utc < (Time.now.utc - 24*60*60))
  end

  #=== get_name
  #
  #Gets the name of the User related to this Location.
  #
  #_users_cache_:: Hash to accelerate response. {user_id, user_name}
  #_user_obj_cache_:: Hash to accelerate response. {user_id, user}
  #return:: Name of the User related to this Location.
  #
  def get_name(users_cache=nil, user_obj_cache=nil)

    return User.get_name(self.user_id, users_cache, user_obj_cache)
  end
end
