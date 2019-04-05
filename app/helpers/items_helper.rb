#
#= ItemsHelper
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
module ItemsHelper

  #=== self.get_next_revision
  #
  #Gets the next revision number for the specified Item-ID.
  #
  #_user_id_:: Target User-ID.
  #_source_id_:: Source Item-ID.
  #return:: Next revision number.
  #
  def self.get_next_revision(user_id, source_id)

    SqlHelper.validate_token([user_id, source_id])

    copied_items = Item.where("user_id=#{user_id.to_i} and source_id=#{source_id.to_i}").order('created_at DESC').to_a

    rev = 0
    copied_items.each do |item|
      rev_arr = item.title.scan(/[#](\d\d\d)$/)
      next if rev_arr.nil?

      rev = rev_arr.first.to_a.first.to_i
      break
    end

    return ('#' + sprintf('%03d', rev+1))
  end

  #=== self.get_copies_folder
  #
  #Gets the Copies Folder in My Folder of the specified User.
  #If not found, sets up and initializes it.
  #
  #_user_id_:: Target User-ID.
  #return:: Copies Folder.
  #
  def self.get_copies_folder(user_id)

    my_folder = User.get_my_folder(user_id)

    unless my_folder.nil?
      folder_name_quot = SqlHelper.quote(Item.copies_folder)
      con = "(parent_id=#{my_folder.id}) and (name=#{folder_name_quot})"

      begin
        copies_folder = Folder.where(con).first
      rescue
      end
      if copies_folder.nil?
        folder = Folder.new
        folder.name = Item.copies_folder
        folder.parent_id = my_folder.id
        folder.owner_id = user_id.to_i
        folder.xtype = nil
        folder.read_users = ApplicationHelper.a_to_attr([user_id])
        folder.write_users = ApplicationHelper.a_to_attr([user_id])
        folder.save!

        copies_folder = folder
      end
    end

    return copies_folder
  end

  #=== self.exists_copies_folder?
  #
  #Checks if the Copies Folder exists in My Folder.
  #
  #_user_id_:: Target User-ID.
  #return:: true if Copies Folder exists, false otherwise.
  #
  def self.exists_copies_folder?(user_id)

    my_folder = User.get_my_folder(user_id)

    unless my_folder.nil?
      folder_name_quot = SqlHelper.quote(Item.copies_folder)
      con = "(parent_id=#{my_folder.id}) and (name=#{folder_name_quot})"

      begin
        copies_folder = Folder.where(con).first
      rescue
      end
    end

    return !copies_folder.nil?
  end

  #=== self.get_list_sql
  #
  #Gets SQL for list of Items. Here is the sample of return.
  #
  #  select distinct Item.* from items Item, folders Folder
  #  where
  #      (Item.user_id = 1 or Item.public = true)
  #       and 
  #      (
  #        (Item.folder_id = 0) or (
  #                      (Item.folder_id = Folder.id) and (
  #                              (
  #                                (
  #                                  (Folder.read_users like '%|1|%')
  #                                )
  #                                 or
  #                                (
  #                                  (Folder.read_teams like '%|1|%')
  #                                )
  #                              )
  #                               or 
  #                              (
  #                                (Folder.read_users is null)
  #                                 and 
  #                                (Folder.read_groups is null)
  #                                 and 
  #                                (Folder.read_teams is null)
  #                              )
  #                          )
  #                    )
  #      )
  #       and 
  #      (
  #        (Item.folder_id = 0)
  #         or
  #        (Folder.owner_id is null)
  #         or
  #        (Folder.owner_id = 0)
  #      )
  #      order by updated_at DESC
  #
  #_user_:: User Instance for whom list will be made. If not required, specify nil.
  #_keyword_:: Search keyword. If not required, specify nil.
  #_folder_ids_:: Array of Folder-IDs. If not required, specify nil.
  #_sort_col_:: Column to be used to sort list. If specified nil, uses default('updated_at').
  #_sort_type_:: Sort type. Specify 'ASC' , 'DESC'. If specified nil, uses default('DESC').
  #_limit_num_:: Limit count to get. If without limit, specify 0.
  #_admin_:: Optional flag to apply Administrative Authority. Default = false.
  #_add_con_:: Additional condition. This parameter is added to 'where' clause with 'and'. Default = nil.
  #return:: SQL for list of Items.
  #
  def self.get_list_sql(user, keyword, folder_ids, sort_col, sort_type, limit_num, admin=false, add_con=nil)

    SqlHelper.validate_token([folder_ids, sort_col, sort_type, limit_num])

    where = ' where'

    if admin
      where << ' (Item.id > 0)' # Dummy
    else
      if user.nil?
        where << " (Item.public=#{SqlHelper.to_bool(true)})"
      else
        where << " (Item.user_id=#{user.id} or Item.public=#{SqlHelper.to_bool(true)})"
      end
    end

    unless keyword.blank?
      key_array = keyword.split(nil)
      key_array.each do |key| 
        where << ' and ' + SqlHelper.get_sql_like([:title, :summary, :description], key)
      end
    end

    # Considering about folder security.
    unless admin
      restricted = false
      where_read_users = ''
      unless user.nil?
        where_read_users = SqlHelper.get_sql_like(['Folder.read_users'], "|#{user.id}|")
      end

      array = []
      unless user.nil?
        groups = user.get_groups_a
        groups.each do |group_id|
          array << SqlHelper.get_sql_like(['Folder.read_groups'], "|#{group_id}|")
        end
      end
      where_read_groups = array.join(' or ')

      array = []
      unless user.nil?
        teams = user.get_teams_a
        teams.each do |team_id|
          array << SqlHelper.get_sql_like(['Folder.read_teams'], "|#{team_id}|")
        end
      end
      where_read_teams = array.join(' or ')

      array = []
      array << '('+where_read_users+')' unless where_read_users.empty?
      array << '('+where_read_groups+')' unless where_read_groups.empty?
      array << '('+where_read_teams+')' unless where_read_teams.empty?
      where_restrict = array.join(' or ')

      array = []
      array << '('+where_restrict+')' unless where_restrict.empty?
      array << '((Folder.read_users is null) and (Folder.read_groups is null) and (Folder.read_teams is null))'
      where_restrict = array.join(' or ')

      where << ' and ((Item.folder_id = 0) or ((Item.folder_id = Folder.id) and ('+where_restrict+')))'

      # Exclude "My Folder"s
      #where << ' and ((Item.folder_id = 0) or (Folder.owner_id is null) or (Folder.owner_id = 0))'
    end

    unless folder_ids.nil?
      folder_cons = []

      [folder_ids].flatten.each do |folder_id|
        folder_cons << "(Item.folder_id=#{folder_id})"
      end

      where << ' and (' + folder_cons.join(' or ') + ')'
    end

    unless add_con.nil? or add_con.empty?
      where << ' and (' + add_con + ')'
    end

    sort_col = 'updated_at' if sort_col.nil?
    sort_type = 'DESC' if sort_type.nil?
    order_by = ' order by ' + sort_col + ' ' + sort_type

    limit = ''
    unless limit_num.nil? or limit_num <= 0
      limit = ' limit 0,' + limit_num.to_s
    end

    sql = 'select distinct Item.* from items Item, folders Folder' + where + order_by + limit

    return sql
  end

  #=== self.sort_opts
  #
  #Returns sort options of the Items.
  #
  #_excepts_:: Array of the fields to exclude (ex. [:xorder]).
  #return:: Array of options.
  #
  def self.sort_opts(excepts)
    excepts ||= []
    opts = []
    unless excepts.include?(:xorder)
      opts << [I18n.t('sort.specified')+I18n.t('sort.asc'), 'xorder ASC']
      opts << [I18n.t('sort.specified')+I18n.t('sort.desc'), 'xorder DESC']
    end
    unless excepts.include?(:id)
      opts << [I18n.t('activerecord.attributes.id')+I18n.t('sort.asc'), 'Item.id ASC']
      opts << [I18n.t('activerecord.attributes.id')+I18n.t('sort.desc'), 'Item.id DESC']
    end
    unless excepts.include?(:title)
      opts << [Item.human_attribute_name('title')+I18n.t('sort.asc'), 'title ASC']
      opts << [Item.human_attribute_name('title')+I18n.t('sort.desc'), 'title DESC']
    end
    unless excepts.include?(:folder_id)
      opts << [I18n.t('item.folder')+I18n.t('sort.asc'), 'folder_id ASC']
      opts << [I18n.t('item.folder')+I18n.t('sort.desc'), 'folder_id DESC']
    end
    unless excepts.include?(:updated_at)
      opts << [I18n.t('activerecord.attributes.updated_at')+I18n.t('sort.asc'), 'updated_at ASC']
      opts << [I18n.t('activerecord.attributes.updated_at')+I18n.t('sort.desc'), 'updated_at DESC']
    end
    unless excepts.include?(:public)
      opts << [Item.human_attribute_name('public')+I18n.t('sort.asc'), 'public ASC']
      opts << [Item.human_attribute_name('public')+I18n.t('sort.desc'), 'public DESC']
    end
    unless excepts.include?(:user_id)
      opts << [I18n.t('item.registered_by')+I18n.t('sort.asc'), 'Item.user_id ASC']
      opts << [I18n.t('item.registered_by')+I18n.t('sort.desc'), 'Item.user_id DESC']
    end
    return opts
  end
end
