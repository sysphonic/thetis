#
#= MailFoldersController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class MailFoldersController < ApplicationController
  layout('base')

  before_action(:check_login)
  before_action(:check_owner, :only => [:rename, :destroy, :move, :get_mails, :empty])
  before_action(:check_mail_owner, :only => [:get_mail_content, :get_mail_raw])

  #=== show_tree
  #
  #Shows MailFolder tree.
  #
  def show_tree
    if (params[:action] == 'show_tree')
      Log.add_info(request, params.inspect)
    end

    con = []
    con << "(user_id=#{@login_user.id})"

    account_xtype = params[:mail_account_xtype]
    SqlHelper.validate_token([account_xtype])

    unless account_xtype.blank?
      con << "(xtype='#{account_xtype}')"
    end
    @mail_accounts = MailAccount.find_all(con.join(' and '))

    mail_account_ids = []
    @mail_accounts.each do |mail_account|

      mail_account_ids << mail_account.id

      if MailFolder.where("mail_account_id=#{mail_account.id}").count <= 0
        @login_user.create_default_mail_folders(mail_account.id)
      end

      Email.destroy_by_user(@login_user.id, "status='#{Email::STATUS_TEMPORARY}'")
    end

    @folder_tree = MailFolder.get_tree_for(@login_user, mail_account_ids)
  end

  #=== ajax_get_tree
  #
  #Gets MailFolder tree by Ajax.
  #
  def ajax_get_tree
    Log.add_info(request, params.inspect)

    show_tree

    render(:partial => 'ajax_get_tree', :layout => false)
  end

  #=== create
  #
  #Creates MailFolder.
  #Receives MailFolder name from ThetisBox.
  #
  def create
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    parent_id = params[:selectedFolderId]

    if params[:thetisBoxEdit].blank?
      @mail_folder = nil
    else
      @mail_folder = MailFolder.new
      @mail_folder.name = params[:thetisBoxEdit]
      @mail_folder.parent_id = parent_id
      @mail_folder.user_id = @login_user.id
      @mail_folder.xtype = nil
      @mail_folder.save!
    end
    render(:partial => 'ajax_folder_entry', :layout => false)
  end

  #=== rename
  #
  #Renames MailFolder.
  #Receives MailFolder name from ThetisBox.
  #
  def rename
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @mail_folder = MailFolder.find(params[:id])

    unless params[:thetisBoxEdit].blank?
      @mail_folder.name = params[:thetisBoxEdit]
      @mail_folder.save
    end
    render(:partial => 'ajax_folder_name', :layout => false)
  end

  #=== destroy
  #
  #Deletes MailFolder.
  #
  def destroy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    mail_account_id = params[:mail_account_id]
    SqlHelper.validate_token([mail_account_id])

    mail_folder = MailFolder.find(params[:id])
    trash_folder = MailFolder.get_for(@login_user, mail_account_id, MailFolder::XTYPE_TRASH)

    if trash_folder.nil?
      mail_folder.force_destroy
      render(:plain => '')
    else
      if mail_folder.get_parents(false).include?(trash_folder.id.to_s)
        mail_folder.force_destroy
        render(:plain => '')
      else
        mail_folder.update_attribute(:parent_id, trash_folder.id)
        flash[:notice] = t('msg.moved_to_trash')

        prms = ApplicationHelper.get_fwd_params(params)
        prms[:controller] = params[:controller]
        prms[:action] = 'show_tree'
        @redirect_url = ApplicationHelper.url_for(prms)
        render(:partial => 'common/redirect_to', :layout => false)
      end
    end
  end

  #=== move
  #
  #Moves MailFolder.
  #Receives target MailFolder-ID from access-path and destination MailFolder-ID from ThetisBox.
  #params[:tree_node_id] keeps selected ID of <a>-tag like "tree_node_id-1:<selected-id>". 
  #
  def move
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @mail_folder = MailFolder.find(params[:id])

    if params[:tree_node_id].blank?
      prms = ApplicationHelper.get_fwd_params(params)
      prms[:action] = 'show_tree'
      redirect_to(prms)
      return
    end

    parent_id = params[:tree_node_id]
    SqlHelper.validate_token([parent_id])

    if (parent_id == TreeElement::ROOT_ID.to_s)
      flash[:notice] = 'ERROR:' + t('mail_folder.root_cannot_have_folders')
    else
      # Check if specified parent is not one of subfolders.
      childs = MailFolder.get_childs(@mail_folder.id, true, false)
      if childs.include?(parent_id) or (@mail_folder.id == parent_id.to_i)
        flash[:notice] = 'ERROR:' + t('folder.cannot_be_parent')
        prms = ApplicationHelper.get_fwd_params(params)
        prms[:action] = 'show_tree'
        redirect_to(prms)
        return
      end

      @mail_folder.parent_id = parent_id
      @mail_folder.xorder = nil
      @mail_folder.save

      flash[:notice] = t('msg.move_success')
    end

    prms = ApplicationHelper.get_fwd_params(params)
    prms[:action] = 'show_tree'
    redirect_to(prms)
  end

  #=== get_mails
  #
  #Gets Mails in specified MailFolder.
  #
  def get_mails
    if (params[:action] == 'get_mails')
      Log.add_info(request, params.inspect)
    end

    if (!params[:pop].nil? and params[:pop] == 'true')

      mail_account_id = params[:mail_account_id]
      SqlHelper.validate_token([mail_account_id])

      begin
        new_arrivals_h = {}

        if mail_account_id.blank?
          mail_accounts = MailAccount.find_all("user_id=#{@login_user.id}")
          mail_accounts.each do |mail_account|
            emails = Email.do_pop(mail_account)
            unless emails.empty?
              new_arrivals_h[mail_account.id] ||= []
              new_arrivals_h[mail_account.id] |= emails
            end
          end
        else
          mail_account = MailAccount.find(mail_account_id)
          emails = Email.do_pop(mail_account)
          unless emails.empty?
            new_arrivals_h[mail_account.id] ||= []
            new_arrivals_h[mail_account.id] |= emails
          end
        end

        unless new_arrivals_h.empty?
          flash[:notice] = t('mail.received', :count => new_arrivals_h.values.flatten.length)

        # FEATURE_MAIL_FILTERS >>>
          new_arrivals_h.each do |mail_account_id, emails|
            mail_filters = MailFilter.get_for(mail_account_id, true, MailFilter::TRIGGER_CHECKING)
            filter_next = true

            emails.each do |email|
              mail_filters.each do |filter|
                filter_next = filter.execute(email)
                break unless filter_next
              end
              break unless filter_next
            end
          end
        # FEATURE_MAIL_FILTERS <<<
        end
      rescue => evar
        if evar.to_s.starts_with?('ERROR:')
          flash[:notice] = evar.to_s
        else
          flash[:notice] = 'ERROR:' + t('mail.receive_error') + '<br/>' + evar.to_s
        end
        Log.add_error(nil, evar)
      end
    end

    @folder_id = params[:id]
    SqlHelper.validate_token([@folder_id])

    if (@folder_id == TreeElement::ROOT_ID.to_s)
      @emails = nil
    else
=begin
#      @emails = MailFolder.get_mails_to_show(@folder_id, @login_user)
=end
# FEATURE_PAGING_IN_TREE >>>
      @sort_col = (params[:sort_col] || 'sent_at')
      @sort_type = (params[:sort_type] || 'DESC')
      SqlHelper.validate_token([@sort_col, @sort_type], ['.'])

      sql = EmailsHelper.get_list_sql(@login_user, params[:keyword], [@folder_id], @sort_col, @sort_type, 0, nil)
      @email_pages, @emails, @total_num = paginate_by_sql(Email, sql, 10)
# FEATURE_PAGING_IN_TREE <<<
    end

    session[:mailfolder_id] = @folder_id

    render(:partial => 'ajax_folder_mails', :layout => false)
  end

  #=== get_mail_content
  #
  #Gets Email content.
  #
  def get_mail_content
    Log.add_info(request, params.inspect)

    email_id = params[:id]

    begin
      @email = Email.find(email_id)
      render(:partial => 'ajax_mail_content', :layout => false)
    rescue => evar
      Log.add_error(nil, evar)
      render(:plain => '')
    end
  end

  #=== get_mail_attachments
  #
  #Gets all attachment-files of the Email.
  #
  def get_mail_attachments
    Log.add_info(request, params.inspect)

    email_id = params[:id]

    email = Email.find(email_id)
    if (email.nil? or email.user_id != @login_user.id)
      render(:plain => '')
      return
    end

    download_name = "mail_attachments#{email.id}.zip"
    zip_file = email.zip_attachments(params[:enc])

    if zip_file.nil?
      send_data('', :type => 'application/octet-stream;', :disposition => 'attachment;filename="'+download_name+'"')
    else
      filepath = zip_file.path
      send_file(filepath, :filename => download_name, :stream => true, :disposition => 'attachment')
    end
  end

  #=== get_mail_attachment
  #
  #Gets attachment-file of the Email.
  #
  def get_mail_attachment
    Log.add_info(request, params.inspect)

    attached_id = params[:id].to_i
    begin
      mail_attach = MailAttachment.find(attached_id)
    rescue => evar
    end

    if mail_attach.nil?
      redirect_to(THETIS_RELATIVE_URL_ROOT + '/404.html')
      return
    end

    begin
      email = Email.find(mail_attach.email_id)
    rescue => evar
    end
    if (email.nil? or email.user_id != @login_user.id)
      render(:plain => '')
      return
    end

    mail_attach_name = mail_attach.name

    agent = request.env['HTTP_USER_AGENT']
    unless agent.nil?
      ie_ver = nil
      agent.scan(/\sMSIE\s?(\d+)[.](\d+)/){|m|
                  ie_ver = m[0].to_i + (0.1 * m[1].to_i)
                }
      mail_attach_name = CGI::escape(mail_attach_name) unless ie_ver.nil?
    end

    filepath = mail_attach.get_path
    if (!filepath.nil? and FileTest.exist?(filepath))
      send_file(filepath, :filename => mail_attach_name, :stream => true, :disposition => 'attachment')
    else
      send_data('', :type => 'application/octet-stream;', :disposition => 'attachment;filename="'+mail_attach_name+'"')
    end
  end

  #=== get_mail_raw
  #
  #Gets raw data of the Email.
  #
  def get_mail_raw
    Log.add_info(request, params.inspect)

    email = Email.find(params[:id])
    email_name = email.subject + Email::EXT_RAW

    agent = request.env['HTTP_USER_AGENT']
    unless agent.nil?
      ie_ver = nil
      agent.scan(/\sMSIE\s?(\d+)[.](\d+)/){|m|
                  ie_ver = m[0].to_i + (0.1 * m[1].to_i)
                }
      email_name = CGI::escape(email_name) unless ie_ver.nil?
    end

    filepath = File.join(email.get_dir, email.id.to_s + Email::EXT_RAW)
    if (!filepath.nil? and FileTest.exist?(filepath))
      send_file(filepath, :filename => email_name, :stream => true, :disposition => 'attachment')
    else
      send_data('', :type => 'application/octet-stream;', :disposition => 'attachment;filename="'+email_name+'"')
    end
  end

  #=== empty
  #
  #Deletes all Emails in specified MailFolder.
  #
  def empty
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @folder_id = params[:id]
    mail_account_id = params[:mail_account_id]
    SqlHelper.validate_token([@folder_id, mail_account_id])

    trash_folder = MailFolder.get_for(@login_user, mail_account_id, MailFolder::XTYPE_TRASH)

    mail_folder = MailFolder.find(@folder_id)
    emails = (MailFolder.get_mails(mail_folder.id, @login_user) || [])

    if ((mail_folder.id == trash_folder.id) \
        or mail_folder.get_parents(false).include?(trash_folder.id.to_s))
      emails.each do |email|
        email.destroy
      end
      flash[:notice] = t('msg.delete_success')
    else
      emails.each do |email|
        email.update_attribute(:mail_folder_id, trash_folder.id)
      end
      flash[:notice] = t('msg.moved_to_trash')
    end

    get_mails
  end

  #=== ajax_delete_mails
  #
  #Deletes specified Emails.
  #
  def ajax_delete_mails
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    folder_id = params[:id]
    mail_account_id = params[:mail_account_id]
    SqlHelper.validate_token([folder_id, mail_account_id])

    unless params[:check_mail].blank?
      mail_folder = MailFolder.find(folder_id)
      trash_folder = MailFolder.get_for(@login_user, mail_account_id, MailFolder::XTYPE_TRASH)

      count = 0
      params[:check_mail].each do |email_id, value|
        next if (value != '1')

        begin
          email = Email.find(email_id)
        rescue => evar
        end
        next if email.nil? or (email.user_id != @login_user.id)

        if trash_folder.nil? \
            or folder_id == trash_folder.id.to_s \
            or mail_folder.get_parents(false).include?(trash_folder.id.to_s)
          email.destroy
          flash[:notice] ||= t('msg.delete_success')
        else
          begin
            email.update_attribute(:mail_folder_id, trash_folder.id)
            flash[:notice] ||= t('msg.moved_to_trash')
          rescue => evar
            Log.add_error(request, evar)
            email.destroy
            flash[:notice] ||= t('msg.delete_success')
          end
        end

        count += 1
      end
    end

    get_mails
  end

  #=== ajax_move_mails
  #
  #Moves specified Emails.
  #
  def ajax_move_mails
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    folder_id = params[:tree_node_id]
    SqlHelper.validate_token([folder_id])
    begin
      mail_folder = MailFolder.find(folder_id)
    rescue => evar
    end

    if folder_id == TreeElement::ROOT_ID.to_s \
        or mail_folder.nil? \
        or mail_folder.user_id != @login_user.id
      flash[:notice] = 'ERROR:' + t('msg.cannot_save_in_folder')
      get_mails
      return
    end

    unless params[:check_mail].blank?
      count = 0
      params[:check_mail].each do |email_id, value|
        if (value == '1')

          begin
            email = Email.find(email_id)
            next if (email.user_id != @login_user.id)

            email.update_attribute(:mail_folder_id, folder_id)

          rescue => evar
            Log.add_error(request, evar)
          end

          count += 1
        end
      end
      flash[:notice] = t('mail.moved', :count => count)
    end

    get_mails
  end

  #=== get_folders_order
  #
  #Gets child MailFolders' order in specified MailFolder.
  #
  def get_folders_order
    Log.add_info(request, params.inspect)

    @folder_id = params[:id]
    SqlHelper.validate_token([@folder_id])

    if (@folder_id == TreeElement::ROOT_ID.to_s)
      @folders = MailFolder.get_account_roots_for(@login_user)
    else
      mail_folder = MailFolder.find(@folder_id)
      if (mail_folder.user_id == @login_user.id)
        @folders = MailFolder.get_childs(@folder_id, false, true)
      end
    end

    render(:partial => 'ajax_folders_order', :layout => false)
  end

  #=== update_folders_order
  #
  #Updates folders' order by Ajax.
  #
  def update_folders_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    order_arr = params[:folders_order]

    SqlHelper.validate_token([params[:id]])
    folders = MailFolder.get_childs(params[:id], false, false)
    # folders must be ordered by xorder ASC.

    folders.sort! { |id_a, id_b|

      idx_a = order_arr.index(id_a)
      idx_b = order_arr.index(id_b)

      if (idx_a.nil? or idx_b.nil?)
        idx_a = folders.index(id_a)
        idx_b = folders.index(id_b)
      end

      idx_a - idx_b
    }

    idx = 1
    folders.each do |folder_id|
      begin
        folder = MailFolder.find(folder_id)
        next if (folder.user_id != @login_user.id)

        folder.update_attribute(:xorder, idx)

        if (folder.xtype == MailFolder::XTYPE_ACCOUNT_ROOT)
          mail_account = MailAccount.find_by_id(folder.mail_account_id)
          unless mail_account.nil?
            mail_account.update_attribute(:xorder, idx)
          end
        end

        idx += 1
      rescue => evar
        Log.add_error(request, evar)
      end
    end

    render(:plain => '')
  end

  #=== update_mail_unread
  #
  #Updates unread flag of the E-mail by Ajax.
  #
  def update_mail_unread
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    email_id = params[:email_id]
    unread = (params[:unread] == "1")

    begin
      email = Email.find(email_id)
      if !email.nil? and (email.user_id == @login_user.id)
        if (email.xtype == Email::XTYPE_RECV)
          status = (unread)?(Email::STATUS_UNREAD):(Email::STATUS_NONE)
          email.update_attribute(:status, status)
        end
      end
    rescue => evar
      Log.add_error(nil, evar)
    end

    render(:plain => '')
  end

 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of the specified MailFolder.
  #
  def check_owner

    return if params[:id].blank? \
             or (params[:id] == TreeElement::ROOT_ID.to_s) \
             or @login_user.nil?

    begin
      owner_id = MailFolder.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    if !@login_user.admin?(User::AUTH_MAIL) and owner_id != @login_user.id
      Log.add_check(request, '[check_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end

  #=== check_mail_owner
  #
  #Filter method to check if current User is owner of the specified Email.
  #
  def check_mail_owner
    return if (params[:id].blank? or @login_user.nil?)

    begin
      owner_id = Email.find(params[:id]).user_id
    rescue
      owner_id = -1
    end
    if !@login_user.admin?(User::AUTH_MAIL) and owner_id != @login_user.id
      Log.add_check(request, '[check_mail_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
