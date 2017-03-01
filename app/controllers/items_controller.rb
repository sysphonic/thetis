#
#= ItemsController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#The Action-Controller about Items.
#
#== Note:
#
#* 
#
class ItemsController < ApplicationController
  layout 'base'

  if YamlHelper.get_value($thetis_config, 'menu.req_login_items', nil) == '1'
    before_action :check_login
  else
    before_action :check_login, :except => [:index, :list, :search, :bbs, :show, :show_for_print, :get_image, :get_attachment]
    before_action :allow_midair_login, :only => [:get_attachment]
  end
  before_action :check_owner, :only => [:edit, :move, :destroy, :set_basic, :set_description, :set_image, :set_attachment, :wf_issue, :update_images_order, :update_attachments_order, :team_organize]  # :move_in_team_folder
  before_action :check_comment_registrant, :only => [:update_comment, :add_comment_attachment, :delete_comment_attachment]


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

    if @login_user.nil?
      check_login
      return
    end

    my_folder = @login_user.get_my_folder

    if my_folder.nil?
      render(:plain => '')
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

    @folder_id = nil
    if !params[:tree_node_id].nil?
      @folder_id = params[:tree_node_id]

      if !@folder_id.nil? and @folder_id.index('+') == 0
        @folder_id[0, 1] = ''
      end
    elsif params[:folder_id].blank?
    else
      @folder_id = params[:folder_id]
    end
    SqlHelper.validate_token([@folder_id])

    unless @folder_id.nil?
      session[:folder_id] = @folder_id

      unless Folder.check_user_auth(@folder_id, @login_user, 'r', true)
        flash[:notice] = 'ERROR:' + t('folder.need_auth_to_read')
      end
    end

# Copy to FEATURE_PAGING_IN_TREE >>>
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if @sort_col.blank? or @sort_type.blank?
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
          folder_ids = [@folder_id]
        when Item::FOLDER_LOWER
          folder_ids = Folder.get_childs(@folder_id, nil, true, false, false)
          folder_ids.unshift(@folder_id)
        else
          folder_ids = [@folder_id]
      end
      unless folder_ids.nil?
        delete_arr = []
        folder_ids.each do |folder_id|
          unless Folder.check_user_auth(folder_id, @login_user, 'r', true)
            delete_arr << folder_id
          end
        end
        folder_ids -= delete_arr unless delete_arr.empty?
      end
    end

    sql = ItemsHelper.get_list_sql(@login_user, params[:keyword], folder_ids, @sort_col, @sort_type, 0, false, add_con)
    @item_pages, @items, @total_num = paginate_by_sql(Item, sql, 10)
# Copy to FEATURE_PAGING_IN_TREE <<<
  end

  #=== search
  #
  #Shows search result.
  #Does same as list-action except rendered rhtml.
  #
  def search
    Log.add_info(request, params.inspect)

    unless params[:select_sorting].blank?
      sort_a = params[:select_sorting].split(' ')
      params[:sort_col] = sort_a.first
      params[:sort_type] = sort_a.last
    end

    list

    if params[:keyword].blank?
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

    unless params[:select_sorting].nil?
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

    unless @item.check_user_auth(@login_user, 'r', true)

      Log.add_check(request, '[Item.check_user_auth]'+params.inspect)

      if @login_user.nil?
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

    @item = Item.new
    if params[:folder_id].blank?
      my_folder = @login_user.get_my_folder
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
    rescue => evar
      @item = nil
      Log.add_error(request, evar)
    end
  end

  #=== move
  #
  #<Ajax>
  #Moves Item to the specified Folder.
  #
  def move
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @item = Item.find(params[:id])

    unless params[:tree_node_id].nil?

      folder_id = params[:tree_node_id]

      if Folder.check_user_auth(folder_id, @login_user, 'w', true)

        @item.update_attribute(:folder_id, folder_id)
        flash[:notice] = t('msg.move_success')
      else
        flash[:notice] = 'ERROR:' + t('folder.need_auth_to_write_in')
      end
    end

    render(:partial => 'ajax_move', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    flash[:notice] = 'ERROR:' + evar.to_s[0, 64]
    render(:partial => 'ajax_move', :layout => false)
  end

  #=== move_multi
  #
  #Moves multiple Items.
  #
  def move_multi
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:check_item].nil? or params[:tree_node_id].nil?
      list
      render(:action => 'list')
      return
    end

    is_admin = @login_user.admin?(User::AUTH_ITEM)

    folder_id = params[:tree_node_id]
    SqlHelper.validate_token([folder_id])

    unless Folder.check_user_auth(folder_id, @login_user, 'w', true)
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
          next if !is_admin and item.user_id != @login_user.id

          item.update_attribute(:folder_id, folder_id)

        rescue => evar
          item = nil
          Log.add_error(request, evar)
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

    raise(RequestPostOnlyException) unless request.post?

    begin
      Item.destroy(params[:id])
    rescue => evar
      Log.add_error(request, evar)
    end

    if params[:from_action].nil?
      render(:plain => params[:id])
    else
      flash[:notice] = t('msg.delete_success')
      self.send(params[:from_action])
    end
  end

  #=== destroy_multi
  #
  #Deletes multiple Items.
  #
  def destroy_multi
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:check_item].nil?
      list
      render(:action => 'list')
      return
    end

    is_admin = @login_user.admin?(User::AUTH_ITEM)

    count = 0
    params[:check_item].each do |item_id, value|
      if value == '1'

        begin
          item = Item.find(item_id)
          next if !is_admin and item.user_id != @login_user.id

          item.destroy

        rescue => evar
          Log.add_error(request, evar)
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

    raise(RequestPostOnlyException) unless request.post?

    copies_folder = ItemsHelper.get_copies_folder(@login_user.id)

    item = Item.find(params[:id])
    if item.is_a_copy?
      flash[:notice] = 'ERROR:' + t('msg.system_error')
    else
      item.xtype = Item::XTYPE_INFO
      item.public = false
      item.title += ItemsHelper.get_next_revision(@login_user.id, item.id)
      copied_item = item.copy(@login_user.id, copies_folder.id, [:image, :attachment])

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

    raise(RequestPostOnlyException) unless request.post?

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
      user_ids = value.split(',')
      SqlHelper.validate_token([user_ids])

      orders << ApplicationHelper.a_to_attr(user_ids)
    end
    @item.workflow.update_attribute(:users, orders.join(','))

    render(:partial => 'edit_item_workflow', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    render(:partial => 'edit_item_workflow', :layout => false)
  end

  #=== set_basic
  #
  #<Ajax>
  #Registers basic information of the Item.
  #
  def set_basic
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:item][:xtype] == Item::XTYPE_ZEPTAIR_DIST \
        and !@login_user.admin?(User::AUTH_ZEPTAIR)
      render(:plain => t('msg.need_to_be_admin'))
      return
    end

    folder_id = params[:item][:folder_id]

    unless Folder.check_user_auth(folder_id, @login_user, 'w', true)
      @item = Item.new(params.require(:item).permit(Item::PERMIT_BASE))
      @item.errors.add_to_base t('folder.need_auth_to_write_in')
      render(:partial => 'edit_item_basic', :layout => false)
      return
    end

    if (params[:check_create_folder] == '1') and !params[:create_folder_name].empty?
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

    if params[:id].blank?
      @item = Item.new_info(folder_id)
      @item.attributes = params.require(:item).permit(Item::PERMIT_BASE)
      @item.user_id = @login_user.id
      @item.save
    else
      @item = Item.find(params[:id])

      rename_team = false
      delete_team = false
      delete_zept_cmd = false

      if @item.xtype == Item::XTYPE_PROJECT

        if params[:item][:xtype] == Item::XTYPE_PROJECT
          if params[:item][:title] != @item.title
            rename_team = true
          end
        else
          # No more Project
          delete_team = true
        end
      elsif @item.xtype == Item::XTYPE_ZEPTAIR_DIST \
              and params[:item][:xtype] != Item::XTYPE_ZEPTAIR_DIST
        delete_zept_cmd = true
      end

      @item.update_attributes(params.require(:item).permit(Item::PERMIT_BASE))

      unless @item.team.nil?
        if rename_team
          @item.team.rename(@item.title)
        end

        if delete_team
          begin
            @item.team.destroy
          rescue => evar
            Log.add_error(request, evar)
          end
        end
      end

      unless @item.zeptair_command
        if delete_zept_cmd
          begin
            @item.zeptair_command.destroy
          rescue => evar
            Log.add_error(request, evar)
          end
        end
      end
    end

    if @item.xtype == Item::XTYPE_ZEPTAIR_DIST
      if @item.zeptair_command.nil?
        @item.zeptair_command = ZeptairCommand.new
      end
      params[:zeptair_command].delete(:item_id)
      @item.zeptair_command.attributes = params[:zeptair_command]
      if @item.zeptair_command.changed?
        @item.zeptair_command.save!
      end
    end

    render(:partial => 'edit_item_basic', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'edit_item_basic', :layout => false)
  end

  #=== set_description
  #
  #<Ajax>
  #Registers desctiption of the Item.
  #
  def set_description
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:id].blank?
      @item = Item.new_info(0)
      @item.attributes = params.require(:item).permit(Item::PERMIT_BASE)
      @item.user_id = @login_user.id
      @item.title = t('paren.no_title')
      @item.save
    else
      @item = Item.find(params[:id])
      @item.update_attributes(params.require(:item).permit(Item::PERMIT_BASE))
    end

    render(:partial => 'edit_item_description', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'edit_item_description', :layout => false)
  end

  #=== recent_descriptions
  #
  #<Ajax>
  #Gets recent descriptions to select.
  #
  def recent_descriptions
    Log.add_info(request, params.inspect)

    detail_sql = SqlHelper.get_sql_like([:detail], "\"id\"=>\"#{params[:id]}\"")
    sql = "select distinct * from logs where user_id=#{@login_user.id} and (access_path like '%/items/set_description%') and #{detail_sql} order by updated_at DESC limit 0,10"
    @logs = Log.find_by_sql(sql)

    render(:partial => 'ajax_recent_descriptions', :layout => false)
  end

  #=== set_image
  #
  #<Ajax>
  #Registers images of the Item.
  #
  def set_image
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    img_attrs = nil
    unless params[:file].blank?
      params[:file].original_filename = params[:name] unless params[:name].blank?
      img_attrs = {:file => params[:file]}
      params.delete(:file)
    end

    created = false

    if params[:id].blank?
      attrs = params.fetch(:item, nil)
      unless attrs.nil? or img_attrs.nil?
        @item = Item.new_info(0)
        @item.attributes = attrs.permit(Item::PERMIT_BASE)
        @item.user_id = @login_user.id
        @item.title ||= t('paren.no_title')
        @item.save!
        created = true
      end
    else
      @item = Item.find(params[:id])
    end

    unless @item.nil? or img_attrs.nil?
      item_images = @item.images_without_content

      image = Image.new
      image.item_id = @item.id
      image.file = img_attrs[:file]
      image.title = File.basename(image.name, '.*')
      image.xorder = item_images.length
      image.save!

      item_images << image

      unless created
        @item.update_attribute(:updated_at, Time.now)
      end
    end

    render(:partial => 'edit_item_image', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    @image = Image.new
    @image.errors.add_to_base(evar.to_s[0, 256])

    render(:partial => 'edit_item_image', :layout => false)
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

    parent_item = img.item
    if parent_item.nil? or !parent_item.check_user_auth(@login_user, 'r', true)
      Log.add_check(request, '[Item.check_user_auth]'+params.inspect)
      redirect_to(:controller => 'frames', :action => 'http_error', :id => '401')
      return
    end

    response.headers["Content-Type"] = img.content_type
    response.headers["Content-Disposition"] = "inline"
    render(:plain => img.content)
  end

  #=== delete_image
  #
  #<Ajax>
  #Deletes Image.
  #
  def delete_image
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    begin
      image = Image.find(params[:image_id])

      @item = Item.find(image.item_id)

      unless @item.check_user_auth(@login_user, 'w', true)
        raise(t('msg.need_to_be_owner'))
      end

      image.destroy

      @item.update_attribute(:updated_at, Time.now)

    rescue => evar
      Log.add_error(request, evar)
    end

    render(:partial => 'edit_item_image', :layout => false)
  end

  #=== edit_image_info
  #
  #<Ajax>
  #Gets Image information to edit.
  #
  def edit_image_info
    Log.add_info(request, params.inspect)

    begin
      @image = Image.find(params[:image_id])

      item = Item.find(@image.item_id)

      unless item.check_user_auth(@login_user, 'w', true)
        raise(t('msg.need_to_be_owner'))
      end
    rescue => evar
      Log.add_error(request, evar)
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

    raise(RequestPostOnlyException) unless request.post?

    image = Image.find(params[:image_id])

    # Getting Item at first for the case of resetting the db connection by an error.
    @item = Item.find(image.item_id)

    unless @item.check_user_auth(@login_user, 'w', true)
      raise(t('msg.need_to_be_owner'))
    end

    img_attrs = nil
    unless params[:file].blank?
      params[:file].original_filename = params[:name] unless params[:name].blank?
      img_attrs = {:file => params[:file]}
      params.delete(:file)
    end

    image.file = img_attrs[:file] unless img_attrs.nil?
    image.title = params[:image][:title]
    image.memo = params[:image][:memo]

    unless image.save
      @image = image
      render(:partial => 'edit_item_image', :layout => false)
      return
    end

    @item = Item.find(image.item_id)
    @item.update_attribute(:updated_at, Time.now)

    render(:partial => 'edit_item_image', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    @image = Image.new
    @image.errors.add_to_base(evar.to_s[0, 256])

    render(:partial => 'edit_item_image', :layout => false)
  end

  #=== update_images_order
  #
  #<Ajax>
  #Updates Images' order by Ajax.
  #
  def update_images_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    order_arr = params[:images_order]

    item = Item.find(params[:id])

    item.images_without_content.each do |img|
      class << img
        def record_timestamps; false; end
      end

      img.update_attribute(:xorder, order_arr.index(img.id.to_s) + 1)

      class << img
        remove_method(:record_timestamps)
      end
    end

    render(:plain => '')

  rescue => evar
    Log.add_error(request, evar)
    render(:plain => evar.to_s)
  end

  #=== set_attachment
  #
  #<Ajax>
  #Registers attachment-files of the Item.
  #
  def set_attachment
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    attach_attrs = nil
    unless params[:file].blank?
      params[:file].original_filename = params[:name] unless params[:name].blank?
      attach_attrs = {:file => params[:file]}
      params.delete(:file)
    end

    created = false

    if params[:id].blank?
      attrs = params.fetch(:item, nil)
      unless attrs.nil? or attach_attrs.nil?
        @item = Item.new_info(0)
        @item.attributes = attrs.permit(Item::PERMIT_BASE)
        @item.user_id = @login_user.id
        @item.title ||= t('paren.no_title')
        @item.save!
        created = true
      end
    else
      @item = Item.find(params[:id])
    end

    unless @item.nil? or attach_attrs.nil?
      item_attachments = @item.attachments_without_content

      attachment = Attachment.create(attach_attrs, @item, item_attachments.length)
      attachment.item_id = @item.id
      attachment.title = File.basename(attachment.name, '.*')
      attachment.save!

      item_attachments << attachment

      unless created
        @item.update_attribute(:updated_at, Time.now)
      end
    end

    render(:partial => 'edit_item_attachment', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    @attachment = Attachment.new
    @attachment.errors.add_to_base(evar.to_s[0, 256])

    render(:partial => 'edit_item_attachment', :layout => false)
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

    parent_item = (attach.item || ((attach.comment.nil?) ? nil : attach.comment.item))
    if parent_item.nil? or !parent_item.check_user_auth(@login_user, 'r', true)
      Log.add_check(request, '[Item.check_user_auth]'+params.inspect)
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

    raise(RequestPostOnlyException) unless request.post?

    begin
      attach = Attachment.find(params[:attachment_id])

      @item = Item.find(attach.item_id)

      unless @item.check_user_auth(@login_user, 'w', true)
        raise(t('msg.need_to_be_owner'))
      end

      attach.destroy

      @item.update_attribute(:updated_at, Time.now)

    rescue => evar
      Log.add_error(request, evar)
    end

    render(:partial => 'edit_item_attachment', :layout => false)
  end

  #=== edit_attachment_info
  #
  #<Ajax>
  #Gets Attachment information to edit.
  #
  def edit_attachment_info
    Log.add_info(request, params.inspect)

    begin
      @attachment = Attachment.find(params[:attachment_id])

      item = Item.find(@attachment.item_id)

      unless item.check_user_auth(@login_user, 'w', true)
        raise(t('msg.need_to_be_owner'))
      end
    rescue => evar
      Log.add_error(request, evar)
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

    raise(RequestPostOnlyException) unless request.post?

    attachment = Attachment.find(params[:attachment_id])

    # Getting Item at first for the case of resetting the db connection by an error.
    @item = Item.find(attachment.item_id)

    unless @item.check_user_auth(@login_user, 'w', true)
      raise(t('msg.need_to_be_owner'))
    end

    attach_attrs = nil
    unless params[:file].blank?
      params[:file].original_filename = params[:name] unless params[:name].blank?
      attach_attrs = {:file => params[:file]}
      params.delete(:file)
    end

    attrs = {
      :title => params[:attachment][:title],
      :memo => params[:attachment][:memo]
    }
    unless attach_attrs.nil?
      attrs[:file] = attach_attrs[:file]
    end

    unless attachment.update_attributes(attrs)
      @attachment = attachment
      render(:partial => 'edit_item_attachment', :layout => false)
      return
    end

    @item = Item.find(attachment.item_id)
    @item.update_attribute(:updated_at, Time.now)

    render(:partial => 'edit_item_attachment', :layout => false)

  rescue => evar
    Log.add_error(request, evar)

    @attachment = Attachment.new
    @attachment.errors.add_to_base(evar.to_s[0, 256])

    render(:partial => 'edit_item_attachment', :layout => false)
  end

  #=== update_attachments_order
  #
  #<Ajax>
  #Updates Attachments' order by Ajax.
  #
  def update_attachments_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    order_arr = params[:attachments_order]

    item = Item.find(params[:id])

    item.attachments_without_content.each do |attach|
      class << attach
        def record_timestamps; false; end
      end

      attach.update_attribute(:xorder, order_arr.index(attach.id.to_s) + 1)

      class << attach
        remove_method(:record_timestamps)
      end
    end

    render(:plain => '')

  rescue => evar
    Log.add_error(request, evar)
    render(:plain => evar.to_s)
  end

  #=== add_comment
  #
  #<Ajax>
  #Adds a message to the Item.
  #
  def add_comment
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @comment = Comment.new(params.require(:comment).permit(Comment::PERMIT_BASE))
    @comment.save!
    @item = @comment.item

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

    raise(RequestPostOnlyException) unless request.post?

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

    raise(RequestPostOnlyException) unless request.post?

    comment = Comment.find(params[:comment_id])
    @item = comment.item

    unless @login_user.admin?(User::AUTH_ITEM) or \
              comment.user_id == @login_user.id or \
              @item.user_id == @login_user.id
      render(:plain => 'ERROR:' + t('msg.need_to_be_admin'))
      return
    end

    comment.destroy

    case @item.xtype
      when Item::XTYPE_PROJECT
        if comment.xtype == Comment::XTYPE_APPLY

          flash[:notice] = t('msg.cancel_success')
          render(:partial => 'ajax_team_apply')

        else
          render(:plain => '')
        end

      else
        render(:plain => '')
    end
  end

  #=== add_comment_attachment
  #
  #<Ajax>
  #Attaches a file to the Comment.
  #
  def add_comment_attachment
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    attach_attrs = nil
    unless params[:file].blank?

      @comment = Comment.find(params[:comment_id])

      params[:file].original_filename = params[:name] unless params[:name].blank?
      attach_attrs = {:file => params[:file]}
      params.delete(:file)

      @comment.attachments << Attachment.create(attach_attrs, @comment, 0)
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

    raise(RequestPostOnlyException) unless request.post?

    begin
      attachment = Attachment.find(params[:attachment_id])
      @comment = Comment.find(params[:comment_id])

      if attachment.comment_id == @comment.id
        attachment.destroy
        @comment.update_attribute(:updated_at, Time.now)
      end
    rescue => evar
      Log.add_error(request, evar)
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
    if !params[:tree_node_id].nil?
      @group_id = params[:tree_node_id]
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    @users = Group.get_users(@group_id)

    render(:partial => 'ajax_select_users', :layout => false)
  end

  #=== wf_issue
  #
  #<Ajax>
  #Issues specified Workflow.
  #
  def wf_issue
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    begin
      @item = Item.find(params[:id])
      @workflow = @item.workflow
    rescue => evar
      Log.add_error(request, evar)
    end
 
    attrs = ActionController::Parameters.new({status: Workflow::STATUS_ACTIVE, issued_at: Time.now})
    @workflow.update_attributes(attrs.permit(Workflow::PERMIT_BASE))

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

    raise(RequestPostOnlyException) unless request.post?

    team_id = params[:team_id]
    unless team_id.blank?
      begin
        @team = Team.find(team_id)
      rescue
        @team = nil
      end
      if @team.nil?
        flash[:notice] = t('msg.already_deleted', :name => Team.model_name.human)
        return
      end

      users = @team.get_users_a
    end

    team_members = params[:team_members]
    SqlHelper.validate_token([team_members])

    created = false
    modified = false

    if team_members.nil? or team_members.empty?

      unless team_id.blank?
        # @team must not be nil.
        modified = @team.clear_users
        @team.save if modified
      end

    else

      if team_members != users

        if team_id.blank?

          item = Item.find(params[:id])

          created = true
          @team = Team.new
          @team.name = item.title
          @team.item_id = params[:id]
          @team.status = Team::STATUS_STANDBY
        else
          @team.clear_users
        end

        @team.add_users(team_members)
        @team.save
        @team.remove_application(team_members)

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

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_team_info', :layout => false)
  end

=begin
#  #=== move_in_team_folder
#  #
#  #<Ajax>
#  #Moves the Item in the Team Folder.
#  #
#  def move_in_team_folder
#    Log.add_info(request, params.inspect)
#
#    raise(RequestPostOnlyException) unless request.post?
#
#    @item = Item.find(params[:id])
#
#    team_folder = @item.team.get_team_folder
#
#    @item.update_attribute(:folder_id, team_folder.id)
#
#    flash[:notice] = t('msg.move_success')
#
#    render(:partial => 'ajax_move_in_team_folder', :layout => false)
#
#  rescue => evar
#    Log.add_error(request, evar)
#    render(:partial => 'ajax_move_in_team_folder', :layout => false)
#  end
=end

  #=== change_team_status
  #
  #<Ajax>
  #Changes status of the Team.
  #
  def change_team_status
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    SqlHelper.validate_token([params[:status]])

    team_id = params[:team_id]
    begin
      team = Team.find(team_id)
      team.update_status(params[:status])

      @item = team.item

      flash[:notice] = t('msg.update_success')

    rescue => evar
      Log.add_error(request, evar)
      flash[:notice] = evar.to_s
    end

    render(:partial => 'ajax_team_status', :layout => false)
  end

 private
  #=== check_owner
  #
  #Filter method to check if the current User is owner of the specified Item.
  #
  def check_owner
    return if params[:id].blank? or @login_user.nil?

    begin
      owner_id = Item.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    if !@login_user.admin?(User::AUTH_ITEM) and owner_id != @login_user.id
      Log.add_check(request, '[check_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end

  #=== check_comment_registrant
  #
  #Filter method to check if the current User is registrant of the specified Comment.
  #
  def check_comment_registrant
    return if @login_user.nil?

    begin
      owner_id = Comment.find(params[:comment_id]).user_id
    rescue
      owner_id = -1
    end
    if !@login_user.admin?(User::AUTH_ITEM) and owner_id != @login_user.id
      Log.add_check(request, '[check_comment_registrant]'+params.inspect)

      flash[:notice] = t('msg.need_auth_to_access')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
