#
#= UsersController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2015 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Users.
#
#== Note:
#
#* 
#
class UsersController < ApplicationController
  layout 'base'

  before_filter(:check_login, :except => [:new, :create])
  before_filter(:check_owner, :only => [:edit, :update, :create_profile_sheet, :destroy_profile_sheet])

  auth_array = [:destroy, :add_to_group, :exclude_from_group, :notify, :update_auth, :export_csv, :import_csv, :configure, :create_title, :destroy_title, :rename_title, :update_titles_order, :update_zept_allowed]
  auth_array.concat([:list, :show, :search]) if $thetis_config[:menu]['disp_user_list'] != '1'
  auth_array.concat([:new, :create]) if $thetis_config[:menu]['open_user_reg'] != '1'
  before_filter :only => auth_array do |controller|
    controller.check_auth(User::AUTH_USER)
  end

  require 'digest/md5'
  require 'cgi'
  require 'csv'


  #=== new
  #
  #Does nothing about showing empty form to create User.
  #
  def new
    Log.add_info(request, params.inspect)

    render(:layout => (!request.xhr?))
  end

  #=== create
  #
  #Creates User.
  #
  def create
    Log.add_info(request, params.inspect)

    return unless request.post?

    attrs = _process_user_attrs(nil, params[:user])
    password = attrs[:password]
    attrs.delete(:password)

    @user = UsersHelper.get_initialized_user(attrs.permit(User::PERMIT_BASE))
    @user.auth = User::AUTH_ALL if User.count <= 0

    begin
      @user.save!
    rescue
      render(:controller => 'users', :action => 'new')
      return
    end

    @user.setup

    flash[:notice] = t('msg.register_success')

    if params[:from] == 'users_list'
      redirect_to(:controller => 'users', :action => 'list')
    else
      NoticeMailer.welcome(@user, password, ApplicationHelper.root_url(request)).deliver
      flash[:notice] << '<br/><span class=\'font_msg_bold\' style=\'color:firebrick;\'>'+t('user.initial_password')+'</span>'+t('msg.sent_by')+'<span class=\'font_msg_bold\'>'+t('email.name')+'</span>'+t('msg.check_it')
      redirect_to(:controller => 'login', :action => 'index')
    end
  end

  #=== edit
  #
  #Shows form to edit User information.
  #
  def edit
    Log.add_info(request, params.inspect)

    user_id = params[:id]
    user_id = @login_user.id if user_id.blank?

    begin
      @user = User.find(user_id)
    rescue => evar
      Log.add_error(request, evar)
      redirect_to(:controller => 'login', :action => 'logout')
    end
  end

  #=== show
  #
  #Shows User information.
  #
  def show
    Log.add_info(request, params.inspect)

    @user = User.find(params[:id])
    if @user.nil?
      flash[:notice] = t('msg.already_deleted', :name => User.model_name.human)
    end
    render(:layout => (!request.xhr?))
  end

  #=== update
  #
  #Updates User information.
  #
  def update
    Log.add_info(request, '')   # Not to show passwords.

    return unless request.post?

    @user = User.find(params[:id])

    attrs = _process_user_attrs(@user, params[:user])
    attrs.delete(:password)

    # Official title and order to display
    title = attrs[:title]
    unless title.nil?
      attrs[:xorder] = User::XORDER_MAX

      titles = User.get_config_titles
      if !titles.nil? and titles.include?(title)
        attrs[:xorder] = titles.index(title)
      end
    end

    if @user.update_attributes(attrs.except(:id).permit(User::PERMIT_BASE))

      flash[:notice] = t('msg.update_success')

      if @user.id == @login_user.id
        @login_user = @user
      end
      if params[:from] == 'users_list'
        redirect_to(:controller => 'users', :action => 'list')
      else
        redirect_to(:controller => 'desktop', :action => 'show')
      end
    else
      render(:controller => 'users', :action => 'edit')
    end
  end

  #=== list
  #
  #Shows Users list.
  #
  def list
    if params[:action] == 'list'
      Log.add_info(request, params.inspect)
    end

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

# Copy to FEATURE_PAGING_IN_TREE >>>
    con = ['User.id > 0']

    unless @group_id.nil?
      if @group_id == '0'
        con << "((User.groups like '%|0|%') or (User.groups is null))"
      else
        con << SqlHelper.get_sql_like(['User.groups'], "|#{@group_id}|")
      end
    end

    if params[:keyword]
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        con << SqlHelper.get_sql_like(['User.name', 'User.email', 'User.fullname', 'User.address', 'User.organization', 'User.tel1', 'User.tel2', 'User.tel3', 'User.fax', 'User.url', 'User.postalcode', 'User.title'], key)
      end
    end

    where = ''
    unless con.empty?
      where = ' where ' + con.join(' and ')
    end

    order_by = nil
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if @sort_col.blank? or @sort_type.blank?
      @sort_col = 'OfficialTitle.xorder'
      @sort_type = 'ASC'
    end

    SqlHelper.validate_token([@sort_col, @sort_type])
    order_by = @sort_col + ' ' + @sort_type

    if @sort_col == 'OfficialTitle.xorder'
      order_by = '(OfficialTitle.xorder is null) ' + @sort_type + ', ' + order_by
    else
      order_by << ', (OfficialTitle.xorder is null) ASC, OfficialTitle.xorder ASC'
    end
    if @sort_col != 'User.name'
      order_by << ', User.name ASC'
    end

    sql = 'select distinct User.* from (users User left join user_titles UserTitle on User.id=UserTitle.user_id)'
    sql << ' left join official_titles OfficialTitle on UserTitle.official_title_id=OfficialTitle.id'

    sql << where + ' order by ' + order_by

    @user_pages, @users, @total_num = paginate_by_sql(User, sql, 50)
# Copy to FEATURE_PAGING_IN_TREE <<<
  end

  #=== search
  #
  #Searches Users.
  #
  def search
    Log.add_info(request, params.inspect)

    list
    render(:action => 'list')
  end

  #=== destroy
  #
  #Deletes Users.
  #
  def destroy
    Log.add_info(request, params.inspect)

    return unless request.post?

    if params[:check_user].nil?
      list
      render(:action => 'list')
      return
    end

    count = 0
    params[:check_user].each do |user_id, value|
      if value == '1'
        SqlHelper.validate_token([user_id])
        begin
          User.destroy(user_id)
        rescue => evar
          Log.add_error(request, evar)
        end

        count += 1
      end
    end
    flash[:notice] = count.to_s + t('user.deleted')
    redirect_to(:action => 'list')
  end

  #=== select_official_titles
  #
  #Show dialog to select User's OfficialTitles.
  #
  def select_official_titles
    Log.add_info(request, params.inspect)

    @user = User.find(params[:user_id])

    unless params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    end
    SqlHelper.validate_token([@group_id])

    if @group_id.nil?
      @official_titles = OfficialTitle.get_for('0', false, true)
    else
      @official_titles = OfficialTitle.get_for(@group_id, false, true)
    end

    render(:partial => 'select_official_titles', :layout => false)
  end

  #=== add_official_titles
  #
  #Add OfficialTitles to the User.
  #
  def add_official_titles
    Log.add_info(request, params.inspect)

    return unless request.post?

    @user = User.find(params[:user_id])

    unless params[:official_titles].nil?
      params[:official_titles].each do |official_title_id|
        if @user.user_titles.index{|user_title| user_title.official_title_id.to_s == official_title_id}.nil?
          user_title = UserTitle.new
          user_title.user_id = @user.id
          user_title.official_title_id = official_title_id
          user_title.save!

          @user.user_titles << user_title
        end
      end
    end

    render(:partial => 'ajax_user_titles', :layout => false)
  end

  #=== remove_official_titles
  #
  #Add OfficialTitles to the User.
  #
  def remove_official_titles
    Log.add_info(request, params.inspect)

    return unless request.post?

    @user = User.find(params[:user_id])

    unless params[:official_titles].nil?
      params[:official_titles].each do |official_title_id|
        idx = @user.user_titles.index{|user_title| user_title.official_title_id.to_s == official_title_id}
        unless idx.nil?
          user_title = @user.user_titles[idx]
          @user.user_titles.delete(user_title)
        end
      end
    end

    render(:partial => 'ajax_user_titles', :layout => false)
  end

  #=== notify
  #
  #Notifies message by E-mail to specified Users.
  #
  def notify
    Log.add_info(request, params.inspect)

    return unless request.post?

    root_url = ApplicationHelper.root_url(request)
    count = UsersHelper.send_notification(params[:check_user], params[:thetisBoxEdit], root_url)

    if count > 0
      flash[:notice] = t('user.notification_sent')+ count.to_s + t('user.notification_sent_suffix')
    end

    redirect_to(:action => 'list')
  end

  #=== update_auth
  #
  #<Ajax>
  #Updates User's authority.
  #
  def update_auth
    Log.add_info(request, params.inspect)

    return unless request.post?

    auth = nil

    if params[:check_auth_all] == '1'

      auth = User::AUTH_ALL

    else

      auth_selected = params[:auth_selected]

      unless auth_selected.nil? or auth_selected.empty?
        auth = '|' + auth_selected.join('|') + '|'
      end

      if auth_selected.nil? or !auth_selected.include?(User::AUTH_USER)
        user_admin_err = false
        user_admins = User.where("auth like '%|#{User::AUTH_USER}|%' or auth='#{User::AUTH_ALL}'").to_a

        if user_admins.nil? or user_admins.empty?
          user_admin_err = true
        elsif user_admins.length == 1
          if user_admins.first.id.to_s == params[:id]
            user_admin_err = true
          end
        end

        if user_admin_err
          render(:text => t('user.no_user_auth'))
          return
        end
      end
    end

    begin
      user = User.find(params[:id])
    rescue => evar
      Log.add_error(request, evar)
    end

    if user.nil?
      render(:text => t('msg.already_deleted', :name => User.model_name.human))
    else
      user.update_attribute(:auth, auth)

      if user.id == @login_user.id
        @login_user = user
      end
      render(:text => '')
    end
  end

  #=== add_to_group
  #
  #<Ajax>
  #Adds User to specified Group.
  #If current_id parameter is specified, this method will Change Group,
  #that is, excludes User from current_id, then adds it to specified Group.
  #
  def add_to_group
    Log.add_info(request, params.inspect)

    return unless request.post?

    if params[:thetisBoxSelKeeper].blank?
      render(:partial => 'ajax_groups', :layout => false)
      return
    end

    group_id = params[:thetisBoxSelKeeper].split(':').last
    unless group_id == '0'  # '0' for ROOT
      begin
        group = Group.find(group_id)
      rescue => evar
        Log.add_error(request, evar)
      ensure
        if group.nil?
          render(:partial => 'ajax_groups', :layout => false)
          return
        end
      end
    end

    begin
      @user = User.find(params[:user_id])
    rescue => evar
      Log.add_error(request, evar)
    end

    unless @user.nil?

      is_modified = false

      # Change, not simply Add
      unless params[:current_id].blank?
        if @user.exclude_from(params[:current_id])
          is_modified = true
        end
      end

      is_modified = true if @user.add_to(group_id)

      if is_modified == true
        @user.save!

        if @user.id == @login_user.id
          @login_user = @user
        end
      end
    end

    render(:partial => 'ajax_groups', :layout => false)
  end

  #=== exclude_from_group
  #
  #<Ajax>
  #Excludes User from specified Group.
  #
  def exclude_from_group
    Log.add_info(request, params.inspect)

    return unless request.post?

    if params[:group_id].blank?
      render(:partial => 'ajax_groups', :layout => false)
      return
    end

    group_id = params[:group_id]

    begin
      @user = User.find(params[:id])
      unless @user.nil?
        if @user.exclude_from(group_id)
          @user.save

          if @user.id == @login_user.id
            @login_user = @user
          end
        end
      end
    rescue => evar
      Log.add_error(request, evar)
    end

    render(:partial => 'ajax_groups', :layout => false)
  end

  #=== create_profile_sheet
  #
  #<Ajax>
  #Creates Profile-sheet ("About Me").
  #
  def create_profile_sheet
    Log.add_info(request, params.inspect)

    return unless request.post?

    user_id = params[:id]
    @user = User.find(user_id)

    @item = @user.create_profile_sheet

    @user.update_attribute(:item_id, @item.id)

    render(:partial => 'ajax_profile_sheet', :layout => false)
  end

  #=== destroy_profile_sheet
  #
  #<Ajax>
  #Destroys Profile-sheet ("About Me").
  #
  def destroy_profile_sheet
    Log.add_info(request, params.inspect)

    return unless request.post?

    user_id = params[:id]
    @user = User.find(user_id)
    item_id = @user.item_id

    @user.update_attribute(:item_id, nil)

    Item.find(item_id).destroy
    @item = nil

    render(:partial => 'ajax_profile_sheet', :layout => false)
  end

  #=== export_csv
  #
  #Exports Users' list as a CSV file.
  #
  def export_csv
    Log.add_info(request, params.inspect)

    csv = User.export_csv

    begin
      csv.encode!(params[:enc], Encoding::UTF_8, {:invalid => :replace, :undef => :replace, :replace => ' '})
    rescue => evar
      Log.add_error(request, evar)
    end

    send_data(csv, :type => 'application/octet-stream;charset=UTF-8', :disposition => 'attachment;filename="users.csv"')
  end

  #=== import_csv
  #
  #Imports Users' list as a CSV file.
  #
  def import_csv
    Log.add_info(request, params.inspect)

    return unless request.post?

    file = params[:imp_file]
    mode = params[:mode]
    enc = params[:enc]

    all_users = User.find_all

    user_names = []
#   user_emails = []
    if mode == 'add'
      all_users.each do |user|
        user_names << user.name
#       user_emails << user.email
      end
    end

    @imp_errs = {}
    count = -1  # 0 for Header-line
    users = [] 

    opt = {
      :skip_blanks => true
    }

    csv = file.read
    begin
      csv.encode!(Encoding::UTF_8, enc, {:invalid => :replace, :undef => :replace, :replace => ' '})
    rescue => evar
      Log.add_error(request, evar)
    end

    found_update = false

    CSV.parse(csv, opt) do |row|
      unless row.first.nil?
        next if row.first.lstrip.index('#') == 0
      end
      next if row.compact.empty?

      count += 1
      next if count == 0  # for Header Line

      user = User.parse_csv_row(row)

      check = user.check_import(mode, user_names)  #, user_emails

      @imp_errs[count] = check unless check.empty?

      users << user

      if mode == 'update'
        update_user = all_users.find do |u|
          u.id == user.id
        end
        unless update_user.nil?
          all_users.delete(update_user)
          found_update = true
        end
      end
    end

    if users.empty?
      @imp_errs[0] = [t('user.nothing_to_import')]
    else
      if mode == 'update'
        if found_update
          user_admin = users.find do |user|
            user.admin?(User::AUTH_USER)
          end
          if user_admin.nil?
            @imp_errs[0] = [t('user.no_user_auth_import')]
          end

        else
          @imp_errs[0] = [t('user.nothing_to_update')]
        end
      end
    end

    # Create or Update
    count = 0
    @imp_cnt = 0
    if @imp_errs.empty?
      users.each do |user|
        count += 1
        begin
          user_id = user.id

          user.save!

          if user_id.nil?
            user.setup
          end

          @imp_cnt += 1

        rescue => evar
          @imp_errs[count] = [t('user.failed_to_save') + evar.to_s]
        end
      end
    end

    # Delete
    # Actually, the correct order of the process is Delete -> Create,
    # not to duplicate a User Name.
    #    3: morita   <- Delete
    #     : morita   <- Create
    # But such a case is most likely to be considered as a 
    # user's miss-operation. We can avoid this case with
    # 'opposite' process.
    del_cnt = 0
    if @imp_errs.empty? and mode == 'update'
      all_users.each do |user|
        user.destroy
        del_cnt += 1
      end
    end

    # Set order to display
    User.update_xorder(nil, User::XORDER_MAX)

    titles = User.get_config_titles
    unless titles.nil?
      idx = 0
      titles.each do |title|
        User.update_xorder title, idx
        idx += 1
      end
    end

    if @imp_errs.empty?
      flash[:notice] = users.length.to_s + t('user.imported')
      if del_cnt > 0
        flash[:notice] << '<br/>' + del_cnt.to_s + t('user.deleted')
      end
    end

    list
    render(:action => 'list')
  end

  #=== configure
  #
  #Shows configuration page about User.
  #
  def configure
    Log.add_info(request, params.inspect)

    @yaml = ApplicationHelper.get_config_yaml
  end

  #=== create_title
  #
  #<Ajax>
  #Creates a title with default name.
  #
  def create_title

    return unless request.post?

    titles = User.get_config_titles
    titles = [] if titles.nil?
    titles << t('user.new_title')
    User.save_config_titles(titles)

    render(:partial => 'ajax_title', :layout => false)
  end

  #=== destroy_title
  #
  #<Ajax>
  #Destroys the specified title.
  #
  def destroy_title
    Log.add_info(request, params.inspect)

    return unless request.post?

    title = params[:title]

    titles = User.get_config_titles
    unless titles.nil?
      titles.delete(title)
      User.save_config_titles titles
    end

    User.update_xorder(title, User::XORDER_MAX)
    idx = 0
    unless titles.nil?
      titles.each do |title|
        User.update_xorder(title, idx)
        idx += 1
      end
    end

    render(:partial => 'ajax_title', :layout => false)
  end

  #=== rename_title
  #
  #<Ajax>
  #Renames the specified title.
  #
  def rename_title
    Log.add_info(request, params.inspect)

    return unless request.post?

    org_title = params[:org_title]
    new_title = params[:new_title]

    if org_title.nil? or new_title.nil? or org_title == new_title
      render(:partial => 'ajax_title', :layout => false)
      return
    end

    titles = User.get_config_titles
    unless titles.nil?
      if titles.include?(new_title)
        flash[:notice] = 'ERROR:' + t('user.title_duplicated')
      else
        idx = titles.index(org_title)
        unless idx.nil?
          titles[idx] = new_title
          User.save_config_titles(titles)

          User.rename_title(org_title, new_title)
          User.update_xorder(new_title, idx)
        end
      end
    end

    render(:partial => 'ajax_title', :layout => false)
  end

  #=== update_titles_order
  #
  #<Ajax>
  #Updates titles' order.
  #
  def update_titles_order
    Log.add_info(request, params.inspect)

    return unless request.post?

    titles = params[:titles_order]

    org_order = User.get_config_titles
    org_order = [] if org_order.nil?

    User.save_config_titles(titles)

    idx = 0
    titles.each do |title|
      if title != org_order[idx]
        User.update_xorder(title, idx)
      end
      idx += 1
    end
    render(:text => '')
  end

  #=== update_zept_allowed
  #
  #<Ajax>
  #Updates availability of Zeptair VPN Connection for User.
  #
  def update_zept_allowed
    Log.add_info(request, params.inspect)

    return unless request.post?

    user = User.find(params[:id])
    zept_allowed = params[:zept_allowed]

    if zept_allowed == 'true'
      unless user.allowed_zept_connect?
        user.update_attribute(:zeptair_id, User::ZEPTID_PLACE_HOLDER)
      end
    else
      if user.allowed_zept_connect?
        user.update_attribute(:zeptair_id, nil)
        post_item = ZeptairPostHelper.get_item_for(user, false)
        post_item.destroy unless post_item.nil?
      end
    end

    render(:text => '')
  end

 private
  #=== _process_user_attrs
  #
  #Processes User attributes in the request parameters.
  #
  #_user_:: Target User.
  #_attrs_:: Hash of the attributes.
  #return:: Hash of the attributes.
  #
  def _process_user_attrs(user, attrs)

    if attrs[:birthday].nil?
      begin
        attrs[:birthday] = attrs[:birthday_y] + '-' + attrs[:birthday_m] + '-' + attrs[:birthday_d]
      rescue
      end
      attrs.delete(:birthday_y)
      attrs.delete(:birthday_m)
      attrs.delete(:birthday_d)
    end

    if !attrs[:name].nil? or !attrs[:password].nil?
      user_name = attrs[:name]
      user_name ||= user.name unless user.nil?
      password = attrs[:password]
      if password.blank?
        password = UsersHelper.generate_password
        attrs[:password] = password
      end
      attrs[:pass_md5] = UsersHelper.generate_digest_pass(user_name, password)
    end
    return attrs
  end

  #=== check_owner
  #
  #Filter method to check if current User is owner of specified Item.
  #
  def check_owner

    return if params[:id].nil? or params[:id].empty? or @login_user.nil?

    if !@login_user.admin?(User::AUTH_USER) and params[:id] != @login_user.id.to_s
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
