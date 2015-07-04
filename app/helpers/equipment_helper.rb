#
#= EquipmentHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about Equipment.
#
#== Note:
#
#* 
#
module EquipmentHelper

  #=== self.get_scope_condition_for
  #
  #Gets the SQL condition clause about membership
  #of the specified User.
  #
  #_user_:: The target User.
  #return:: SQL condition clause..
  #
  def self.get_scope_condition_for(user)

    scope_con = '((users is null) and (groups is null) and (teams is null))'

    unless user.nil?
      con = ["(users like '%|#{user.id}|%')"]
      user.get_groups_a(true).each do |group_id|
        con << "(groups like '%|#{group_id}|%')"
      end
      user.get_teams_a.each do |team_id|
        con << "(teams like '%|#{team_id}|%')"
      end

      scope_con << ' or (' + con.join(' or ') + ')'
    end

    return scope_con
  end
end
