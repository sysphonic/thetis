#
#= Team
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Team is the unit to take on a mission (= Item whose xtype attribute is XTYPE_PROJECT).
#
class Team < ApplicationRecord
  public::PERMIT_BASE = [:name, :item_id, :users, :status, :req_to_del_at]

  belongs_to(:item)

  public::STATUS_STANDBY = 'standby'
  public::STATUS_ACTIVATED = 'activated'
  public::STATUS_DEACTIVATED = 'deactivated'

  before_destroy do |rec|
    # Team Folder
    folder = Team.get_team_folder(rec.id)

    unless folder.nil?
      if (folder.count_items(true) <= 0)
        folder.force_destroy
      else
        folder.slice_auth_team(rec)
        folder.owner_id = 0
        folder.xtype = nil
        folder.save
      end
    end

    # General Folders
    con = SqlHelper.get_sql_like([:read_teams, :write_teams], "|#{rec.id}|")
    folders = Folder.where(con).to_a
    unless folders.nil?
      folders.each do |folder|
        folder.slice_auth_team(rec)
        folder.save
      end
    end

    # Schedules
    Schedule.trim_on_destroy_member(:team, rec.id)
  end

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

    attrs = ActionController::Parameters.new({status: new_stat, req_to_del_at: nil})
    self.update_attributes(attrs.permit(Team::PERMIT_BASE))
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

    attrs = ActionController::Parameters.new({req_to_del_at: Time.now})
    self.update_attributes(attrs.permit(Team::PERMIT_BASE))

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

    project_items = Item.where(con).to_a
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
    con << SqlHelper.get_sql_like([:users], "|#{user_id}|") unless user_id.nil? or user_id.to_s.empty?
    con << "(status != '#{Team::STATUS_DEACTIVATED}')" if exclude_deact
    return Team.where(con.join(' and ')).to_a
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

    return ApplicationHelper.attr_to_a(self.users)
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

    return if new_users.nil? or new_users.empty?

    arr = ApplicationHelper.attr_to_a(self.users)
    arr |= new_users
    self.users = ApplicationHelper.a_to_attr(arr)
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

    SqlHelper.validate_token([team_id])
    begin
      return Folder.where("(owner_id=#{team_id.to_i}) and (xtype='#{Folder::XTYPE_TEAM}')").first
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
    folder.read_teams = ApplicationHelper.a_to_attr([self.id])
    folder.write_teams = ApplicationHelper.a_to_attr([self.id])
    folder.save!

    return folder
 end

  #=== remove_application
  #
  #Removes applications of the specified Users.
  #
  #_user_ids_:: Array of User-IDs.
  #
  def remove_application(user_ids)

    return if user_ids.nil? or user_ids.empty?

    SqlHelper.validate_token([user_ids])

    con = ["(xtype='#{Comment::XTYPE_APPLY}')"]
    con << "(item_id=#{self.item_id})"

    user_con_a = []
    user_ids.each do |user_id|
      user_con_a << "(user_id=#{user_id.to_i})"
    end

    con << '(' + user_con_a.join(' or ') + ')'

    Comment.where(con.join(' and ')).destroy_all
 end
end
