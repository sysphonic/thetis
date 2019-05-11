#
#= EquipmentHelper
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
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
        con << SqlHelper.get_sql_like([:groups], "|#{group_id}|")
      end
      user.get_teams_a.each do |team_id|
        con << SqlHelper.get_sql_like([:teams], "|#{team_id}|")
      end

      scope_con << ' or (' + con.join(' or ') + ')'
    end

    return scope_con
  end
end
