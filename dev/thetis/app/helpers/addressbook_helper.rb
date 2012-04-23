#
#= AddressbookHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
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
  #_prms_:: Request parameters.
  #_user_:: Login User.
  #return:: true if succeeded, false otherwise.
  #
  def self.arrange_per_scope(prms, user)

    case prms[:scope]
     when 'private'
      prms[:address][:owner_id] = user.id
      prms[:address][:groups] = nil
      prms[:address][:teams] = nil

     when 'all'
      return false unless user.admin?(User::AUTH_ADDRESSBOOK)

      prms[:address][:owner_id] = 0
      prms[:address][:groups] = nil
      prms[:address][:teams] = nil

     when 'common'
      return false unless user.admin?(User::AUTH_ADDRESSBOOK)

      prms[:address][:owner_id] = 0

      if (prms[:groups].nil? or prms[:groups].empty?)
        prms[:address][:groups] = nil
      else
        prms[:address][:groups] = '|' + prms[:groups].join('|') + '|'
      end

      if (prms[:teams].nil? or prms[:teams].empty?)
        prms[:address][:teams] = nil
      else
        prms[:address][:teams] = '|' + prms[:teams].join('|') + '|'
      end
    end

    return true
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
          scope_con << "(groups like '%|#{group_id}|%')"
        end
        user.get_teams_a.each do |team_id|
          scope_con << "(teams like '%|#{team_id}|%')"
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
