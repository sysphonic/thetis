#
#= MailFiltersController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#The Action-Controller about MailFilters.
#
#== Note:
#
#* 
#
class MailFiltersController < ApplicationController
  layout 'base'

  before_action(:check_login)
  before_action(:check_owner, :only => [:edit, :update, :show])


  #=== list
  #
  #Lists message filters.
  #
  def list
    if (params[:action] == 'list')
      Log.add_info(request, params.inspect)
    end

    mail_account_id = params[:mail_account_id]
    account_xtype = params[:mail_account_xtype]
    SqlHelper.validate_token([mail_account_id, account_xtype])

    accounts_con = []
    accounts_con << "(user_id=#{@login_user.id})"
    unless account_xtype.blank?
      accounts_con << "(xtype='#{account_xtype}')"
    end
    @mail_accounts = MailAccount.find_all(accounts_con.join(' and '))
    unless mail_account_id.blank?
      @mail_account = @mail_accounts.find{|rec| rec.id == mail_account_id.to_i}
    end
    @mail_account ||= @mail_accounts.first

    con = []
    if @mail_account.nil?
      con << "(mail_account_id=0)"  # Force to get empty set.
    else
      con << "(mail_account_id=#{@mail_account.id})"
    end

    where = ''
    unless con.empty?
      where = ' where ' + con.join(' and ')
    end

    order_by = ' order by (xorder is null) ASC, xorder ASC, id ASC'

    sql = 'select distinct MailFilter.* from mail_filters MailFilter'
    sql << where + order_by

    @filter_pages, @filters, @total_num = paginate_by_sql(MailFilter, sql, 50)

    if (params[:action] == 'list')
      render(:action => 'list', :layout => false)   # (!request.xhr?)
    end
  end

  #=== new
  #
  #Does nothing about showing empty form to create User.
  #
  def new
    if params[:action] == 'new'
      Log.add_info(request, params.inspect)
    end

    render(:action => 'edit', :layout => (!request.xhr?))
  end

  #=== edit
  #
  #Shows form to edit MailFilter information.
  #
  def edit
    Log.add_info(request, params.inspect)

    mail_filter_id = params[:id]

    begin
      @mail_filter = MailFilter.find(mail_filter_id)
    rescue => evar
      Log.add_error(request, evar)
      redirect_to(:controller => 'login', :action => 'logout')
      return
    end
    render(:layout => (!request.xhr?))
  end

  #=== show
  #
  #Shows MailFilter information.
  #
  def show
    if params[:action] == 'show'
      Log.add_info(request, params.inspect)
    end

    begin
      @mail_filter = MailFilter.find(params[:id])
    rescue => evar
    end
    if @mail_filter.nil?
      render(:plain => 'ERROR:' + t('msg.already_deleted', :name => MailFilter.model_name.human))
      return
    else
      if @mail_filter.mail_account.user_id != @login_user.id
        render(:plain => 'ERROR:' + t('msg.need_to_be_owner'))
        return
      end
    end
    render(:action => 'show', :layout => (!request.xhr?))
  end

  #=== update
  #
  #Updates MailFilter information.
  #
  def update
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    attrs = params[:mail_filter]
    if attrs['and_or'] == 'none'
      attrs['and_or'] = nil
      attrs['conditions'] = nil
    else
      filter_conditions = params[:filter_condition]
      condition_entries = []
      filter_conditions.each do |condition_id, entry|
        point, compare, val = entry.split("\n")
        if val.nil? or val.empty?
          condition_entries << [point, compare].join('-')
        else
          condition_entries << [point, compare, val].join('-')
        end
      end
      attrs['conditions'] = condition_entries.join("\n")
    end

    filter_actions = params[:filter_action]
    action_entries = []
    filter_actions.each do |action_id, entry|
      verb, val = entry.split("\n")
      if val.nil? or val.empty?
        action_entries << verb
      else
        action_entries << [verb, val].join('-')
      end
    end
    attrs['actions'] = action_entries.join("\n")

    mail_filter_id = params[:id]
    if mail_filter_id.blank?
      @mail_filter = MailFilter.new(attrs.permit(MailFilter::PERMIT_BASE))
      @mail_filter.mail_account_id = params[:mail_account_id]
    else
      @mail_filter = MailFilter.find(mail_filter_id)

      if @mail_filter.mail_account.user_id != @login_user.id
        flash[:notice] = t('msg.need_to_be_owner')
        redirect_to(:controller => 'desktop', :action => 'show')
        return
      end
    end

    if @mail_filter.id.nil?
      @mail_filter.save!
      flash[:notice] = t('msg.register_success')
    else
      @mail_filter.update_attributes(attrs.permit(MailFilter::PERMIT_BASE))
      flash[:notice] = t('msg.update_success')
    end

    list
    render(:action => 'list', :layout => !request.xhr?)
  end

  #=== destroy
  #
  #Deletes MailFilters.
  #
  def destroy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:check_filter].nil?
      list
      render(:action => 'list', :layout => !request.xhr?)
      return
    end

    count = 0
    params[:check_filter].each do |filter_id, value|
      if value == '1'

        begin
          filter = MailFilter.find(filter_id)
          filter.destroy if filter.editable?(@login_user)
        rescue => evar
          filter = nil
          Log.add_error(request, evar)
        end

        count += 1
      end
    end
    flash[:notice] = t('address.deleted', :count => count)

    list
    render(:action => 'list', :layout => !request.xhr?)
  end

  #=== do_execute
  #
  #<Ajax>
  #Does execute MailFilters of the specified MailAccount.
  #
  def do_execute
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    mail_account = MailAccount.find(params[:mail_account_id])
    mail_folder = MailFolder.find(params[:mail_folder_id])

    if mail_account.user_id != @login_user.id \
        or mail_folder.user_id != @login_user.id
      render(:plain => t('msg.need_to_be_owner'))
      return
    end

    mail_filters = MailFilter.get_for(mail_account.id, true, MailFilter::TRIGGER_MANUAL)
    emails = MailFolder.get_mails(mail_folder.id, mail_folder.user_id)

    filter_next = true
    emails.each do |email|
      mail_filters.each do |filter|
        filter_next = filter.execute(email)
        break unless filter_next
      end
      break unless filter_next
    end

    render(:plain => '')
  end

  #=== get_order
  #
  #<Ajax>
  #Gets MailFilters' order of the specified MailAccount.
  #
  def get_order
    Log.add_info(request, params.inspect)

    mail_account_id = params[:mail_account_id]
    SqlHelper.validate_token([mail_account_id])

    @mail_account = MailAccount.find(mail_account_id)

    if @mail_account.user_id != @login_user.id
      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
      return
    end

    @mail_filters = MailFilter.get_for(mail_account_id)

    render(:partial => 'ajax_order', :layout => false)

  rescue => evar
    Log.add_error(request, evar)
    render(:partial => 'ajax_order', :layout => false)
  end

  #=== update_order
  #
  #<Ajax>
  #Updates folders' order by Ajax.
  #
  def update_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    mail_account_id = params[:mail_account_id]
    order_arr = params[:mail_filters_order]

    SqlHelper.validate_token([mail_account_id])

    @mail_account = MailAccount.find(mail_account_id)

    if @mail_account.user_id != @login_user.id
      render(:plain => 'ERROR:' + t('msg.need_to_be_owner'))
      return
    end

    filters = MailFilter.get_for(mail_account_id)
    # filters must be ordered by xorder ASC.

    filters.sort! { |filter_a, filter_b|
      id_a = filter_a.id.to_s
      id_b = filter_b.id.to_s

      idx_a = order_arr.index(id_a)
      idx_b = order_arr.index(id_b)

      if idx_a.nil? or idx_b.nil?
        idx_a = filters.index(id_a)
        idx_b = filters.index(id_b)
      end

      idx_a - idx_b
    }

    idx = 1
    filters.each do |filter|
      next if filter.mail_account_id != mail_account_id.to_i

      filter.update_attribute(:xorder, idx)

      idx += 1
    end

    render(:plain => '')
  end

  #=== edit_condition
  #
  #Shows form to edit filter condition.
  #
  def edit_condition
    Log.add_info(request, params.inspect)

    render(:layout => (!request.xhr?))
  end

  #=== edit_action
  #
  #Shows form to edit filter action.
  #
  def edit_action
    Log.add_info(request, params.inspect)

    render(:layout => (!request.xhr?))
  end


 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of specified MailFilter.
  #
  def check_owner

    return if (params[:id].blank? or @login_user.nil?)

    mail_filter = MailFilter.find(params[:id])

    if !@login_user.admin?(User::AUTH_MAIL) and mail_filter.mail_account.user_id != @login_user.id
      Log.add_check(request, '[check_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
