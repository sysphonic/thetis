#
#= User
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class User < ApplicationRecord
  public::PERMIT_BASE = [:name, :fullname, :pass_md5, :address, :organization, :email, :tel1, :tel1_note, :tel2, :tel2_note, :tel3, :tel3_note, :fax, :url, :postalcode, :birthday, :time_zone, :figure, :email_sub1, :email_sub1_type, :email_sub2, :email_sub2_type, :title, :xorder]

  has_many(:user_titles, {:dependent => :destroy})
  has_one(:paintmail, {:dependent => :destroy})

  require('csv')

  extend(CachedRecord)

  validates_uniqueness_of(:name)
# Comment out considering about administrative users.
#  validates_uniqueness_of(:email)
  validates_format_of(:name, :with => /\A[01-9a-zA-Z]+\z/)
  validates_presence_of(:name, :pass_md5, :email)

  public::PASSWORD_DUMMY = '********'

  public::AUTH_ALL = 'all'
  public::AUTH_DESKTOP = 'desktop'
  public::AUTH_ITEM = 'item'
  public::AUTH_FOLDER = 'folder'
  public::AUTH_USER = 'user'
  public::AUTH_GROUP = 'group'
  public::AUTH_TEAM = 'team'
  public::AUTH_SCHEDULE = 'schedule'
  public::AUTH_EQUIPMENT = 'equipment'
  public::AUTH_LOG = 'log'
  public::AUTH_RESEARCH = 'research'
  public::AUTH_TEMPLATE = 'template'
  public::AUTH_TIMECARD = 'timecard'
  public::AUTH_WORKFLOW = AUTH_ITEM
  public::AUTH_MAIL = 'mail'
  public::AUTH_ADDRESSBOOK = 'address'
  public::AUTH_ZEPTAIR = 'zeptair'
  public::AUTH_LOCATION = 'location'

  public::XORDER_MAX = 9999

  public::ZEPTID_PLACE_HOLDER = '#'

  before_destroy do |rec|
    # General Folders
    con = SqlHelper.get_sql_like([:read_users, :write_users], "|#{rec.id}|")
    folders = Folder.where(con).to_a
    unless folders.nil?
      folders.each do |folder|
        folder.remove_auth_user(rec)
        folder.save
      end
    end

    # My Folder and its contents
    folder = User.get_my_folder(rec.id)
    folder.force_destroy unless folder.nil?

    # Application for Teams
    Comment.where("(user_id=#{rec.id}) and (xtype='#{Comment::XTYPE_APPLY}')").destroy_all

    Toy.where("(user_id=#{rec.id})").destroy_all
    Research.where("(user_id=#{rec.id})").destroy_all
    Desktop.where("(user_id=#{rec.id})").destroy_all

    # Timecards and PaidHolidays
    Timecard.where("(user_id=#{rec.id})").destroy_all
    PaidHoliday.where("(user_id=#{rec.id})").destroy_all

    # MailFolders, Emails and MailAccounts
    MailFolder.where("(user_id=#{rec.id})").destroy_all
    Email.destroy_by_user(rec.id)
    MailAccount.destroy_by_user(rec.id)

    # Addresses in private Addressbook
    Address.where("(owner_id=#{rec.id})").destroy_all

    # Settings
    Setting.where("(user_id=#{rec.id})").destroy_all

    # Schedules
    Schedule.trim_on_destroy_member(:user, rec.id)

    # Locations
    Location.where("(user_id=#{rec.id})").destroy_all
  end

  #=== get_emails_by_type
  #
  #Gets email addresses of the specified email type.
  #
  #_email_type_:: Target type of email.
  #return:: Array of email addresses of the specified email type.
  #
  def get_emails_by_type(email_type=nil)

    if email_type.nil?
      return [self.email]
    else
      ret = []
      [
        [self.email_sub1, self.email_sub1_type],
        [self.email_sub2, self.email_sub2_type]
      ].each do |sub_entry|
        sub_addr, sub_type = sub_entry
        if (sub_type == email_type)
          unless (sub_addr.nil? or sub_addr.empty?)
            ret << sub_addr
          end
        end
      end
      return ret
    end
  end

  #=== self.get_email_type_name
  #
  #Gets String which represents specified email type.
  #
  #_email_type_:: Target type of email.
  #return:: String which represents specified email type.
  #
  def self.get_email_type_name(email_type)

    return '' if (email_type.nil? or email_type.empty?)

    return I18n.t('email.type.' + email_type.to_s)
  end

  #=== get_xorder
  #
  #Gets order of the User.
  #
  #_group_id_:: Target Group-ID.
  #return:: Order of the User.
  #
  def get_xorder(group_id=nil)

    prime_official_title = self.get_prime_official_title(group_id)
    if prime_official_title.nil?
      return OfficialTitle::XORDER_MAX
    else
      return prime_official_title.xorder
    end
  end

  #=== get_prime_official_title
  #
  #Gets prime OfficialTitle of the User.
  #
  #_group_id_:: Target Group-ID.
  #return:: Prime OfficialTitle of the User.
  #
  def get_prime_official_title(group_id=nil)

    if group_id.nil?
      group_ids = nil
    else
      group_ids = [TreeElement::ROOT_ID.to_s]

      if (group_id.to_s != TreeElement::ROOT_ID.to_s)
        group_obj_cache = {}
        group = Group.find_with_cache(group_id, group_obj_cache)
        unless group.nil?
          group_ids |= group.get_parents(false, group_obj_cache)
          group_ids << group.id.to_s
        end
      end
    end

    ret = nil

    self.user_titles.each do |user_title|
      official_title = OfficialTitle.find(user_title.official_title_id)
      next if official_title.nil?

      if (group_ids.nil? or group_ids.include?(official_title.group_id.to_s))
        if (ret.nil? or ret.xorder > official_title.xorder)
          ret = official_title
        end
      end
    end

    return ret
  end

  #=== get_figure
  #
  #Gets User's figure.
  #
  #return:: User's figure.
  #
  def get_figure
    if (self.figure.nil? or self.figure.empty?)
      return 'boy_green'
    else
      return self.figure
    end
  end

  #=== allowed_zept_connect?
  #
  #Gets if the User is allowed to connect with Zeptair VPN.
  #
  #return:: Flag whether the User is allowed to connect with Zeptair VPN.
  #
  def allowed_zept_connect?
    return !(self.zeptair_id.nil? or self.zeptair_id.empty?)
  end

  #=== self.get_tel_type_name
  #
  #Gets String which represents specified telephone type.
  #
  #_tel_type_:: Target type of telephone.
  #return:: String which represents specified telephone type.
  #
  def self.get_tel_type_name(tel_type)
    tel_types = {
      'External' => I18n.t('tel.external'),
      'Internal' => I18n.t('tel.internal'),
      'Home' => I18n.t('tel.home'),
      'Mobile' => I18n.t('tel.mobile'),
    }
    return tel_types[tel_type]
  end

  #=== self.get_config_titles
  #
  #Gets titles from the configuration file.
  #
  #return:: Titles in the configuration file.
  #
  def self.get_config_titles

    yaml = ApplicationHelper.get_config_yaml
    return YamlHelper.get_value(yaml, 'user_titles', nil)
  end

  #=== self.save_config_titles
  #
  #Saves official titles in the configuration file.
  #
  #_titles_:: Array of the official titles.
  #
  def self.save_config_titles(titles)

    yaml = ApplicationHelper.get_config_yaml
    YamlHelper.set_value(yaml, 'user_titles', titles)
    ApplicationHelper.save_config_yaml(yaml)
  end

  #=== self.get_auth_names
  #
  #Gets Hash of authority names.
  #
  #return:: Hash of authority names.
  #
  def self.get_auth_names
    auth_names = {
      AUTH_ALL => I18n.t('user.auth_all'),
      AUTH_DESKTOP => Desktop.model_name.human,
      AUTH_ITEM => Item.model_name.human,
      AUTH_FOLDER => Folder.model_name.human,
      AUTH_USER => User.model_name.human,
      AUTH_GROUP => Group.model_name.human,
      AUTH_TEAM => Team.model_name.human,
      AUTH_SCHEDULE => Schedule.model_name.human,
      AUTH_EQUIPMENT => Equipment.model_name.human,
      AUTH_LOG => Log.model_name.human,
      AUTH_RESEARCH => Research.model_name.human,
      AUTH_TEMPLATE => I18n.t('template.name'),
      AUTH_TIMECARD => Timecard.model_name.human,
      AUTH_MAIL => Email.model_name.human,
      AUTH_ADDRESSBOOK => I18n.t('address.book'),
      AUTH_ZEPTAIR => I18n.t('zeptair.vpn'),
      AUTH_LOCATION => Location.model_name.human,
    }

    return auth_names
  end

  #=== self.get_auth_name
  #
  #Gets String which represents the specified authority.
  #
  #_auth_:: Target authority.
  #return:: String which represents the specified authority.
  #
  def self.get_auth_name(auth)

    return User.get_auth_names[auth]
  end

  #=== self.authenticate
  #
  #Authenticates attributes.
  #
  #_attrs_:: Hash of the attributes to authenticate.
  #
  def self.authenticate(attrs)

    return nil if (attrs.nil? or attrs[:name].nil? or attrs[:password].nil?)

    name = attrs[:name]
    password = attrs[:password]

    SqlHelper.validate_token([name])

    pass_md5 = UsersHelper.generate_digest_pass(name, password)

    return User.where("(name='#{name}') and (pass_md5='#{pass_md5}')").first
  end

  #=== self.find_all
  #
  #Finds all Users in order to display with specified condition.
  #
  #_con_:: Condition (String without 'where '). If not required, specify nil.
  #return:: Array of Users.
  #
  def self.find_all(con = nil)

    where = ''

    unless con.nil? or con.empty?
      where = 'where ' + con
    end

    User.find_by_sql('select * from users ' + where + ' order by xorder ASC, name ASC')
  end

  #=== exclude_from
  #
  #Excludes this User from specified Group.
  #
  #return:: true if modified, false otherwise.
  #
  def exclude_from(group_id)

    return false if self.groups.nil?

    arr = ApplicationHelper.attr_to_a(self.groups)
    if arr.include?(group_id.to_s)
      arr.delete(group_id.to_s)
      self.groups = ApplicationHelper.a_to_attr(arr)
      self.groups = nil if self.groups.blank?
      return true
    else
      return false
    end
  end

  #=== add_to
  #
  #Adds this User to specified Group.
  #
  #return:: true if modified, false otherwise.
  #
  def add_to(group_id)

    return false if group_id.nil?

    arr = ApplicationHelper.attr_to_a(self.groups)
    if arr.include?(group_id.to_s)
      return false
    else
      arr << group_id
      self.groups = ApplicationHelper.a_to_attr(arr)
      return true
    end
  end

  #=== self.get_name
  #
  #Gets the name of specified User.
  #
  #_user_id_:: Target User-ID
  #_users_cache_:: Hash to accelerate response. {user.id, user_name}
  #_user_obj_cache_:: Hash to accelerate response. {user.id, user}
  #return:: User name. If not found, prearranged string.
  #
  def self.get_name(user_id, users_cache=nil, user_obj_cache=nil)

    return '' if user_id.nil?

    unless users_cache.nil?
      user_name = users_cache[user_id.to_i]
      return user_name unless user_name.nil?
    end

    if (user_id.to_s == '0')
      user_name = I18n.t('user.system')
    else
      user = User.find_with_cache(user_id, user_obj_cache)

      if user.nil?
        user_name = user_id.to_s + ' '+ I18n.t('paren.deleted')
      else
        user_name = user.get_name
      end
    end

    unless users_cache.nil?
      users_cache[user_id.to_i] = user_name
    end

    return user_name
  end

  #=== get_name
  #
  #Gets the name of this User.
  #
  #return:: User name.
  #
  def get_name

    if (YamlHelper.get_value($thetis_config, 'user.by_full_name', nil) == '1') \
        and !self.fullname.blank?
      return self.fullname
    else
      return self.name
    end
  end

  #=== get_name_for_timecard
  #
  #Gets the name of this User for Timecard.
  #
  #_yaml_:: YAML to save loading time.
  #return:: User name for Timecard.
  #
  def get_name_for_timecard(yaml=nil)

    return self.name if self.fullname.blank?

    if (YamlHelper.get_value($thetis_config, 'user.by_full_name', nil) == '1')
      return self.fullname
    else
      yaml = ApplicationHelper.get_config_yaml if yaml.nil?

      if (YamlHelper.get_value(yaml, 'timecard.always_by_full_name', nil) == '1')
        return self.fullname
      else
        return self.name
      end
    end
  end

  #=== self.get_from_name
  #
  #Gets User who has specified name.
  #
  #_user_name_:: Target User name
  #return:: User.
  #
  def self.get_from_name(user_name)

    SqlHelper.validate_token([user_name])

    begin
      user = User.where(name: user_name).first
    rescue => evar
      Log.add_error(nil, evar)
    end

    return user
  end

  #=== get_groups_a
  #
  #Gets Groups array to which this User belongs.
  #
  #_incl_parents_:: Flag to require parent Group-IDS by return.
  #_group_obj_cache_:: Hash to accelerate response. {group_id, group}
  #return:: Array of Group-IDs.
  #
  def get_groups_a(incl_parents=false, group_obj_cache=nil)

    return [TreeElement::ROOT_ID.to_s] if (self.groups.nil? or self.groups.empty?)

    arr = ApplicationHelper.attr_to_a(self.groups)

    if incl_parents
      parent_ids = []
      arr.each do |group_id|

        group = Group.find_with_cache(group_id, group_obj_cache)

        unless group.nil?
          parent_ids |= group.get_parents(false, group_obj_cache)
        end
      end
      arr |= parent_ids
    end

    return arr.uniq
  end

  #=== get_group_branches
  #
  #Gets Array of Group branches to which the User belongs.
  #
  #_group_obj_cache_:: Hash to accelerate response. {group_id, group}
  #return:: Array of Group branches.
  #
  def get_group_branches(group_obj_cache=nil)

    group_branches = []

    return group_branches if (self.groups.nil? or self.groups.empty?)

    group_ids = ApplicationHelper.attr_to_a(self.groups)
    group_ids.each do |group_id|
      group = Group.find_with_cache(group_id, group_obj_cache)

      unless group.nil?
        branch = group.get_parents(false, group_obj_cache)
        branch << group_id
        group_branches << branch
      end
    end

    return group_branches
  end

  #=== get_teams_a
  #
  #Gets Teams array to which this User belongs.
  #
  #return:: Array of Team-IDs. If no teams, returns empty array.
  #
  def get_teams_a

    teams = Team.where(SqlHelper.get_sql_like([:users], "|#{self.id}|")).to_a

    arr = []

    return arr if teams.nil?

    teams.each do |team|
      arr << team.id.to_s
    end

    return arr
  end

  #=== self.get_admins
  #
  #Gets Users who have the specified authority.
  #
  #_auth_:: Target authority. If any, specify nil.
  #return:: Array of Users.
  #
  def self.get_admins(auth)

    if (auth.nil? or auth.empty?)

      admins = User.find_all('auth is not null')

    elsif (auth == User::AUTH_ALL)

      admins = User.find_all("auth='#{User::AUTH_ALL}'")

    else

      admins = User.find_all("(auth='#{User::AUTH_ALL}') or " + SqlHelper.get_sql_like([:auth], "|#{auth}|"))
    end

    admins = [] if admins.nil?

    return admins
  end

  #=== admin?
  #
  #Checks if this User has an administrative authority.
  #
  #_auth_:: Authority to verify. If called without argument, verify if User has any authority.
  #return:: true if this User has authority, false otherwise.
  #
  def admin?(auth=nil)

    return false if self.auth.nil?
    return true if (self.auth == AUTH_ALL)

    if auth.nil?

      if (!self.auth.nil? and !self.auth.empty?)
        return true
      else
        return false
      end

    else

      if self.auth.index("|#{auth}|").nil?
        return false
      else
        return true
      end
    end
  end

  #=== get_auth_a
  #
  #Gets authorities array.
  #
  #return:: Authorities array without empty element. If no authorities, returns empty array.
  #
  def get_auth_a

    return ApplicationHelper.attr_to_a(self.auth)
  end

  #=== get_profile_sheet
  #
  #Gets Profile-sheet as an Item object.
  #
  #return:: Profile-sheet as an Item object. If no profile, returns nil.
  #
  def get_profile_sheet

    return nil if self.item_id.nil?

    item = nil
    begin
      item = Item.find(self.item_id)
    rescue => evar
      Log.add_error(nil, evar)
    end
    return item
  end

  #=== create_profile_sheet
  #
  #Creates Profile-sheet of this User.
  #
  #return:: Profile-sheet as an Item object.
  #
  def create_profile_sheet

    folder = self.get_my_folder
    if folder.nil?
      folder = self.create_my_folder
    end

    tmpl_folder, tmpl_system_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_SYSTEM)

    unless tmpl_system_folder.nil?
      con = "(folder_id=#{tmpl_system_folder.id}) and (xtype='#{Item::XTYPE_PROFILE}')"
      begin
        tmpl_item = Item.where(con).first
      rescue
      end
    end

    item = Item.new_profile(folder.id)
    item.title = Item.profile_title_def

    unless tmpl_item.nil?
      item.title = tmpl_item.title
      item.summary = tmpl_item.summary
      item.description = tmpl_item.description
      item.layout = tmpl_item.layout
    end

    item.user_id = self.id
    item.save!

    self.update_attribute(:item_id, item.id)

    return item
 end

  #=== get_my_folder
  #
  #Gets 'My Folder' of this User.
  #
  #return:: Folder object of 'My Folder'.
  #
  def get_my_folder

    return User.get_my_folder(self.id)
  end

  #=== self.get_my_folder
  #
  #Gets 'My Folder' of specified User.
  #
  #_user_id_:: Target User-ID.
  #return:: Folder object of 'My Folder'.
  #
  def self.get_my_folder(user_id)

    SqlHelper.validate_token([user_id])
    return Folder.where("(owner_id=#{user_id.to_i}) and (xtype='#{Folder::XTYPE_USER}')").first
  end

  #=== create_my_folder
  #
  #Creates 'My Folder' of this User.
  #
  #return:: Folder object of 'My Folder'.
  #
  def create_my_folder

    folder = Folder.new
    folder.name = I18n.t('folder.my_folder')
    folder.parent_id = 0
    folder.owner_id = self.id
    folder.xtype = Folder::XTYPE_USER
    folder.read_users = ApplicationHelper.a_to_attr([self.id])
    folder.write_users = ApplicationHelper.a_to_attr([self.id])
    folder.save!

    return folder
 end

  #=== create_default_mail_folders
  #
  #Creates default MailFolders for User.
  #
  #_mail_account_id_:: Target MailAccount-ID.
  #return:: true if succeeded, false otherwise.
  #
  def create_default_mail_folders(mail_account_id)

    folder_account_root = MailFolder.new
    folder_account_root.name = ''
    folder_account_root.mail_account_id = mail_account_id
    folder_account_root.parent_id = 0
    folder_account_root.user_id = self.id
    folder_account_root.xtype = MailFolder::XTYPE_ACCOUNT_ROOT
    folder_account_root.created_at = Time.now
    folder_account_root.save!

    folder_inbox = MailFolder.new
    folder_inbox.name = I18n.t('mail.inbox')
    folder_inbox.mail_account_id = mail_account_id
    folder_inbox.parent_id = folder_account_root.id
    folder_inbox.user_id = self.id
    folder_inbox.xtype = MailFolder::XTYPE_INBOX
    folder_inbox.created_at = Time.now
    folder_inbox.save!

    folder_drafts = MailFolder.new
    folder_drafts.name = I18n.t('mail.drafts')
    folder_drafts.mail_account_id = mail_account_id
    folder_drafts.parent_id = folder_account_root.id
    folder_drafts.user_id = self.id
    folder_drafts.xtype = MailFolder::XTYPE_DRAFTS
    folder_drafts.created_at = Time.now
    folder_drafts.save!

    folder_sent = MailFolder.new
    folder_sent.name = I18n.t('mail.sent')
    folder_sent.mail_account_id = mail_account_id
    folder_sent.parent_id = folder_account_root.id
    folder_sent.user_id = self.id
    folder_sent.xtype = MailFolder::XTYPE_SENT
    folder_sent.created_at = Time.now
    folder_sent.save!

    folder_trash = MailFolder.new
    folder_trash.name = I18n.t('mail.trash')
    folder_trash.mail_account_id = mail_account_id
    folder_trash.parent_id = folder_account_root.id
    folder_trash.user_id = self.id
    folder_trash.xtype = MailFolder::XTYPE_TRASH
    folder_trash.created_at = Time.now
    folder_trash.save!

    return true
  end

  #=== self.belongs_to_group?
  #
  #Checks if the specified User belongs to the Group.
  #
  #_user_id_:: User-ID.
  #_Group_id_:: Group-ID.
  #_include_parents_:: Flag to include parent Groups.
  #return:: true if specified User belongs to Group, false otherwise.
  #
  def self.belongs_to_group?(user_id, group_id, include_parents)

    begin
      user = User.find(user_id)
    rescue => evar
      Log.add_error(nil, evar)
      return false
    end

    groups = user.get_groups_a
    return true if groups.include?(group_id.to_s)

    if include_parents
      groups.each do |gr_id|
        begin
          group = Group.find(gr_id)
        rescue => evar
          Log.add_error(nil, evar)
          next
        end
        return true if group.get_parents(false).include?(group_id.to_s)
      end
    end

    return false
 end

  #=== self.export_csv
  #
  #Gets CSV description of all Users.
  #
  def self.export_csv

    users = User.where(nil).order('id ASC').to_a

    csv_line = ''

    csv_line << I18n.t('user.export.rem1') + "\n"
    csv_line << I18n.t('user.export.rem2') + "\n"
    csv_line << I18n.t('user.export.rem3') + "\n"
    csv_line << "\n"

    csv_line << I18n.t('user.export.rem_groups') + "\n"
    groups = Group.where(nil).to_a
    unless groups.nil?
      groups_cache = {}
      group_obj_cache = Group.build_cache(groups)
      groups.each do |group|
        csv_line << '#   ' + group.id.to_s + ' = ' + Group.get_path(group.id, groups_cache, group_obj_cache) + "\n"
      end
    end
    csv_line << "\n"

    opt = {
      :force_quotes => true,
      :encoding => 'UTF-8'
    }

    csv_line << CSV.generate(opt) do |csv|

      # Header
      arr = []
      arr << I18n.t('activerecord.attributes.id')
      arr << User.human_attribute_name('name')
      arr << I18n.t('password.name')
      arr << User.human_attribute_name('fullname')
      arr << User.human_attribute_name('address')
      arr << User.human_attribute_name('organization')
      arr << User.human_attribute_name('email')
      arr << User.human_attribute_name('tel1_note')
      arr << User.human_attribute_name('tel1')
      arr << User.human_attribute_name('tel2_note')
      arr << User.human_attribute_name('tel2')
      arr << User.human_attribute_name('tel3_note')
      arr << User.human_attribute_name('tel3')
      arr << User.human_attribute_name('fax')
      arr << User.human_attribute_name('url')
      arr << User.human_attribute_name('postalcode')
      arr << User.human_attribute_name('auth')
      arr << User.human_attribute_name('groups')
      arr << User.human_attribute_name('title')
      arr << User.human_attribute_name('time_zone')
      arr << I18n.t('zeptair.id')
      arr << User.human_attribute_name('figure')

      csv << arr

      # Users
      users.each do |user|
        arr = []
        arr << user.id
        arr << user.name
        arr << ''   # Password
        arr << user.fullname
        arr << user.address
        arr << user.organization
        arr << user.email
        arr << user.tel1_note
        arr << user.tel1
        arr << user.tel2_note
        arr << user.tel2
        arr << user.tel3_note
        arr << user.tel3
        arr << user.fax
        arr << user.url
        arr << user.postalcode
        arr << user.auth
        arr << user.groups
        arr << user.title
        arr << user.time_zone
        arr << user.zeptair_id
        arr << user.figure

        csv << arr
      end
    end

    return csv_line
  end

  #=== self.parse_csv_row
  #
  #Parses fields array of a CSV row.
  #
  #_row_:: Fields array of a CSV row.
  #return:: User instance created from specified array.
  #
  def self.parse_csv_row(row)

    imp_id = (row[0].nil?)?nil:(row[0].strip)
    unless imp_id.nil? or imp_id.empty?
      begin
        org_user = User.find(imp_id)
      rescue
      end
    end

    if org_user.nil?
      user = User.new
    else
      user = org_user
    end

    user.id =           imp_id
    user.name =         (row[1].nil?)?nil:(row[1].strip)
    password =          (row[2].nil?)?nil:(row[2].strip)
    if (user.name.nil? or user.name.empty? \
            or password.nil? or password.empty?)
      user.pass_md5 = nil
    else
      user.pass_md5 = UsersHelper.generate_digest_pass(user.name, password)
    end
    user.fullname =     (row[3].nil?)?nil:(row[3].strip)
    user.address =      (row[4].nil?)?nil:(row[4].strip)
    user.organization = (row[5].nil?)?nil:(row[5].strip)
    user.email =        (row[6].nil?)?nil:(row[6].strip)
    user.tel1_note =    (row[7].nil?)?nil:(row[7].strip)
    user.tel1 =         (row[8].nil?)?nil:(row[8].strip)
    user.tel2_note =    (row[9].nil?)?nil:(row[9].strip)
    user.tel2 =         (row[10].nil?)?nil:(row[10].strip)
    user.tel3_note =    (row[11].nil?)?nil:(row[11].strip)
    user.tel3 =         (row[12].nil?)?nil:(row[12].strip)
    user.fax =          (row[13].nil?)?nil:(row[13].strip)
    user.url =          (row[14].nil?)?nil:(row[14].strip)
    user.postalcode =   (row[15].nil?)?nil:(row[15].strip)
    user.auth =         (row[16].nil?)?nil:(row[16].strip)
    user.groups =       (row[17].nil?)?nil:(row[17].strip)
    user.title =        (row[18].nil?)?nil:(row[18].strip)
    user.time_zone =    (row[19].nil?)?nil:(row[19].strip)
    user.zeptair_id =   (row[20].nil?)?nil:(row[20].strip)
    user.figure =       (row[21].nil?)?nil:(row[21].strip)

    return user
  end

  #=== check_import
  #
  #Checks data to import.
  #
  #_mode_:: Mode ('add' or 'update').
  #_user_names_:: Array of User names to check duplicated data.
  #return:: Array of error messages. If no error, returns [].
  #
  def check_import(mode, user_names)    #, user_emails

    err_msgs = []

    # Existing Users
    unless self.id.nil? or self.id == 0 or self.id == ''
      if (mode == 'add')
        err_msgs << I18n.t('user.import.dont_specify_id')
      else
        begin
          org_user = User.find(self.id)
        rescue
        end
        if org_user.nil?
          err_msgs << I18n.t('user.import.not_found')
        end
      end
    end

    # Required
    if (self.name.nil? or self.name.empty?)
      err_msgs <<  User.human_attribute_name('name') + I18n.t('msg.is_required')
    end
    if (self.pass_md5.nil? or self.pass_md5.empty?)
      if (mode == 'update' and !org_user.nil?)
        self.pass_md5 = org_user.pass_md5
      end
    end
    if (self.pass_md5.nil? or self.pass_md5.empty?)
      err_msgs << I18n.t('password.name') + I18n.t('msg.is_required')
    end
    if (self.email.nil? or self.email.empty?)
      err_msgs <<  User.human_attribute_name('email') + I18n.t('msg.is_required')
    end

    # Duplicated
    if user_names.include?(self.name)
      err_msgs << User.human_attribute_name('name') + I18n.t('msg.is_duplicated')
    elsif (!self.name.nil? and !self.name.empty?)
      user_names << self.name
    end
# Comment out considering about administrative users.
#    if user_emails.include?(self.email)
#      err_msgs << User.human_attribute_name('email') + I18n.t('msg.is_duplicated')
#    elsif (!self.email.nil? and !self.email.empty?)
#      user_emails << self.email
#    end

    # Characters
    if (/^[01-9a-zA-Z]+$/ =~ self.name).nil?
      err_msgs << User.human_attribute_name('name') + I18n.t('activerecord.errors.models.user.attributes.name.invalid', :attribute => User.human_attribute_name('name'))
    end

    # Authority
    unless self.auth.nil? or self.auth.empty? or self.auth == User::AUTH_ALL

      if (/^|([a-z]+|)+$/ =~ self.auth) == 0

        keys = User.get_auth_names.keys()
        keys.delete(User::AUTH_ALL)

        self.get_auth_a.each do |auth|
          unless keys.include?(auth)
            err_msgs << I18n.t('user.import.not_valid_auth') + ': '+auth.to_s
            break
          end
        end

      else
        err_msgs << I18n.t('user.import.invalid_auth_format')
      end
    end

    # Groups
    unless self.groups.nil? or self.groups.empty?

      if (/^|([0-9]+|)+$/ =~ self.groups) == 0

        self.get_groups_a.each do |group_id|
          begin
            group = Group.find(group_id)
          rescue => evar
            group = nil
          end
          if group.nil?
            err_msgs << I18n.t('user.import.not_valid_groups') + ': '+group_id.to_s
            break
          end
        end
      else
        err_msgs << I18n.t('user.import.invalid_groups_format')
      end
    end

    return err_msgs
  end

  #=== update_xorder
  #
  #Updates xorder attributes of all Users whose titles are the same
  #as specified one.
  #
  #_title_:: Target official title. Specifiy nil if all users are to update.
  #_order_:: New order index.
  #
  def self.update_xorder(title, order)

    if title.nil?
      con = nil
    else
      con = ['title=?', title]
    end

    SqlHelper.validate_token([order])
    User.where(con).update_all(xorder: order.to_i)
  end

  #=== rename_title
  #
  #Updates title attributes of corresponding Users.
  #
  #_org_title_:: Original title.
  #_new_title_:: New title.
  #
  def self.rename_title(org_title, new_title)

    con = ['title=?', org_title]

    User.where(con).update_all(title: new_title.gsub("'"){"\\'"})
  end

  #=== get_project_application
  #
  #Gets this User's Comment as an application for the project.
  #
  #_item_id_:: Item-ID of the project definition.
  #return:: Comment if exist, nil otherwise.
  #
  def get_project_application(item_id)

    SqlHelper.validate_token([item_id])

    con = "(item_id=#{item_id}) and (user_id=#{self.id}) and (xtype='#{Comment::XTYPE_APPLY}')"
    begin
      comment = Comment.where(con).first
    rescue
    end

    return comment
  end

  #=== self.create_init_user
  #
  #Creates an initial User.
  #
  def self.create_init_user

    begin
      user = User.new
      user.name = 'admin'
      user.fullname = 'Administrator'
      user.email = I18n.t('msg.specify_item')
      user.pass_md5 = UsersHelper.generate_digest_pass(user.name, 'admin')
      user.created_at = Time.now
      user.auth = User::AUTH_ALL
      user.save!
    rescue => evar
      Log.add_error(nil, evar)
#     puts evar.to_s
      return
    end

    user.setup

  rescue => evar
    Log.add_error(nil, evar)
  end

  #=== setup
  #
  #Sets up the environment for the new User.
  #
  def setup

    # My Folder
    my_folder = self.create_my_folder

    # Shortcut for My Folder on desktop
    toy = Toy.new
    toy.user_id = self.id
    toy.xtype = Toy::XTYPE_FOLDER
    toy.target_id = my_folder.id
    toy.x, toy.y = DesktopsHelper.find_empty_block(self)
    toy.save!

    # Profile Sheet
    self.create_profile_sheet

  rescue => evar
    Log.add_error(nil, evar)
  end
end
