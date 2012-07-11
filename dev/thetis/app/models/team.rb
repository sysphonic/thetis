#
#= Team
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Team is the unit to take on a mission (= Item whose xtype attribute is XTYPE_PROJECT).
#
#== Note:
#
#*
#
class Team < ActiveRecord::Base
  attr_accessible(:name, :item_id, :users, :status, :req_to_del_at)

  belongs_to(:item)

  public::STATUS_STANDBY = 'standby'
  public::STATUS_ACTIVATED = 'activated'
  public::STATUS_DEACTIVATED = 'deactivated'

 public

  #=== get_status_name
  #
  #Gets String which represents specified status.
  #
  #_status_:: Status.
  #return:: String which represents specified status.
  #
  def self.status_name(status)

    status_names = {
      STATUS_STANDBY => I18n.t('team.status.standby'),
      STATUS_ACTIVATED => I18n.t('team.status.activated'),
      STATUS_DEACTIVATED => I18n.t('team.status.deactivated'),
    }
    return status_names[status]
  end

  #=== get_status_name
  #
  #Gets String which represents status of the Team.
  #
  #return:: String which represents status of the Team.
  #
  def get_status_name

    return Team.status_name(self.status)
  end

  #=== update_status
  #
  #Updates status of the Team.
  #
  #_new_stat_:: New status.
  #
  def update_status(new_stat)

    self.update_attributes({:status => new_stat, :req_to_del_at => nil})
  end

  #=== need_req_to_del?
  #
  #Checks if it is needed to request to delete this Team.
  #
  #_ignore_former_req_:: Flag to ignore the former requests.
  #return:: true if confirmation required, false otherwise.
  #
  def need_req_to_del?(ignore_former_req=false)

    return false if self.status == Team::STATUS_ACTIVATED

    if ignore_former_req or self.req_to_del_at.nil?
      return true if self.updated_at.nil?

      base_dt = self.updated_at
      pending_months = 3
    else
      base_dt = self.req_to_del_at
      pending_months = 1
    end

    expired_date = (UtilDate.create(base_dt).get_date >> pending_months)

    return UtilDate.create(expired_date).before?(Date.today)
  end

  #=== done_req_to_del
  #
  #Register the current time as the last request time
  #to delete this Team.
  #
  def done_req_to_del

    return if self.status != Team::STATUS_DEACTIVATED

    class << self
      def record_timestamps; false; end
    end

    self.update_attributes({:req_to_del_at => Time.now})

    class << self
      remove_method :record_timestamps
    end
  end

  #=== self.check_req_to_del_for
  #
  #Check if the specified User has any Teams which it is needed
  #to request to delete.
  #
  #_user_id_:: Target User-ID.
  #return:: true or false.
  #
  def self.check_req_to_del_for(user_id)

    con = "xtype='#{Item::XTYPE_PROJECT}'"

    project_items = Item.find(:all, :conditions => con)
    return if project_items.nil? or project_items.empty?

    project_items.each do |item|
      team = item.team
      next if team.nil?

      if team.need_req_to_del?
        comment = Comment.new
        comment.user_id = 0   # 0 for System
        comment.item_id = item.id
        comment.xtype = Comment::XTYPE_MSG
        comment.message = I18n.t('team.request_to_delete')
        comment.save

        team.done_req_to_del
      end
    end
  end

  #=== self.get_for
  #
  #Gets Teams of the specified User.
  #
  #_user_id_:: Target User-ID. Specify nil if all required (for admins).
  #_exclude_deact_:: Flag to exclude deactivated Teams.
  #return:: Teams for the specified User.
  #
  def self.get_for(user_id, exclude_deact)
    con = []
    con << "(users like '%|#{user_id}|%')" unless user_id.nil? or user_id.to_s.empty?
    con << "(status != '#{Team::STATUS_DEACTIVATED}')" if exclude_deact
    return Team.find(:all, :conditions => con.join(' and ')) || []
  end

  #=== self.destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  #_id_:: Target Team-ID.
  #
  def self.destroy(id)

    id.is_a?(Array) ? id.each { |id| destroy(id) } : find(id).destroy
  end

  #=== destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  def destroy()

    # Team Folder
    folder = Team.get_team_folder(self.id)

    unless folder.nil?

      if folder.count_items(true) <= 0

        folder.force_destroy

      else

        folder.slice_auth_team(self)
        folder.owner_id = 0
        folder.xtype = nil
        folder.save
      end
    end

    # General Folders
    con = "(read_teams like '%|#{self.id}|%') or (write_teams like '%|#{self.id}|%')"
    folders = Folder.find(:all, :conditions => con)

    unless folders.nil?
      folders.each do |folder|
        folder.slice_auth_team(self)
        folder.save
      end
    end

    # Schedules
    Schedule.trim_on_destroy_member(:team, self.id)

    super()
  end

  #=== self.delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  #_id_:: Target Team-ID.
  #
  def self.delete(id)

    Team.destroy(id)
  end

  #=== delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  def delete()

    Team.destroy(self.id)
  end

  #=== self.destroy_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.destroy_all(conditions = nil)

    raise 'Use Team.destroy() instead of Team.destroy_all()!'
  end

  #=== self.delete_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.delete_all(conditions = nil)

    raise 'Use Team.destroy() instead of Team.delete_all()!'
  end

  #=== rename
  #
  #Renames Team.
  #
  #_new_name_:: New name.
  #
  def rename(new_name)

    self.update_attribute(:name, new_name)

    folder = self.get_team_folder

    unless folder.nil?
      folder.update_attribute(:name, new_name)
    end
  end

  #=== get_users_a
  #
  #Gets Users array who belong to this Team.
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

  #=== clear_users
  #
  #Excludes all Users from this Team.
  #
  #return:: true if modified, false otherwise.
  #
  def clear_users

    if self.users.nil? or self.users.empty?
      return false
    else
      self.users = nil
      return true
    end
  end

  #=== add_users
  #
  #Adds specified Users to this Team without duplex-check.
  #
  def add_users(new_users)

    return if new_users.nil?

    self.users = '|' if self.users.nil? or self.users.empty?
    self.users += new_users.join('|') + '|'
  end

  #=== self.get_name
  #
  #Gets the name of the specified Team.
  #
  #_team_id_:: Target Team-ID
  #_teams_cache_:: Hash to accelerate response. {team_id, name}
  #return:: Team name. If not found, prearranged string.
  #
  def self.get_name(team_id, teams_cache=nil)

    unless teams_cache.nil?
      name = teams_cache[team_id.to_i]
      return name unless name.nil?
    end

    begin
      team = Team.find(team_id)
    rescue => evar
      Log.add_error(nil, evar)
    end

    if team.nil?
      name = team_id.to_s + ' '+ I18n.t('paren.deleted')
    else
      name = team.name
    end

    teams_cache[team_id.to_i] = name unless teams_cache.nil?
    return name
  end

  #=== get_team_folder
  #
  #Gets Team Folder.
  #
  #return:: Folder object of the Team.
  #
  def get_team_folder

    Team.get_team_folder(self.id)
  end

  #=== self.get_team_folder
  #
  #Gets Team Folder of specified Team-ID.
  #
  #_team_id_:: Target Team-ID.
  #return:: Folder object of the Team.
  #
  def self.get_team_folder(team_id)

    begin
      return Folder.find(:first, :conditions => ['owner_id=? and xtype=?', team_id.to_i, Folder::XTYPE_TEAM])
    rescue => evar
      Log.add_error(nil, evar)
      return nil
    end
  end

  #=== create_team_folder
  #
  #Creates Team Folder.
  #
  #return:: Folder object of the Team.
  #
  def create_team_folder

    folder = Folder.new
    folder.name = self.name
    folder.parent_id = 0
    folder.owner_id = self.id
    folder.xtype = Folder::XTYPE_TEAM
    folder.read_teams = '|'+self.id.to_s+'|'
    folder.write_teams = '|'+self.id.to_s+'|'
    folder.save!

    return folder
 end

  #=== remove_application
  #
  #Removes applications of the specified Users.
  #
  #_users_:: Array of User-IDs.
  #
  def remove_application(users)

    return if users.nil? or users.empty?

    array = ["(xtype='#{Comment::XTYPE_APPLY}')"]
    array << "(item_id=#{self.item_id})"

    user_con_a = []
    users.each do |user_id|
      user_con_a << "(user_id=#{user_id})"
    end

    array << '(' + user_con_a.join(' or ') + ')'

    Comment.destroy_all(array.join(' and '))
 end

end
