#
#= Equipment
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Equipment is related to Schedules, in short, 'reserved'.
#
#== Note:
#
#* Some attributes ('users', 'groups', 'teams') are prepared for future use, currently not in use,
#
class Equipment < ActiveRecord::Base

  validates_presence_of :name

  #=== self.get_name
  #
  #Gets Equipment name.
  #
  #return:: Equipment name.
  #
  def self.get_name(equipment_id)

    begin
      equipment = Equipment.find(equipment_id)
    rescue
    end
    if equipment.nil?
      return equipment_id.to_s + ' '+ I18n.t('paren.deleted')
    else
      return equipment.name
    end
  end

  #=== get_users_a
  #
  #Gets Users array which this Equipment belongs to.
  #
  #return:: Users array without empty element. If no Users, returns empty array.
  #
  def get_users_a

    return [] if self.users.nil? or self.users.empty?

    array = self.users.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_groups_a
  #
  #Gets Groups array which this Equipment belongs to.
  #
  #return:: Groups array without empty element. If no Groups, returns empty array.
  #
  def get_groups_a

    return [] if self.groups.nil? or self.groups.empty?

    array = self.groups.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_teams_a
  #
  #Gets Teams array which this Equipment belongs to.
  #
  #return:: Teams array without empty element. If no Teams, returns empty array.
  #
  def get_teams_a

    return [] if self.teams.nil? or self.teams.empty?

    array = self.teams.split('|')
    array.compact!
    array.delete('')

    return array
  end
end
