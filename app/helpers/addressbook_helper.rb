#
#= AddressbookHelper
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Methods added to this helper will be available to all templates in the application.
#
#== Note:
#
#* 
#
module AddressbookHelper

  #=== self.arrange_per_scope
  #
  #Arranges parameters per scope specification.
  #
  #_address_:: Target Address.
  #_user_:: Login User.
  #_scope_:: Scope (common, all or private).
  #_group_ids_:: Group-IDs to set to the Address.
  #_team_ids_:: Team-IDs to set to the Address.
  #return:: Target Address.
  #
  def self.arrange_per_scope(address, user, scope, group_ids, team_ids)

    SqlHelper.validate_token([group_ids, team_ids])

    case scope
     when 'private'
      address.owner_id = user.id
      address.groups = nil
      address.teams = nil

     when 'all'
      return false unless user.admin?(User::AUTH_ADDRESSBOOK)

      address.owner_id = 0
      address.groups = nil
      address.teams = nil

     when 'common'
      return nil unless user.admin?(User::AUTH_ADDRESSBOOK)

      address.owner_id = 0

      if group_ids.nil? or group_ids.empty?
        address.groups = nil
      else
        address.groups = '|' + group_ids.join('|') + '|'
      end

      if team_ids.nil? or team_ids.empty?
        address.teams = nil
      else
        address.teams = '|' + team_ids.join('|') + '|'
      end
    end

    return address
  end

  #=== self.get_scope_condition_for
  #
  #Gets the SQL condition clause about membership
  #of the specified User.
  #
  #_user_:: Target User.
  #_book_:: Target book.
  #return:: SQL condition clause..
  #
  def self.get_scope_condition_for(user, book=Address::BOOK_BOTH)

    scope_con = []

    if (book == Address::BOOK_BOTH or book == Address::BOOK_COMMON)
      scope_con << '((owner_id=0) and (groups is null) and (teams is null))'

      unless user.nil?
        user.get_groups_a(true).each do |group_id|
          scope_con << SqlHelper.get_sql_like([:groups], "|#{group_id}|")
        end
        user.get_teams_a.each do |team_id|
          scope_con << SqlHelper.get_sql_like([:teams], "|#{team_id}|")
        end
      end
    end

    if (book == Address::BOOK_BOTH or book == Address::BOOK_PRIVATE)
      unless user.nil?
        scope_con << "(owner_id=#{user.id})"
      end
    end

    if scope_con.empty?
      scope_con << "(owner_id is null)"   # Should always get empty set
    end

    return '(' + scope_con.join(' or ') + ')'
  end
end
