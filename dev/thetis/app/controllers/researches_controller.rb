#
#= ResearchesController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Researches.
#
#== Note:
#
#* 
#
class ResearchesController < ApplicationController
  layout 'base', :except => :index

  before_filter :check_login, :except => [:index]
  before_filter :except => [:index, :show_receipt, :edit_page, :save_page, :do_confirm] do |controller|
    controller.check_auth(User::AUTH_RESEARCH)
  end

  require 'fileutils'


  #=== index
  #
  #Shows index-page of Research.
  #
  def index
    Log.add_info(request, params.inspect)

    if Research.get_status == Research::STATUS_STARTED
      redirect_to(:action => 'edit_page')
    else
      render(:action => 'index', :layout => 'title')
    end
  end

  #=== settings
  #
  #Shows setting-page.
  #
  def settings
    if params[:action] == 'settings'
      Log.add_info(request, params.inspect)
    end

    tmpl_folder, @tmpl_q_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_RESEARCH)

    if @tmpl_q_folder.nil?
      ary = TemplatesHelper.setup_tmpl_folder
      @tmpl_q_folder = ary[4]
    end

    @items = Folder.get_items_admin(@tmpl_q_folder.id, 'xorder ASC')

    @group_ids = Research.get_statistics_groups

    @q_hash = {}
    unless @items.nil?
      @items.each do |item|
        hash = Research.find_q_codes(item.description)

        hash.each do |q_code, q_params_h|
          q_params_h = Hash.new if q_params_h.nil?
          q_params_h[:item_id] = item.id
          q_params_h[:item_title] = item.title
          hash[q_code] = q_params_h
        end

        Research.select_q_caps(item.description).each do |q_code, cap|
          if hash.key?(q_code) and hash[q_code][:caption].nil?
            hash[q_code][:caption] = cap
          end
        end

        hash.each do |key, val|
          @q_hash[key] = val
        end
      end
    end

    Research.trim_config_yaml(@q_hash.keys)

  rescue => evar
    Log.add_error(request, evar)
  end

  #=== create_q_page
  #
  #<Ajax>
  #Creates a template in 'Research' Folder with default name.
  #
  def create_q_page
    Log.add_info(request, params.inspect)

    @tmpl_folder, @tmpl_q_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_RESEARCH)

    unless @tmpl_q_folder.nil?

      @items = Folder.get_items_admin(@tmpl_q_folder.id, 'xorder ASC')

      if !@items.nil? and @items.length >= ResearchesHelper::MAX_PAGES
        flash[:notice] = 'ERROR:' + t('research.max_pages')
        render(:partial => 'ajax_q_page', :layout => false)
        return
      end

      item = Item.new_research(@tmpl_q_folder.id)
      item.title = t('research.new_page')
      item.user_id = 0
      item.save!

      @items << item

    else
      Log.add_error(request, nil, '/'+TemplatesHelper::TMPL_ROOT+'/'+TemplatesHelper::TMPL_RESEARCH+' NOT found!')
    end

    render(:partial => 'ajax_q_page', :layout => false)
  end

  #=== destroy_q_page
  #
  #<Ajax>
  #Destroys specified research page template.
  #
  def destroy_q_page
    Log.add_info(request, params.inspect)

    begin
      Item.find(params[:id]).destroy
    rescue
    end

    # Get $Templates and its sub folders to update partial division.
    @tmpl_folder, @tmpl_q_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_RESEARCH)

    @items = Folder.get_items_admin(@tmpl_q_folder.id, 'xorder ASC')

    render(:partial => 'ajax_q_page', :layout => false)
  end

  #=== update_q_ctrl
  #
  #<Ajax>
  #Updates controls of choices.
  #
  def update_q_ctrl
    Log.add_info(request, params.inspect)

    item_id = params[:item_id]
    q_code = params[:q_code]
    q_param = params[:q_param]
    cap = params[:caption]

    yaml = Research.get_config_yaml

    type = q_param.split(':').first
    vals = q_param[type.length+1 .. -1]

    yaml[q_code] = {:item_id => item_id, :type => type, :values => vals, :caption => cap.to_s }

    Research.save_config_yaml yaml

    render(:text => '')

  rescue => evar
    Log.add_error(request, evar)
    render(:text => evar.to_s)
  end

  #=== reset_q_ctrl
  #
  #<Ajax>
  #Resets controls of choices.
  #
  def reset_q_ctrl
    Log.add_info(request, params.inspect)

    Research.trim_config_yaml nil

    settings

    render(:partial => 'ajax_q_ctrls')

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_q_ctrls')
  end

  #=== renew_q_ctrl
  #
  #<Ajax>
  #Renews controls of choices.
  #
  def renew_q_ctrl
    Log.add_info(request, params.inspect)

    settings

    render(:partial => 'ajax_q_ctrls')

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_q_ctrls')
  end

  #=== add_statistics_group
  #
  #<Ajax>
  #Adds Group for statistics.
  #
  def add_statistics_group
    Log.add_info(request, params.inspect)

    current_id = params[:current_id]

    if !params[:thetisBoxSelKeeper].nil?
      group_id = params[:thetisBoxSelKeeper].split(':').last
    end

    if group_id.nil? or group_id.empty?
      @group_ids = Research.get_statistics_groups 
      render(:partial => 'ajax_statistics_groups', :layout => false)
      return
    end

    unless current_id.nil? or current_id.empty?
      Research.delete_statistics_group current_id
    end

    @group_ids = Research.add_statistics_group group_id

    render(:partial => 'ajax_statistics_groups', :layout => false)
  end

  #=== delete_statistics_group
  #
  #<Ajax>
  #Deletes Group for statistics.
  #
  def delete_statistics_group
    Log.add_info(request, params.inspect)

    group_id = params[:group_id]

    if group_id.nil? or group_id.empty?
      @group_ids = Research.get_statistics_groups 
      render(:partial => 'ajax_statistics_groups', :layout => false)
      return
    end

    @group_ids = Research.delete_statistics_group group_id

    render(:partial => 'ajax_statistics_groups', :layout => false)
  end

  #=== update_groups_order
  #
  #<Ajax>
  #Updates Groups' order for statistics.
  #
  def update_groups_order
    Log.add_info(request, params.inspect)

    order_ary = params[:groups_order]

    Research.set_statistics_groups order_ary

    render(:text => '')
  end

  #=== start
  #
  #<Ajax>
  #Starts the questionnaire.
  #
  def start
    Log.add_info(request, params.inspect)

    tmpl_folder, tmpl_q_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_RESEARCH)

    if tmpl_q_folder.nil?
      ary = TemplatesHelper.setup_tmpl_folder
      tmpl_q_folder = ary[4]
    end

    items = Folder.get_items_admin(tmpl_q_folder.id, 'xorder ASC')
 
    if items.nil? or items.empty?

      render(:text => t('research.create_page_first'))
      return
    else

      ApplicationHelper.delete_file_safe(Research.get_pages)

      items.each_with_index do |item, idx|
        desc = item.description
        if desc.nil? or desc.empty?
          render(:text => t('research.specify_page_content') + item.title.to_s)
          return
        end

        q_hash = Research.find_q_codes(desc)
        q_hash.each do |q_code, q_param|
          desc = Research.replaceCtrl(desc, q_code, q_param)
        end

        FileUtils.mkdir_p(Research.page_dir)

        file_name = sprintf('_q%02d.html.erb', idx+1)
        path = File.join(Research.page_dir, file_name)

        ApplicationHelper.f_ensure_exist(path)
        mode = ApplicationHelper.f_chmod(0666, path)

        begin
          f = File.open(path, 'w')
          f.write(desc)
          f.close
        rescue => evar
          logger.fatal(evar.to_s)
        end

        ApplicationHelper.f_chmod(mode, path)
      end
    end

    render(:text => '')

  rescue => evar
    Log.add_error(request, evar)
    render(:text => evar.to_s)
  end

  #=== stop
  #
  #<Ajax>
  #Stops the questionnaire.
  #
  def stop
    Log.add_info(request, params.inspect)

    ApplicationHelper.delete_file_safe(Research.get_pages)
    render(:text => '')

  rescue => evar
    Log.add_error(request, evar)
    render(:text => evar.to_s)
  end

  #=== reset
  #
  #<Ajax>
  #Resets all Users' status.
  #
  def reset
    Log.add_info(request, params.inspect)

    Research.delete_all

    render(:text => '')

  rescue => evar
    Log.add_error(request, evar)
    render(:text => evar.to_s)
  end

  #=== reset_users
  #
  #Resets status of the selected Users.
  #
  def reset_users
    Log.add_info(request, params.inspect)

    count = 0

    unless params[:check_user].nil?

      params[:check_user].each do |user_id, value|
        if value == '1'
          begin
            Research.destroy_all('user_id=' + user_id.to_s)
            count += 1
          rescue => evar
            Log.add_error(request, evar)
          end
        end
      end
    end

    if count > 0
      flash[:notice] = t('msg.status_of')+ count.to_s + t('user.status_reset')
    end

    redirect_to(:controller => 'researches', :action => 'users')

  rescue => evar
    Log.add_error(request, evar)
    render(:text => evar.to_s)
  end

  #=== show_receipt
  #
  #Shows receipt-page.
  #
  def show_receipt
  end

  #=== edit_page
  #
  #Shows page of the questionnaire.
  #
  def edit_page

    # Saved contents of Login User
    begin
      @research = Research.find(:first, :conditions => ['user_id=?', @login_user.id])
    rescue
    end
    if @research.nil?
      @research = Research.new
    else
      # Already accepted?
      if !@research.status.nil? and @research.status != 0
        render(:action => 'show_receipt')
        return
      end
    end

    # Specifying page
    @page = '01'
    unless params[:page].nil? or params[:page].empty?
      @page = params[:page]
    end
  end

  #=== save_page
  #
  #Saves current page and shows next or receipt-page.
  #
  def save_page
    Log.add_info(request, params.inspect)

    # Next page
    pave_val = params[:page].to_i + 1
    @page = sprintf('%02d', pave_val)

    page_num = Dir.glob(File.join(Research.page_dir, "_q[0-9][0-9].html.erb")).length

    unless params[:research].nil?
      params[:research].each do |key, value|
        if value.instance_of?(Array)
          value.compact!
          value.delete('')
          if value.empty?
            params[:research][key] = nil
          else
            params[:research][key] = value.join("\n") + "\n"
          end
        end
      end
    end

    if params[:research_id].nil? or params[:research_id].empty?
      @research = Research.new(params.require(:research).permit(Research::PERMIT_BASE))
      @research.status = Research::U_STATUS_IN_ACTON
      @research.update_attribute(:user_id, @login_user.id)
    else
      @research = Research.find(params[:research_id])
      @research.update_attributes(params.require(:research).permit(Research::PERMIT_BASE))
    end

    if pave_val <= page_num

      render(:action => 'edit_page')

    else

      tmpl_folder, tmpl_q_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_RESEARCH)

      if tmpl_q_folder.nil?
        ary = TemplatesHelper.setup_tmpl_folder
        tmpl_q_folder = ary[4]
      end

      items = Folder.get_items_admin(tmpl_q_folder.id, 'xorder ASC')

      @q_caps_h = {}
      unless items.nil?
        items.each do |item|

          desc = item.description
          next if desc.nil? or desc.empty?

          hash = Research.select_q_caps(desc)
          hash.each do |key, val|
            @q_caps_h[key] = val
          end
        end
      end

      render(:action => 'confirm')
    end

  rescue => evar
    Log.add_error(request, evar)
    @page = '01'
    render(:action => 'edit_page')
  end

  #=== do_confirm
  #
  #Receives User's confirmation and commit answers.
  #
  def do_confirm
    Log.add_info(request, params.inspect)

    @research = Research.find(params[:research_id])
    @research.update_attribute(:status, Research::U_STATUS_COMMITTED)

    render(:action => 'show_receipt')

  rescue => evar
    Log.add_error(request, evar)
    render(:action => 'edit_page')
  end

  #=== users
  #
  #Shows list of Users and their status.
  #
  def users
    Log.add_info(request, params.inspect)

    con = []

    if params[:keyword]
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        key = "\'%" + key + "%\'"
        con << "(name like #{key} or email like #{key} or fullname like #{key} or address like #{key} or organization like #{key})"
      end
    end

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].nil? and !params[:group_id].empty?
      @group_id = params[:group_id]
    end
    unless @group_id.nil?
      con << "(groups like '%|#{@group_id}|%')"
    end

    include_research = false

    filter_status = params[:filter_status]

    unless filter_status.nil? or filter_status.empty?
      case filter_status
        when Research::U_STATUS_IN_ACTON.to_s, Research::U_STATUS_COMMITTED.to_s
          con << "((Research.user_id=User.id) and (Research.status=#{filter_status}))"
          include_research = true
        when (-1).to_s
          researches = Research.find(:all)
          except_users = []
          unless researches.nil?
            researches.each do |research|
              except_users << research.user_id
            end
          end
          unless except_users.empty?
            con << '(User.id not in (' + except_users.join(',') + '))'
          end
        else
          ;
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
      @sort_col = 'id'
      @sort_type = 'ASC'
    end
    order_by = ' order by ' + @sort_col + ' ' + @sort_type

    sql = 'select distinct User.* from users User'
    if include_research
      sql << ', researches Research'
    end
    sql << where + order_by

    @user_pages, @users, @total_num = paginate_by_sql(User, sql, 50)
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

    redirect_to(:action => 'users')
  end

  #=== statistics
  #
  #Shows statistics.
  #
  def statistics
    Log.add_info(request, params.inspect)

    tmpl_folder, tmpl_q_folder = TemplatesHelper.get_tmpl_subfolder(TemplatesHelper::TMPL_RESEARCH)

    if tmpl_q_folder.nil?
      ary = TemplatesHelper.setup_tmpl_folder
      tmpl_q_folder = ary[4]
    end

    @q_codes = []

    items = Folder.get_items_admin(tmpl_q_folder.id, 'xorder ASC')

    if items.nil? or items.empty?

      @q_codes = Research.get_q_codes
    else

      items.each do |item|
        desc = item.description
        unless desc.nil? or desc.empty?
          q_hash = Research.find_q_codes(desc)
          @q_codes.concat q_hash.keys unless q_hash.nil?
        end
      end
    end

    @q_hash = Research.get_config_yaml

    @sum_groups = Research.get_statistics_groups

    con = ['status=?', Research::U_STATUS_COMMITTED]
    researches = Research.find(:all, :conditions => con)

    unless researches.nil? or researches.empty?

      @ans_hash = {}   # q_code => user_id => Answer

      @q_codes.each do |q_code|
        @ans_hash[q_code] = {}
      end

      researches.each do |research|
        @q_codes.each do |q_code|
          @ans_hash[q_code][research.user_id] = research.get_by_q_code(q_code)
        end
      end
    end
  end

  #=== get_records_group
  #
  #<Ajax>
  #Gets records by Group.
  #
  def get_records_group
    Log.add_info(request, params.inspect)

    where = ' where Research.status=' + Research::U_STATUS_COMMITTED.to_s

    unless params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last

      group_cons = []

      if @group_id != '0'
        group_cons << "(User.groups like '%|#{@group_id}|%')"

        # Group.get_childs(@group_id, true, false).each do |g_id|
        #   group_cons << "(User.groups like '%|#{g_id}|%')"
        # end

        where << ' and (Research.user_id = User.id)'
        where << ' and (' + group_cons.join(' or ') + ')'
      end
    end

    sql = 'select distinct Research.* from researches Research, users User' + where

    @researches = Research.find_by_sql(sql)

    q_hash = Research.get_config_yaml

    unless q_hash.nil? or q_hash.empty?
      @q_codes = q_hash.keys
      @q_codes.delete_if{ |q_code|
            !q_code.instance_of?(String) or q_code.match(/^q\d{2}_\d{2}$/).nil?
          }
      @q_codes.sort!
    end

    render(:partial => 'ajax_statistics_records', :layout => false)
  end

  #=== graph
  #
  #Shows graph.
  #
  def graph
    Log.add_info(request, params.inspect)

    begin
      require 'gruff'
    rescue => evar
      Log.add_error(request, evar)
      return
    end

    g = Gruff::Pie.new 300
    g.title = params[:title]
    g.theme_37signals

    params[:vote].each do |vote, num|
      g.data(vote, [num])
    end
    send_data(g.to_blob, :type => 'image/png')

  rescue => evar
    Log.add_error(request, evar)
  end
end
