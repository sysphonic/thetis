#
#= UsersController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
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

  include LoginChecker

  before_filter :check_login, :except => [:new, :create]
  before_filter :check_owner, :only => [:edit, :update, :create_profile_sheet, :destroy_profile_sheet]

  auth_array = [:destroy, :add_to_group, :exclude_from_group, :notify, :update_auth, :export_csv, :import_csv, :configure, :create_title, :destroy_title, :rename_title, :update_titles_order, :update_zept_allowed]
  auth_array.concat([:list, :show, :search]) if $thetis_config[:menu]['disp_user_list'] != '1'
  auth_array.concat([:new, :create]) if $thetis_config[:menu]['open_user_reg'] != '1'
  before_filter :only => auth_array do |controller|
    controller.check_auth(User::AUTH_USER)
  end


  require 'digest/md5'
  require 'nkf'
  require 'cgi'
  require 'csv'


  #=== new
  #
  #Does nothing about showing empty form to create User.
  #
  def new
    Log.add_info(request, params.inspect)
  end

  #=== create
  #
  #Creates User.
  #
  def create
    Log.add_info(request, params.inspect)

    if params[:user][:birthday].nil?
      begin
        params[:user][:birthday] = params[:user][:birthday_y] + '-' + params[:user][:birthday_m] + '-' + params[:user][:birthday_d]
      rescue
      end
      params[:user].delete :birthday_y
      params[:user].delete :birthday_m
      params[:user].delete :birthday_d
    end

    @user = User.new(params[:user])

    #Initial Password
    unless params[:user].key? :password
      chars = ('a'..'z').to_a + ('1'..'9').to_a 
      newpass = Array.new(8, '').collect{chars[rand(chars.size)]}.join
      @user.password = newpass
      @user.password_confirmation = newpass
    end
    unless @user.password.nil?
      @user.pass_md5 = Digest::MD5.hexdigest(@user.password)
    end
    @user.created_at = Time.now
    @user.auth = User::AUTH_ALL if User.count <= 0

    # Official title and order to display
    titles = User.get_config_titles
    if !titles.nil? and titles.include?(@user.title)
      @user.xorder = titles.index(@user.title)
    end

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
      # Send E-mail
      NoticeMailer.deliver_welcome(@user, ApplicationHelper.root_url(request))
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

    login_user = session[:login_user]

    user_id = params[:id]
    user_id = login_user.id if user_id.nil? or user_id.empty?

    begin
      @user = User.find(user_id)
    rescue StandardError => err
      Log.add_error(request, err)
      redirect_to(:controller => 'login', :action => 'logout')
    end
    @user.password_confirmation = @user.password
  end

  #=== show
  #
  #Shows User information.
  #
  def show
    Log.add_info(request, params.inspect)

    @user = User.find(params[:id])
    if @user.nil?
      flash[:notice] = t('user.already_deleted')
    end
  end

  #=== update
  #
  #Updates User information.
  #
  def update
    Log.add_info(request, '')   # Not to show passwords.

    @user = User.find(params[:id])

    if params[:user][:birthday].nil?
      begin
        params[:user][:birthday] = params[:user][:birthday_y] + '-' + params[:user][:birthday_m] + '-' + params[:user][:birthday_d]
      rescue
      end
      params[:user].delete :birthday_y
      params[:user].delete :birthday_m
      params[:user].delete :birthday_d
    end

    unless params[:user][:password].nil?
      params[:user][:pass_md5] = Digest::MD5.hexdigest(params[:user][:password])
    end

    # Official title and order to display
    title = params[:user][:title]
    unless title.nil?
      @user.xorder = User::XORDER_MAX

      titles = User.get_config_titles
      if !titles.nil? and titles.include?(title)
        @user.xorder = titles.index(title)
      end
    end

    if @user.update_attributes(params[:user])

      flash[:notice] = t('msg.update_success')
      if session[:login_user].id == @user.id
        session[:login_user] = @user
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

    con = ['User.id > 0']
    if params[:keyword]
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        key = '%' + key + '%'
        con << "(name like '#{key}' or email like '#{key}' or fullname like '#{key}' or address like '#{key}' or organization like '#{key}' or tel1 like '#{key}' or tel2 like '#{key}' or tel3 like '#{key}' or fax like '#{key}' or url like '#{key}' or postalcode like '#{key}' or title like '#{key}' )"
      end
    end

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].nil? and !params[:group_id].empty?
      @group_id = params[:group_id]
    end
    unless @group_id.nil?
      if @group_id == '0'
        con << "((groups like '%|0|%') or (groups is null))"
      else
        con << "(groups like '%|#{@group_id}|%')"
      end
    end

    where = ''
    unless con.empty?
      where = ' where ' + con.join(' and ')
    end

    order_by = nil
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if @sort_col.nil? or @sort_col.empty? or @sort_type.nil? or @sort_type.empty?
      @sort_col = 'xorder'
      @sort_type = 'ASC'
    end

    order_by = ' order by ' + @sort_col + ' ' + @sort_type

    if @sort_col != 'xorder'
      order_by << ', xorder ASC'
    end
    if @sort_col != 'name'
      order_by << ', name ASC'
    end

    sql = 'select distinct User.* from users User'
    sql << where + order_by

    @user_pages, @users, @total_num = paginate_by_sql(User, sql, 50)
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

    if params[:check_user].nil?
      list
      render(:action => 'list')
      return
    end

    count = 0
    params[:check_user].each do |user_id, value|
      if value == '1'

        begin
          User.destroy(user_id)
        rescue StandardError => err
          Log.add_error(request, err)
        end

        count += 1
      end
    end
    flash[:notice] = count.to_s + t('user.deleted')
    redirect_to(:action => 'list')
  end

  #=== notify
  #
  #Notifies message by E-mail to specified Users.
  #
  def notify
    Log.add_info(request, params.inspect)

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

        user_admins = User.find(:all, :conditions => ["auth like '%|#{User::AUTH_USER}|%' or auth = ?", User::AUTH_ALL] )

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
    rescue StandardError => err
      Log.add_error(request, err)
    end

    if user.nil?

      render(:text => t('user.already_deleted'))
    else

      user.update_attribute(:auth, auth)

      login_user = session[:login_user]
      if login_user.id == user.id
        session[:login_user] = user
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

    if params[:thetisBoxSelKeeper].nil? or params[:thetisBoxSelKeeper].empty?
      render(:partial => 'ajax_groups', :layout => false)
      return
    end

    group_id = params[:thetisBoxSelKeeper].split(':').last
    unless group_id == '0'  # '0' for ROOT
      begin
        group = Group.find(group_id)
      rescue StandardError => err
        Log.add_error(request, err)
      ensure
        if group.nil?
          render(:partial => 'ajax_groups', :layout => false)
          return
        end
      end
    end

    begin
      @user = User.find(params[:user_id])
    rescue StandardError => err
      Log.add_error(request, err)
    end

    unless @user.nil?

      is_modified = false

      # Change, not simply Add
      unless params[:current_id] == nil or params[:current_id].empty?
        if @user.exclude_from(params[:current_id])
          is_modified = true
        end
      end

      is_modified = true if @user.add_to(group_id)

      if is_modified == true
#        @user.update_attribute(:groups, @user.groups)
        @user.save!

        login_user = session[:login_user]
        if @user.id == login_user.id
          session[:login_user] = @user
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

    if params[:group_id].nil? or params[:group_id].empty?
      render(:partial => 'ajax_groups', :layout => false)
      return
    end

    group_id = params[:group_id]

    begin
      @user = User.find(params[:id])
      unless @user.nil?
        if @user.exclude_from group_id
          @user.save 

          login_user = session[:login_user]
          if @user.id == login_user.id
            session[:login_user] = @user
          end
        end
      end
    rescue StandardError => err
      Log.add_error(request, err)
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
      case params[:enc]
        when 'SJIS'
          csv = NKF.nkf("-sW -m0", csv)
        when 'EUC-JP'
          csv = NKF.nkf("-eW -m0", csv)
        when 'UTF8'

        when 'ISO-8859-1'
          csv = Iconv.iconv('ISO-8859-1', 'UTF-8', csv)
      end
    rescue StandardError => err
      Log.add_error(request, err)
    end

    send_data csv, :type => 'application/octet-stream;charset=UTF-8', :disposition => 'attachment;filename="users.csv"'
  end

  #=== import_csv
  #
  #Imports Users' list as a CSV file.
  #
  def import_csv
    Log.add_info(request, params.inspect)

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

    @imp_errs = PseudoHash.new
    count = -1  # 0 for Header-line
    users = [] 

    opt = {
      :skip_blanks => true
    }

    csv = file.read
    begin
      case enc
        when 'SJIS'
          csv = NKF.nkf("-w -m0", csv)
        when 'EUC-JP'
          csv = NKF.nkf("-wE -m0", csv)
        when 'UTF8'
          
        when 'ISO-8859-1'
          csv = Iconv.iconv('UTF-8', 'ISO-8859-1', csv)
      end
    rescue StandardError => err
      Log.add_error(request, err)
    end

    found_update = false

    CSV.parse(csv, opt) do |row|
      unless row.first.nil?
        next if row.first.lstrip.index('#') == 0
      end

      count += 1
      next if count == 0  # for Header Line

      user = User.parse_csv_row row

      check = user.check_import mode, user_names  #, user_emails

      @imp_errs[count, true] = check unless check.empty?

      users << user

      if mode == 'update'
        update_user = all_users.find do |u|
          u.id == user.id
        end
        unless update_user.nil?
          all_users.delete update_user
          found_update = true
        end
      end
    end

    if users.empty?

      @imp_errs[0, true] = [t('user.nothing_to_import')]
    else

      if mode == 'update'

        if found_update

          user_admin = users.find do |user|
            user.admin? User::AUTH_USER
          end
          if user_admin.nil?
            @imp_errs[0, true] = [t('user.no_user_auth_import')]
          end

        else
          @imp_errs[0, true] = [t('user.nothing_to_update')]
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

        rescue StandardError => err
          @imp_errs[count, true] = [t('user.failed_to_save') + err.to_s]
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

    titles = User.get_config_titles
    titles = [] if titles.nil?
    titles << t('user.new_title')
    User.save_config_titles titles

    render(:partial => 'ajax_title', :layout => false)
  end

  #=== destroy_title
  #
  #<Ajax>
  #Destroys the specified title.
  #
  def destroy_title
    Log.add_info(request, params.inspect)

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
          User.save_config_titles titles

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
  #=== check_owner
  #
  #Filter method to check if current User is owner of specified Item.
  #
  def check_owner

    login_user = session[:login_user]

    return if params[:id].nil? or params[:id].empty? or login_user.nil?

    if !login_user.admin?(User::AUTH_USER) and params[:id] != login_user.id.to_s
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
