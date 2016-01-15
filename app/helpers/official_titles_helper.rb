#
#= OfficialTitlesHelper
#
#Copyright:: Copyright (c) 2007-2013 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about OfficialTitle.
#
#== Note:
#
#* 
#
module OfficialTitlesHelper

  #=== self.sort_users
  #
  #Sorts array of Users by OfficialTitle.
  #
  #_users_:: The target array of Users.
  #_direction_:: Sort direction (:asc or :desc).
  #_group_id_:: Target Group-ID.
  #return:: Sorted array.
  #
  def self.sort_users(users, direction=:asc, group_id=nil)

    return nil if users.nil?

    official_title_obj_cache = {}

    sorted_users = users.sort{|user_a, user_b|
      official_title_a = user_a.get_prime_official_title(group_id)
      official_title_b = user_b.get_prime_official_title(group_id)
      xorder_a = official_title_a.xorder unless official_title_a.nil?
      xorder_b = official_title_b.xorder unless official_title_b.nil?
      xorder_a ||= OfficialTitle::XORDER_MAX
      xorder_b ||= OfficialTitle::XORDER_MAX

      if xorder_a != xorder_b
        (direction.to_s.downcase == 'asc')?(xorder_a - xorder_b):(xorder_b - xorder_a)
#     elsif (user_a.fullname_kana || '') != (user_b.fullname_kana || '')
#       kana_a = user_a.fullname_kana || ''
#       kana_b = user_b.fullname_kana || ''
#       (direction.to_s.downcase == 'asc')?(kana_a <=> kana_b):(kana_b <=> kana_a)
      else
        (direction.to_s.downcase == 'asc')?(user_a.name <=> user_b.name):(user_b.name <=> user_a.name)
      end
    }

    return sorted_users
  end
end
