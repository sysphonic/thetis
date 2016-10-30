#
#= DesktopController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#The Action-Controller about Desktop.
#
#== Note:
#
#* 
#
class DesktopController < ApplicationController
  protect_from_forgery :except => :drop_file
  layout 'base'

  if YamlHelper.get_value($thetis_config, 'menu.req_login_desktop', nil) == '1'
    before_action :check_login
  else
    before_action :check_login, :only => [:edit_config, :update_pref, :post_label, :select_users, :get_group_users, :drop_file]
  end
  before_action :check_toy_owner, :only => [:drop_on_recyclebox, :on_toys_moved, :update_label]

  before_action :only => [:update_config] do |controller|
    controller.check_auth(User::AUTH_DESKTOP)
  end


  #=== drop_file
  #
  #Drops a file on desktop.
  #
  def drop_file
    Log.add_info(request, '')   # Not to show passwords.

    raise(RequestPostOnlyException) unless request.post?

    if params[:file].nil? or params[:file].size <= 0
      render(:plain => '')
      return
    end

    my_folder = @login_user.get_my_folder
    if my_folder.nil?
      render(:plain => 'ERROR:' + t('folder.cannot_find_my_folder'))
      return
    end

    original_filename = params[:file].original_filename
    title = ApplicationHelper.take_ncols(File.basename(original_filename, '.*'), 60, nil)

    item = Item.new_info(my_folder.id)
    item.title = title
    item.user_id = @login_user.id
    item.save!

    params[:title] ||= title
    attachment = Attachment.create(params, item, 0)

    toy = Toy.new
    toy.user_id = @login_user.id
    toy.xtype = Toy::XTYPE_ITEM
    toy.target_id = item.id
    toy.x, toy.y = DesktopsHelper.find_empty_block(@login_user)
    toy.save!

    render(:plain => t('file.uploaded'))
  end

  #=== get_schedule
  #
  #Gets today's Schedule table.
  #
  def get_schedule
    Log.add_info(request, params.inspect)

    @date = Date.parse(params[:date])

    @schedules = Schedule.get_user_day(@login_user, @date)

    render(:partial => 'schedule', :layout => false)
  end

  #=== edit_timecard
  #
  #Shows the form to edit Timecard on Desktop.
  #
  def edit_timecard
    Log.add_info(request, params.inspect)

    date_s = params[:date]

    if date_s.blank?
      @date = Date.today
      date_s = @date.strftime(Schedule::SYS_DATE_FORM)
    else
      @date = Date.parse(date_s)
    end

    @timecard = Timecard.get_by(@login_user.id, date_s)

    render(:partial => 'timecard', :layout => false)
  end

  #=== edit_config
  #
  #Shows form of Desktop configuration.
  #
  def edit_config
    Log.add_info(request, params.inspect)

    if @login_user.admin?(User::AUTH_DESKTOP)
      @yaml = ApplicationHelper.get_config_yaml
    end

    @desktop = Desktop.get_for(@login_user)

    render(:layout => (!request.xhr?))
  end

  #=== update_pref
  #
  #Updates Desktop preference.
  #
  def update_pref
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    desktop = Desktop.get_for(@login_user, true)

    params[:desktop].delete(:user_id)

    desktop.update_attributes(params.require(:desktop).permit(Desktop::PERMIT_BASE))

    params.delete(:desktop)

    show
    render(:action => 'show')
  end

  #=== update_config
  #
  #Updates Desktop configuration.
  #
  def update_config
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @yaml = ApplicationHelper.get_config_yaml

    unless params[:desktop].blank?
      params[:desktop].each do |key, val|
        YamlHelper.set_value(@yaml, ['desktop', key].join('.'), val)
      end
      ApplicationHelper.save_config_yaml(@yaml)
    end

    flash[:notice] = t('msg.update_success')
    render(:partial => 'ajax_user_before_login', :layout => false)
  end

  #=== show
  #
  #Shows empty desktop.
  #
  def show
    user = @login_user

    if user.nil?
      user = DesktopsHelper.get_user_before_login
    end

    @desktop = Desktop.get_for(user)
  end

  #=== open_desktop
  #
  #<Ajax>
  #Gets Toys (desktop items) for Login User.
  #
  def open_desktop
    Log.add_info(request, params.inspect)

    user = @login_user

    is_config_desktop = false
    if user.nil?
      user = DesktopsHelper.get_user_before_login
      is_config_desktop = true
    end

    @toys = Toy.get_for_user(user)

    if is_config_desktop
      @toys.delete_if {|toy|
        ret = false
        if toy.xtype == Toy::XTYPE_FOLDER
          begin
            folder = Folder.find(toy.target_id)
            ret = folder.my_folder?
          rescue
          end
        elsif toy.xtype == Toy::XTYPE_POSTLABEL
          ret = true
        end
        ret == true
      }
    end

    agent = request.env['HTTP_USER_AGENT']
    unless agent.nil?
      agent.scan(/\sMSIE\s?(\d+)[.](\d+)/){|m|
                  @ie_ver = m[0].to_i + (0.1 * m[1].to_i)
                }
    end

    @desktop = Desktop.get_for(user)

    render(:partial => 'ajax_get_desktop', :layout => false)
  end

  #=== get_image
  #
  #Gets the background image of the Desktop.
  #
  def get_image

    user = @login_user

    if user.nil?
      user = DesktopsHelper.get_user_before_login
    end

    desktop = Desktop.get_for(user, true)

    if desktop.nil?
      render(:plain => '')
      return
    end

    response.headers["Content-Type"] = desktop.img_content_type
    response.headers["Content-Disposition"] = "inline"
    render(:plain => desktop.img_content)
  end

  #=== get_news_tray
  #
  #<Ajax>
  #Gets Toys (desktop items) for Login User.
  #
  def get_news_tray
    Log.add_info(request, params.inspect)

    @toys = []
    desktop_toys = Toy.get_for_user(@login_user)

    deleted_arr = []

    # Item
    latests = Item.get_toys(@login_user)
    deleted_arr = DesktopsHelper.merge_toys(desktop_toys, latests, deleted_arr)
    @toys.concat(latests)

    # Comment
    latests = Comment.get_toys(@login_user)
    deleted_arr = DesktopsHelper.merge_toys(desktop_toys, latests, deleted_arr)
    @toys.concat(latests)

    # Workflow
    latests = Workflow.get_toys(@login_user)
    deleted_arr = DesktopsHelper.merge_toys(desktop_toys, latests, deleted_arr)
    @toys.concat(latests)

    # Schedule
    latests = Schedule.get_toys(@login_user)
    deleted_arr = DesktopsHelper.merge_toys(desktop_toys, latests, deleted_arr)
    @toys.concat(latests)

    deleted_arr.each do |toy|
      @toys.delete(toy)
    end

    ApplicationHelper.sort_updated_at(@toys)

    render(:partial => 'ajax_news_tray', :layout => false)
  end

  #=== drop_on_desktop
  #
  #<Ajax>
  #Receives dropped event on the desktop by Ajax.
  #
  def drop_on_desktop
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if @login_user.nil?
      t = Time.now
      render(:plain => (t.hour.to_s + t.min.to_s + t.sec.to_s))
      return
    end

    toy = Toy.new

    toy.user_id = @login_user.id
    toy.x = params[:x].to_i
    toy.y = params[:y].to_i
    toy.xtype, toy.target_id = params[:id].split(':')
    toy.save!

    render(:plain => toy.id.to_s)
  end

  #=== add_toy
  #
  #<Ajax>
  #Adds Toy on the desktop by Ajax.
  #
  def add_toy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if @login_user.nil?
      render(:plain => '0')
      return
    end

    toy = Toy.new

    toy.user_id = @login_user.id
    toy.xtype = params[:xtype]
    toy.target_id = params[:target_id].to_i
    toy.x, toy.y = DesktopsHelper.find_empty_block(@login_user)
    toy.save!

    render(:plain => toy.id.to_s)
  end

  #=== drop_on_recyclebox
  #
  #<Ajax>
  #Receives dropped event on the recyclebox by Ajax.
  #
  def drop_on_recyclebox
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    SqlHelper.validate_token([params[:id]])
    unless @login_user.nil?
      Toy.destroy(params[:id])
    end

    render(:plain => params[:id])
  end

  #=== on_toys_moved
  #
  #<Ajax>
  #Saves toys' new position by Ajax.
  #
  def on_toys_moved
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    unless @login_user.nil?
      begin
        toy = Toy.find(params[:id])
      rescue
        toy = nil
      end

      unless toy.nil?
        attrs = ActionController::Parameters.new({x: params[:x], y: params[:y]})
        toy.update_attributes(attrs.permit(Toy::PERMIT_BASE))
      end
    end

    render(:plain => '')
  end

  #=== create_label
  #
  #<Ajax>
  #Creates a label as Toy instance.
  #
  def create_label
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:thetisBoxEdit].empty?
      render(:partial => 'ajax_label', :layout => false)
      return
    end

    @toy = Toy.new

    @toy.xtype = Toy::XTYPE_LABEL
    @toy.message = params[:thetisBoxEdit]
    if @login_user.nil?
      t = Time.now
      @toy.id = (t.hour.to_s + t.min.to_s + t.sec.to_s).to_i
      @toy.x, @toy.y = DesktopsHelper.find_empty_block(@login_user)
    else
      @toy.user_id = @login_user.id
      @toy.x, @toy.y = DesktopsHelper.find_empty_block(@login_user)
      @toy.save!
    end

    render(:partial => 'ajax_label', :layout => false)
  end

  #=== update_label
  #
  #<Ajax>
  #Updates the label.
  #
  def update_label
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    msg = params[:thetisBoxEdit]

    if params[:thetisBoxEdit].empty?
      render(:partial => 'ajax_label', :layout => false)
      return
    end

    if @login_user.nil?
      @toy = Toy.new
      @toy.id = params[:id]
      @toy.xtype = Toy::XTYPE_LABEL
      @toy.x = params[:x]
      @toy.y = params[:y]
      @toy.message = msg
    else
      @toy = Toy.find(params[:id])
      @toy.update_attribute(:message, msg)
    end

    render(:partial => 'ajax_label', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
 
    render(:partial => 'ajax_label', :layout => false)
  end

  #=== show_biorhythm
  #
  #Shows Biorhythm.
  #
  def show_biorhythm
    Log.add_info(request, params.inspect)
    render(:partial => 'biorhythm', :layout => false)
  end

  #=== post_label
  #
  #<Ajax>
  #Posts a label to specified users.
  #
  def post_label
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:txaPostLabel].empty? or params[:post_to].empty?
      render(:plain => '')
      return
    end

    params[:post_to].each do |user_id|
      user = User.find(user_id)
      toy = Toy.new

      toy.xtype = Toy::XTYPE_POSTLABEL
      toy.message = params[:txaPostLabel]
      toy.user_id = user.id
      toy.posted_by = @login_user.id
      toy.x, toy.y = DesktopsHelper.find_empty_block(user)
      toy.save!
    end

    flash[:notice] = t('msg.post_success')
    render(:partial => 'common/flash_notice', :layout => false)
  end

  #=== select_users
  #
  #<Ajax>
  #Shows popup-window to select Users on Groups-Tree.
  #
  def select_users
    Log.add_info(request, params.inspect)

    render(:partial => 'select_users', :layout => false)
  end

  #=== get_group_users
  #
  #<Ajax>
  #Gets Users in specified Group.
  #
  def get_group_users
    Log.add_info(request, params.inspect)

    @group_id = nil
    if !params[:tree_node_id].nil?
      @group_id = params[:tree_node_id]
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    submit_url = url_for(:controller => 'desktop', :action => 'get_group_users')
    render(:partial => 'common/select_users', :layout => false, :locals => {:target_attr => :id, :submit_url => submit_url})
  end

 private
  #=== check_toy_owner
  #
  #Filter method to check if current User is owner of the specified Toy.
  #
  def check_toy_owner
    return if params[:id].blank? or @login_user.nil?

    begin
      owner_id = Toy.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    if !@login_user.admin?(User::AUTH_DESKTOP) and (owner_id != @login_user.id)
      Log.add_check(request, '[check_toy_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
