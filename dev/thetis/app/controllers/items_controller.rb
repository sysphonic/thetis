#
#= ItemsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Items.
#
#== Note:
#
#* 
#
class ItemsController < ApplicationController
  layout 'base'

  include LoginChecker

  if $thetis_config[:menu]['req_login_items'] == '1'
    before_filter :check_login
  else
    before_filter :check_login, :except => [:index, :list, :search, :bbs, :show, :show_for_print, :get_image, :get_attachment]
  end
  before_filter :check_owner, :only => [:edit, :move, :destroy, :set_basic, :set_description, :set_image, :set_attachment, :wf_issue, :update_images_order, :update_attachments_order, :team_organize, :move_in_team_folder]
  before_filter :check_comment_registrant, :only => [:update_comment, :add_comment_attachment, :delete_comment_attachment]

  ###########################
  # Operations for entries  #
  ###########################

  #=== index
  #
  #Shows Items list as default page.
  #
  def index
    list
    render(:action => 'list')
  end

  #=== list_my_folder
  #
  #Shows list of Items in My Folder.
  #
  def list_my_folder
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    if login_user.nil?
      check_login
      return
    end

    my_folder = login_user.get_my_folder

    if my_folder.nil?
      render(:text => '')
    else
      params[:folder_id] = my_folder.id.to_s
      list
      render(:action => 'list')
    end
  end

  #=== list
  #
  #Shows list of Items.
  #This method takes input of filter, keywords, sort options
  #and pagination parameters.
  #
  def list
    if params[:action] == 'list'
      Log.add_info(request, params.inspect)
    end

    login_user = session[:login_user]

    @folder_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @folder_id = params[:thetisBoxSelKeeper].split(':').last

      if !@folder_id.nil? and @folder_id.index('+') == 0
        @folder_id[0, 1] = ''
      end
    elsif params[:folder_id].nil? or params[:folder_id].empty?
    else
      @folder_id = params[:folder_id]
    end

    unless @folder_id.nil?
      session[:folder_id] = @folder_id

      unless Folder.check_user_auth(@folder_id, login_user, 'r', true)
        flash[:notice] = 'ERROR:' + t('folder.need_auth_to_read')
      end
    end

    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if @sort_col.nil? or @sort_col.empty? or @sort_type.nil? or @sort_type.empty?
      @sort_col, @sort_type = FoldersHelper.get_sort_params(@folder_id)
    end

    folder_ids = nil
    add_con = nil

    if @folder_id.nil? and params[:find_in] != Item::FOLDER_ALL
      add_con = "(Item.folder_id != 0) and (Folder.disp_ctrl like '%|#{Folder::DISPCTRL_BBS_TOP}|%')"
    else
      case params[:find_in]
        when Item::FOLDER_ALL
          ;
        when Item::FOLDER_CURRENT
          folder_ids = @folder_id
        when Item::FOLDER_LOWER
          folder_ids = Folder.get_childs(@folder_id, nil, true, false, false)
          folder_ids.unshift(@folder_id)
        else
          folder_ids = @folder_id
      end
    end

    sql = ItemsHelper.get_list_sql(login_user, params[:keyword], folder_ids, @sort_col, @sort_type, 0, false, add_con)
    @item_pages, @items, @total_num = paginate_by_sql(Item, sql, 10)
  end

  #=== search
  #
  #Shows search result.
  #Does same as list-action except rendered rhtml.
  #
  def search
    Log.add_info(request, params.inspect)

    unless params[:select_sorting].nil? or params[:select_sorting].empty?
      sort_a = params[:select_sorting].split(' ')
      params[:sort_col] = sort_a.first
      params[:sort_type] = sort_a.last
    end

    list

    if params[:keyword].nil? or params[:keyword].empty?
      if params[:from_action].nil? or params[:from_action] == 'bbs'
        render(:action => 'bbs')
      else
        render(:action => 'list')
      end
    end
  end

  #=== bbs
  #
  #Shows list on BBS-Mode.
  #Does same as list-action except rendered rhtml.
  #
  def bbs
    Log.add_info(request, params.inspect)

    if !params[:select_sorting].nil?
      sort_a = params[:select_sorting].split(' ')
      params[:sort_col] = sort_a.first
      params[:sort_type] = sort_a.last
    end

    list
    render(:action => 'bbs')
  end

  #=== show
  #
  #Shows Item information in specified layout.
  #
  def show
    Log.add_info(request, params.inspect)

    @item = Item.find(params[:id])

    login_user = session[:login_user]

    unless @item.check_user_auth(login_user, 'r', true)

      Log.add_check(request, '[Item.check_user_auth]'+request.to_s)

      if login_user.nil?
        check_login
      else
        redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
      end
      return false
    end

    @team = @item.team
    return true
  end

  #=== show_for_print
  #
  #Shows Item information for printing.
  #
  def show_for_print
    if show
      render(:action => 'show')
    end
  end

  #=== new
  #
  #Shows page to create a new Item.
  #
  def new

    login_user = session[:login_user]

    @item = Item.new
    if params[:folder_id].nil? or params[:folder_id].empty?
      my_folder = login_user.get_my_folder
      if my_folder.nil?
        @item.folder_id = 0
      else
        @item.folder_id = my_folder.id
      end
    else
      @item.folder_id = params[:folder_id].to_i
    end
    @item.xtype= Item::XTYPE_INFO
    @item.layout = 'C'

    render(:action => 'edit')
  end

  #=== edit
  #
  #Shows page to edit Item information.
  #
  def edit
    Log.add_info(request, params.inspect)

    begin
      @item = Item.find(params[:id])
    rescue StandardError => err
      Log.add_error(request, err)
    end
  end

  #=== move
  #
  #<Ajax>
  #Moves Item to the specified Folder.
  #
  def move
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    @item = Item.find(params[:id])

    unless params[:thetisBoxSelKeeper].nil?

      folder_id = params[:thetisBoxSelKeeper].split(':').last

      if Folder.check_user_auth(folder_id, login_user, 'w', true)

        @item.update_attribute(:folder_id, folder_id)
        flash[:notice] = t('msg.move_success')
      else
        flash[:notice] = 'ERROR:' + t('folder.need_auth_to_write_in')
      end
    end

    render(:partial => 'ajax_move', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    flash[:notice] = 'ERROR:' + err.to_s[0, 64]
    render(:partial => 'ajax_move', :layout => false)
  end

  #=== move_multi
  #
  #Moves multiple Items.
  #
  def move_multi
    Log.add_info(request, params.inspect)

    if params[:check_item].nil? or params[:thetisBoxSelKeeper].nil?
      list
      render(:action => 'list')
      return
    end

    login_user = session[:login_user]
    is_admin = login_user.admin?(User::AUTH_ITEM)

    folder_id = params[:thetisBoxSelKeeper].split(':').last

    unless Folder.check_user_auth(folder_id, login_user, 'w', true)
      flash[:notice] = 'ERROR:' + t('folder.need_auth_to_write_in')

      list
      render(:action => 'list')
      return
    end

    count = 0
    params[:check_item].each do |item_id, value|
      if value == '1'

        begin
          item = Item.find(item_id)
          next if !is_admin and item.user_id != login_user.id

          item.update_attribute(:folder_id, folder_id)

        rescue StandardError => err
          Log.add_error(request, err)
        end

        count += 1
      end
    end
    flash[:notice] = t('item.moved', :count => count)

    list
    render(:action => 'list')
  end

  #=== destroy
  #
  #Deletes Item.
  #
  def destroy
    Log.add_info(request, params.inspect)

    begin
      Item.destroy(params[:id])
    rescue StandardError => err
      Log.add_error(request, err)
    end

    if params[:from_action].nil?
      render(:text => params[:id])
    else
      params.delete(:controller)
      params.delete(:action)
      params.delete(:id)
      flash[:notice] = t('msg.delete_success')
      params[:action] = params[:from_action]
      redirect_to(params)
    end
  end

  #=== destroy_multi
  #
  #Deletes multiple Items.
  #
  def destroy_multi
    Log.add_info(request, params.inspect)

    if params[:check_item].nil?
      list
      render(:action => 'list')
      return
    end

    login_user = session[:login_user]
    is_admin = login_user.admin?(User::AUTH_ITEM)

    count = 0
    params[:check_item].each do |item_id, value|
      if value == '1'

        begin
          item = Item.find(item_id)
          next if !is_admin and item.user_id != login_user.id

          item.destroy

        rescue StandardError => err
          Log.add_error(request, err)
        end

        count += 1
      end
    end
    flash[:notice] = t('item.deleted', :count => count)

    params[:folder_id] = session[:folder_id]
    list
    render(:action => 'list')
  end

  #=== duplicate
  #
  #<Ajax>
  #Duplicates Item.
  #
  def duplicate
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    copies_folder = ItemsHelper.get_copies_folder(login_user.id)

    item = Item.find(params[:id])
    if item.is_a_copy?
      flash[:notice] = 'ERROR:' + t('msg.system_error')
    else
      item.xtype = Item::XTYPE_INFO
      item.public = false
      item.title += ItemsHelper.get_next_revision(login_user.id, item.id)
      copied_item = item.copy(login_user.id, copies_folder.id, [:image, :attachment])

      flash[:notice] = "#{t('msg.save_success')}#{t('cap.suffix')}<br/>#{copied_item.title}"
    end

    render(:partial => 'common/flash_notice', :layout => false)
  end

  ######################
  # Workflow           #
  ######################

  #=== set_workflow
  #
  #<Ajax>
  #Registers Workflow information of the Item.
  #
  def set_workflow
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    @item = Item.find(params[:id])

    orders_hash = params.dup
    orders_hash.reject! { |key, value|
      key.index(/order-/) != 0
    }
    orders_hash.sort_by { |key, value|
      key.split('-').last.to_i
    }

    orders = []
    orders_hash.each do |key, value|

      orders << '|' + value.split(',').join('|') + '|'
    end
    @item.workflow.update_attribute(:users, orders.join(','))

    render(:partial => 'ajax_item_workflow', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    render(:partial => 'ajax_item_workflow', :layout => false)
  end

  ######################
  # Basic Information  #
  ######################

  #=== set_basic
  #
  #<Ajax>
  #Registers basic information of the Item.
  #
  def set_basic
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    folder_id = params[:item][:folder_id]

    unless Folder.check_user_auth(folder_id, login_user, 'w', true)
      @item = Item.new(params[:item])
      @item.errors.add_to_base t('folder.need_auth_to_write_in')
      render(:partial => 'ajax_item_basic', :layout => false)
      return
    end

    if params[:check_create_folder] == '1' and !params[:create_folder_name].empty?
      folder = Folder.new
      folder.name = params[:create_folder_name]
      folder.parent_id = folder_id
      folder.inherit_parent_auth
      folder.save!

      params[:item][:folder_id] = folder.id
    end

    if params[:check_clear_original] == '1'
      params[:item][:original_by] = nil
      params[:item][:source_id] = nil
    end

    if params[:item][:xtype] == Item::XTYPE_ZEPTAIR_DIST \
        and !login_user.admin?(User::AUTH_ZEPTAIR)
      render(:text => t('msg.need_to_be_admin'))
      return
    end

    if params[:id].nil? or params[:id].empty?
      @item = Item.new_info(folder_id)
      @item.attributes = params[:item]
      @item.user_id = login_user.id
      @item.save
    else
      @item = Item.find(params[:id])

      rename_team = false
      delete_team = false

      if @item.xtype == Item::XTYPE_PROJECT

        if params[:item][:xtype] == Item::XTYPE_PROJECT

          if params[:item][:title] != @item.title
            rename_team = true
          end

        else

          # No more Project
          delete_team = true
        end
      end

      @item.update_attributes(params[:item])

      unless @item.team.nil?

        if rename_team
          @item.team.rename @item.title
        end

        if delete_team
          begin
            @item.team.destroy
          rescue StandardError => err
            Log.add_error(request, err)
          end
        end

      end
    end
    render(:partial => 'ajax_item_basic', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)
    render(:partial => 'ajax_item_basic', :layout => false)
  end

  #################
  # Description   #
  #################

  #=== set_description
  #
  #<Ajax>
  #Registers desctiption of the Item.
  #
  def set_description
    Log.add_info(request, params.inspect)

    if params[:id].nil? or params[:id].empty?
      @item = Item.new_info(0)
      @item.attributes = params[:item]
      @item.user_id = session[:login_user].id
      @item.title = t('paren.no_title')
      @item.save
    else
      @item = Item.find(params[:id])
      @item.update_attributes(params[:item])
    end

    render(:partial => 'ajax_item_description', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)
    render(:partial => 'ajax_item_description', :layout => false)
  end

  #=== recent_descriptions
  #
  #<Ajax>
  #Gets recent descriptions to select.
  #
  def recent_descriptions
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    sql = "select distinct * from logs where user_id=#{login_user.id} and (access_path like '%/items/set_description%') and (detail like '%\"id\"=>\"#{params[:id]}\"%') order by updated_at DESC limit 0,10"
    @logs = Log.find_by_sql(sql)

    render(:partial => 'ajax_recent_descriptions', :layout => false)
  end

  ################
  # Images       #
  ################

  #=== set_image
  #
  #<Ajax>
  #Registers images of the Item.
  #
  def set_image
    Log.add_info(request, params.inspect)

    created = false

    if params[:id].nil? or params[:id].empty?
      @item = Item.new_info(0)
      @item.attributes = params[:item]
      @item.user_id = session[:login_user].id
      @item.title = t('paren.no_title')

      [:image0, :image1].each do |img|

        next if params[img].nil? or params[img][:file].size == 0

        @item.save!
        created = true
        break
      end
    else
      @item = Item.find(params[:id])
    end

    modified = false

    item_images = @item.images_without_content
    [:image0, :image1].each do |img|
      next if params[img].nil? or params[img][:file].nil? or params[img][:file].size == 0
      image = Image.new
      image.item_id = @item.id
      image.file = params[img][:file]
      image.title = params[img][:title]
      image.memo = params[img][:memo]
      image.xorder = item_images.length
      image.save!

      modified = true
      item_images << image
    end

    if modified and !created
      @item.update_attribute(:updated_at, Time.now)
    end

    render(:partial => 'ajax_item_image', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    @image = Image.new
    @image.errors.add_to_base err.to_s[0, 256]

    render(:partial => 'ajax_item_image', :layout => false)
  end

  #=== get_image
  #
  #Gets images of the Item.
  #
  def get_image
    img = Image.find(params[:id])

    if img.nil?
      redirect_to(THETIS_RELATIVE_URL_ROOT + '/404.html' )
      return
    end

    login_user = session[:login_user]

    parent_item = img.item
    if parent_item.nil? or !parent_item.check_user_auth(login_user, 'r', true)
      Log.add_check(request, '[Item.check_user_auth]'+request.to_s)
      redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
      return
    end

    response.headers["Content-Type"] = img.content_type
    response.headers["Content-Disposition"] = "inline"
    render(:text => img.content)
  end

  #=== delete_image
  #
  #<Ajax>
  #Deletes Image.
  #
  def delete_image
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    begin
      image = Image.find(params[:image_id])

      @item = Item.find(image.item_id)

      unless @item.check_user_auth(login_user, 'w', true)
        raise t('msg.need_to_be_owner')
      end

      image.destroy

      @item.update_attribute(:updated_at, Time.now)

    rescue StandardError => err
      Log.add_error(request, err)
    end

    render(:partial => 'ajax_item_image', :layout => false)
  end

  #=== edit_image_info
  #
  #<Ajax>
  #Gets Image information to edit.
  #
  def edit_image_info
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    begin
      @image = Image.find(params[:image_id])

      item = Item.find(@image.item_id)

      unless item.check_user_auth(login_user, 'w', true)
        raise t('msg.need_to_be_owner')
      end
    rescue StandardError => err
      Log.add_error(request, err)
    end
    render(:partial => 'ajax_image_info', :layout => false)
  end

  #=== update_image_info
  #
  #<Ajax>
  #Updates Image information.
  #
  def update_image_info
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    image = Image.find(params[:image_id])

    # Getting Item at first for the case of resetting the db connection by an error.
    @item = Item.find(image.item_id)

    unless @item.check_user_auth(login_user, 'w', true)
      raise t('msg.need_to_be_owner')
    end

    if !params[:image][:file].nil? and params[:image][:file].size == 0
      params[:image].delete(:file)
    end
    unless image.update_attributes(params[:image])
      @image = image
      render(:partial => 'ajax_item_image', :layout => false)
      return
    end

    @item = Item.find(image.item_id)
    @item.update_attribute(:updated_at, Time.now)

    render(:partial => 'ajax_item_image', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    @image = Image.new
    @image.errors.add_to_base err.to_s[0, 256]

    render(:partial => 'ajax_item_image', :layout => false)
  end

  #=== update_images_order
  #
  #<Ajax>
  #Updates Images' order by Ajax.
  #
  def update_images_order
    Log.add_info(request, params.inspect)

    order_ary = params[:images_order]

    item = Item.find(params[:id])

    item.images_without_content.each do |img|
      class << img
        def record_timestamps; false; end
      end

      img.update_attribute(:xorder, order_ary.index(img.id.to_s) + 1)

      class << img
        remove_method :record_timestamps
      end
    end

    render(:text => '')

  rescue StandardError => err
    Log.add_error(request, err)
    render(:text => err.to_s)
  end

  ####################
  # Attachment files #
  ####################

  #=== set_attachment
  #
  #<Ajax>
  #Registers attachment-files of the Item.
  #
  def set_attachment
    Log.add_info(request, params.inspect)

    created = false

    if params[:id].nil? or params[:id].empty?
      @item = Item.new_info(0)
      @item.attributes = params[:item]
      @item.user_id = session[:login_user].id
      @item.title = t('paren.no_title')

      [:attachment0, :attachment1].each do |attach|

        next if params[attach].nil? or params[attach][:file].nil? or params[attach][:file].size == 0

        @item.save!
        created = true
        break
      end
    else
      @item = Item.find(params[:id])
    end

    modified = false

    item_attachments = @item.attachments_without_content
    [:attachment0, :attachment1].each do |attach|
      next if params[attach].nil? or params[attach][:file].nil? or params[attach][:file].size == 0

      attachment = Attachment.create(params[attach], @item, item_attachments.length)

      modified = true
      item_attachments << attachment
    end

    if modified and !created
      @item.update_attribute(:updated_at, Time.now)
    end

    render(:partial => 'ajax_item_attachment', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    @attachment = Attachment.new
    @attachment.errors.add_to_base(err.to_s[0, 256])

    render(:partial => 'ajax_item_attachment', :layout => false)
  end

  #=== get_attachment
  #
  #Gets attachment-files of the Item.
  #
  def get_attachment
    Log.add_info(request, params.inspect)

    attach = Attachment.find(params[:id])
    if attach.nil?
      redirect_to(THETIS_RELATIVE_URL_ROOT + '/404.html')
      return
    end

    login_user = session[:login_user]

    parent_item = attach.item || ((attach.comment.nil?) ? nil : attach.comment.item)
    if parent_item.nil? or !parent_item.check_user_auth(login_user, 'r', true)
      Log.add_check(request, '[Item.check_user_auth]'+request.to_s)
      redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
      return
    end

    attach_name = attach.name

    agent = request.env['HTTP_USER_AGENT']
    unless agent.nil?
      ie_ver = nil
      agent.scan(/\sMSIE\s?(\d+)[.](\d+)/){|m|
                  ie_ver = m[0].to_i + (0.1 * m[1].to_i)
                }
      attach_name = CGI::escape(attach_name) unless ie_ver.nil?
    end

    begin
      attach_location = attach.location
    rescue
      attach_location = Attachment::LOCATION_DB   # for lower versions
    end

    if attach_location == Attachment::LOCATION_DIR

      filepath = AttachmentsHelper.get_path(attach)

      send_file(filepath, :filename => attach_name, :stream => true, :disposition => 'attachment')
    else
      send_data(attach.content, :type => (attach.content_type || 'application/octet-stream')+';charset=UTF-8', :disposition => 'attachment;filename="'+attach_name+'"')
    end
  end

  #=== delete_attachment
  #
  #<Ajax>
  #Deletes Attachment.
  #
  def delete_attachment
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    begin
      attach = Attachment.find(params[:attachment_id])

      @item = Item.find(attach.item_id)

      unless @item.check_user_auth(login_user, 'w', true)
        raise t('msg.need_to_be_owner')
      end

      attach.destroy

      @item.update_attribute(:updated_at, Time.now)

    rescue StandardError => err
      Log.add_error(request, err)
    end

    render(:partial => 'ajax_item_attachment', :layout => false)
  end

  #=== edit_attachment_info
  #
  #<Ajax>
  #Gets Attachment information to edit.
  #
  def edit_attachment_info
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    begin
      @attachment = Attachment.find(params[:attachment_id])

      item = Item.find(@attachment.item_id)

      unless item.check_user_auth(login_user, 'w', true)
        raise t('msg.need_to_be_owner')
      end
    rescue StandardError => err
      Log.add_error(request, err)
    end
    render(:partial => 'ajax_attachment_info', :layout => false)
  end

  #=== update_attachment_info
  #
  #<Ajax>
  #Updates Attachment information.
  #
  def update_attachment_info
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    attachment = Attachment.find(params[:attachment_id])

    # Getting Item at first for the case of resetting the db connection by an error.
    @item = Item.find(attachment.item_id)

    unless @item.check_user_auth(login_user, 'w', true)
      raise t('msg.need_to_be_owner')
    end

    if !params[:attachment][:file].nil? and params[:attachment][:file].size == 0
      params[:attachment].delete(:file)
    end
    unless attachment.update_attributes(params[:attachment])
      @attachment = attachment
      render(:partial => 'ajax_item_attachment', :layout => false)
      return
    end

    @item = Item.find(attachment.item_id)
    @item.update_attribute(:updated_at, Time.now)

    render(:partial => 'ajax_item_attachment', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)

    @attachment = Attachment.new
    @attachment.errors.add_to_base(err.to_s[0, 256])

    render(:partial => 'ajax_item_attachment', :layout => false)
  end

  #=== update_attachments_order
  #
  #<Ajax>
  #Updates Attachments' order by Ajax.
  #
  def update_attachments_order
    Log.add_info(request, params.inspect)

    order_ary = params[:attachments_order]

    item = Item.find(params[:id])

    item.attachments_without_content.each do |attach|
      class << attach
        def record_timestamps; false; end
      end

      attach.update_attribute(:xorder, order_ary.index(attach.id.to_s) + 1)

      class << attach
        remove_method :record_timestamps
      end
    end

    render(:text => '')

  rescue StandardError => err
    Log.add_error(request, err)
    render(:text => err.to_s)
  end

  ################
  # Messages     #
  ################

  #=== add_comment
  #
  #<Ajax>
  #Adds a message to the Item.
  #
  def add_comment
    Log.add_info(request, params.inspect)

    unless params[:comment][:file].nil?
      attach_params = { :file => params[:comment][:file] }
      params[:comment].delete(:file)
    end

    @comment = Comment.new(params[:comment])
    @comment.save!
    @item = @comment.item

    unless attach_params.nil? or attach_params[:file].size <= 0
      @comment.attachments << Attachment.create(attach_params, @comment, 0)
    end

    # Sends Mail to the owner of the item.
    # user = User.find(@item.user_id)
    # NoticeMailer.deliver_comment(user, ApplicationHelper.root_url(request)) unless user.nil?

    login_user = session[:login_user]

    case @item.xtype
      when Item::XTYPE_WORKFLOW
        @workflow = @item.workflow
        if @workflow.update_status and @workflow.decided?
          @workflow.distribute_cc
        end
        @orders = @workflow.get_orders

        render(:partial => 'ajax_workflow', :layout => false)

      when Item::XTYPE_PROJECT
        if @comment.xtype == Comment::XTYPE_APPLY

          flash[:notice] = t('msg.done_success')
          render(:partial => 'ajax_team_cancel', :layout => false)
        else
          render(:partial => 'ajax_comments', :layout => false)
        end

      else
        render(:partial => 'ajax_comments', :layout => false)
    end
  end

  #=== update_comment
  #
  #<Ajax>
  #Updates a message of the Item.
  #
  def update_comment
    Log.add_info(request, params.inspect)

    unless params[:thetisBoxEdit].empty?
      @comment = Comment.find(params[:comment_id])
      if @comment.nil?
        redirect_to(THETIS_RELATIVE_URL_ROOT + '/404.html' )
        return
      end
      @comment.message = params[:thetisBoxEdit]
      @comment.save

      @item = Item.find(@comment.item_id)
    end
    render(:partial => 'ajax_comment', :layout => false)
  end

  #=== destroy_comment
  #
  #<Ajax>
  #Deletes a message of the Item.
  #
  def destroy_comment
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    comment = Comment.find(params[:comment_id])
    @item = comment.item

    unless login_user.admin?(User::AUTH_ITEM) or \
              comment.user_id == login_user.id or \
              @item.user_id == login_user.id
      render(:text => 'ERROR:' + t('msg.need_to_be_admin'))
      return
    end

    comment.destroy

    case @item.xtype
      when Item::XTYPE_PROJECT
        if comment.xtype == Comment::XTYPE_APPLY

          flash[:notice] = t('msg.cancel_success')
          render(:partial => 'ajax_team_apply')

        else
          render(:text => '')
        end

      else
        render(:text => '')
    end
  end

  #=== add_comment_attachment
  #
  #<Ajax>
  #Attaches a file to the Comment.
  #
  def add_comment_attachment
    Log.add_info(request, params.inspect)

    unless params[:comment_file].nil?
      attach_params = { :file => params[:comment_file] }
      params.delete(:comment_file)
    end

    unless attach_params.nil? or attach_params[:file].size <= 0
      @comment = Comment.find(params[:comment_id])

      @comment.attachments << Attachment.create(attach_params, @comment, 0)
      @comment.update_attribute(:updated_at, Time.now)
    end

    render(:partial => 'ajax_comment', :layout => false)
  end

  #=== delete_comment_attachment
  #
  #<Ajax>
  #Deletes Attachment of the Comment.
  #
  def delete_comment_attachment
    Log.add_info(request, params.inspect)

    begin
      attachment = Attachment.find(params[:attachment_id])
      @comment = Comment.find(params[:comment_id])

      if attachment.comment_id == @comment.id
        attachment.destroy
        @comment.update_attribute(:updated_at, Time.now)
      end
    rescue StandardError => err
      Log.add_error(request, err)
    end

    render(:partial => 'ajax_comment', :layout => false)
  end

  #=== get_group_users
  #
  #<Ajax>
  #Gets Users in specified Group.
  #
  def get_group_users
    Log.add_info(request, params.inspect)

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].nil? and !params[:group_id].empty?
      @group_id = params[:group_id]
    end

    @users = Group.get_users @group_id

    render(:partial => 'ajax_select_users', :layout => false)
  end

  #=== wf_issue
  #
  #<Ajax>
  #Issues specified Workflow.
  #
  def wf_issue
    Log.add_info(request, params.inspect)

    begin
      @item = Item.find(params[:id])
      @workflow = @item.workflow
    rescue StandardError => err
      Log.add_error(request, err)
    end
 
    attr = {:status => Workflow::STATUS_ACTIVE, :issued_at => Time.now}
    @workflow.update_attributes(attr)

    @orders = @workflow.get_orders

    render(:partial => 'ajax_workflow', :layout => false)
  end

  #=== team_organize
  #
  #<Ajax>
  #Organizes Team.
  #
  def team_organize
    Log.add_info(request, params.inspect)

    team_id = params[:team_id]
    unless team_id.nil? or team_id.empty?
      begin
        @team = Team.find(team_id)
      rescue
        @team = nil
      ensure
        if @team.nil?
          flash[:notice] = t('team.already_deleted')
          return
        end
      end

      users = @team.get_users_a
    end 

    team_members = params[:team_members]

    created = false
    modified = false

    if team_members.nil? or team_members.empty?

      unless team_id.nil? or team_id.empty?
        # @team must not be nil.
        @team.save if modified = @team.clear_users
      end

    else

      if team_members != users

        if team_id.nil? or team_id.empty?

          item = Item.find(params[:id])

          created = true
          @team = Team.new
          @team.name = item.title
          @team.item_id = params[:id]
          @team.status = Team::STATUS_STANDBY

        else

          @team.clear_users
        end

        @team.add_users team_members
        @team.save
        @team.remove_application team_members

        modified = true 
      end
     end

    if created
      @team.create_team_folder
    end

    @item = @team.item

    if modified
      flash[:notice] = t('msg.register_success')
    end
    render(:partial => 'ajax_team_info', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)
    render(:partial => 'ajax_team_info', :layout => false)
  end

  #=== move_in_team_folder
  #
  #<Ajax>
  #Moves the Item in the Team Folder.
  #
  def move_in_team_folder
    Log.add_info(request, params.inspect)

    @item = Item.find(params[:id])

    team_folder = @item.team.get_team_folder

    @item.update_attribute(:folder_id, team_folder.id)

    flash[:notice] = t('msg.move_success')

    render(:partial => 'ajax_move_in_team_folder', :layout => false)

  rescue StandardError => err
    Log.add_error(request, err)
    render(:partial => 'ajax_move_in_team_folder', :layout => false)
  end

  #=== change_team_status
  #
  #<Ajax>
  #Changes status of the Team.
  #
  def change_team_status
    Log.add_info(request, params.inspect)

    team_id = params[:team_id]
    begin
      team = Team.find(team_id)
      team.update_attribute(:status, params[:status])

      @item = team.item

      flash[:notice] = t('msg.update_success')

    rescue StandardError => err
      Log.add_error(request, err)
      flash[:notice] = err.to_s
    end

    render(:partial => 'ajax_team_status', :layout => false)
  end

 private
  #=== check_owner
  #
  #Filter method to check if the current User is owner of the specified Item.
  #
  def check_owner
    return if params[:id].nil? or params[:id].empty? or session[:login_user].nil?

    begin
      owner_id = Item.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    login_user = session[:login_user]
    if !login_user.admin?(User::AUTH_ITEM) and owner_id != login_user.id
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end

  #=== check_comment_registrant
  #
  #Filter method to check if the current User is registrant of the specified Comment.
  #
  def check_comment_registrant
    return if session[:login_user].nil?

    begin
      owner_id = Comment.find(params[:comment_id]).user_id
    rescue
      owner_id = -1
    end
    login_user = session[:login_user]
    if !login_user.admin?(User::AUTH_ITEM) and owner_id != login_user.id
      Log.add_check(request, '[check_comment_registrant]'+request.to_s)

      flash[:notice] = t('msg.need_auth_to_access')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
