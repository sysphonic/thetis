#
#= AddressbookController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Addressbook.
#
#== Note:
#
#* 
#
class AddressbookController < ApplicationController
  layout 'base'

  include LoginChecker

  before_filter :check_login
  before_filter :check_owner, :only => [:edit, :update]

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

    render(:action => 'edit', :layout => (!request.xhr?))
  end

  #=== create
  #
  #Creates Address.
  #
  def create
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    unless AddressbookHelper.arrange_per_scope(params, login_user)
      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
      return
    end

    @address = Address.new(params[:address])

    begin
      @address.save!
    rescue
      render(:controller => 'addressbook', :action => 'edit', :layout => (!request.xhr?))
      return
    end

    flash[:notice] = t('msg.register_success')

    list
    render(:action => 'list')
  end

  #=== edit
  #
  #Shows form to edit Address information.
  #
  def edit
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    address_id = params[:id]

    begin
      @address = Address.find(address_id)
    rescue StandardError => err
      Log.add_error(request, err)
      redirect_to(:controller => 'login', :action => 'logout')
      return
    end
    render(:layout => (!request.xhr?))
  end

  #=== show
  #
  #Shows Address information.
  #
  def show
    Log.add_info(request, params.inspect)

    @address = Address.find(params[:id])
    if @address.nil?
      render(:text => 'ERROR:' + t('msg.already_deleted', :name => Address.human_name))
      return
    else
      login_user = session[:login_user]
      unless @address.visible?(login_user)
        render(:text => 'ERROR:' + t('msg.need_auth_to_access'))
        return
      end
    end
    render(:layout => (!request.xhr?))
  end

  #=== update
  #
  #Updates Address information.
  #
  def update
    Log.add_info(request, params.inspect)

    @address = Address.find(params[:id])

    login_user = session[:login_user]

    unless AddressbookHelper.arrange_per_scope(params, login_user)
      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
      return
    end

    if @address.update_attributes(params[:address])
      flash[:notice] = t('msg.update_success')
      list
      render(:action => 'list')
    else
      render(:controller => 'addressbook', :action => 'edit', :layout => (!request.xhr?))
    end
  end

  #=== list
  #
  #Shows Addresses list.
  #
  def list
    if (params[:action] == 'list')
      Log.add_info(request, params.inspect)
    end

    login_user = session[:login_user]

    if params[:filter_book].nil? or params[:filter_book].empty?
      params[:filter_book] = Address::BOOK_BOTH
    end

    con = []
    if !login_user.nil? \
        and login_user.admin?(User::AUTH_ADDRESSBOOK) \
        and params[:admin] == 'true'
      con = ['owner_id=0']
    else
      con << AddressbookHelper.get_scope_condition_for(login_user, params[:filter_book])
    end

    if params[:keyword]
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        key = '%' + key + '%'
        con << "(name like '#{key}' or email1 like '#{key}' or email2 like '#{key}' or email3 like '#{key}' or name_ruby like '#{key}' or nickname like '#{key}' or screenname like '#{key}' or address like '#{key}' or organization like '#{key}' or tel1 like '#{key}' or tel2 like '#{key}' or tel3 like '#{key}' or fax like '#{key}' or url like '#{key}' or postalcode like '#{key}' or title like '#{key}' or memo like '#{key}' )"
      end
    end

    where = ''
    unless con.empty?
      where = ' where ' + con.join(' and ')
    end

    order_by = nil
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if (@sort_col.nil? or @sort_col.empty? or @sort_type.nil? or @sort_type.empty?)
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

    sql = 'select distinct Address.* from addresses Address'
    sql << where + order_by

    @address_pages, @addresses, @total_num = paginate_by_sql(Address, sql, 50)
  end

  #=== search
  #
  #Searches Addresses.
  #
  def search
    Log.add_info(request, params.inspect)

    list
    render(:action => 'list')
  end

  #=== destroy
  #
  #Deletes Addresses.
  #
  def destroy
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    if params[:check_address].nil?
      list
      render(:action => 'list')
      return
    end

    count = 0
    params[:check_address].each do |address_id, value|
      if value == '1'

        begin
          address = Address.find(address_id)
          address.destroy if address.editable?(login_user)
        rescue StandardError => err
          Log.add_error(request, err)
        end

        count += 1
      end
    end
    flash[:notice] = t('address.deleted', :count => count)

    list
    render(:action => 'list')
  end

  #=== export_csv
  #
  #Exports Address list as a CSV file.
  #
  def export_csv
    Log.add_info(request, params.inspect)

    login_user = session[:login_user]

    csv = Address.export_csv(login_user.id)

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

    send_data(csv, :type => 'application/octet-stream;charset=UTF-8', :disposition => 'attachment;filename="addressbook.csv"')
  end

  #=== import_csv
  #
  #Imports Address list as a CSV file.
  #
  def import_csv
    Log.add_info(request, params.inspect)

    file = params[:imp_file]
    mode = params[:mode]
    enc = params[:enc]

    login_user = session[:login_user]

    all_addresses = Address.find(:all, :conditions => ['owner_id=?', login_user.id]) || []

    address_names = []
#   address_emails = []
    if (mode == 'add')
      all_addresses.each do |address|
        address_names << address.name
#       address_emails << address.email
      end
    end

    @imp_errs = PseudoHash.new
    count = -1  # 0 for Header-line
    addresses = [] 

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
        next if (row.first.lstrip.index('#') == 0)
      end

      count += 1
      next if count == 0  # for Header Line

      address = Address.parse_csv_row(row)

      check = address.check_import(mode, address_names)  #, address_emails

      @imp_errs[count, true] = check unless check.empty?

      addresses << address

      if (mode == 'update')
        update_address = all_addresses.find do |u|
          u.id == address.id
        end
        unless update_address.nil?
          all_addresses.delete(update_address)
          found_update = true
        end
      end
    end

    if addresses.empty?

      @imp_errs[0, true] = [t('address.nothing_to_import')]
    else

      if mode == 'update'

        if found_update
        else
          @imp_errs[0, true] = [t('address.nothing_to_update')]
        end
      end
    end

    # Create or Update
    count = 0
    @imp_cnt = 0
    if @imp_errs.empty?
      addresses.each do |address|
        count += 1
        begin
          address_id = address.id

          address.save!

          if address_id.nil?
            address.setup
          end

          @imp_cnt += 1

        rescue StandardError => err
          @imp_errs[count, true] = [t('address.save_failed') + err.to_s]
        end
      end
    end

    # Delete
    # Actually, the correct order of the process is Delete -> Create,
    # not to duplicate a Address Name.
    #    3: morita   <- Delete
    #     : morita   <- Create
    # But such a case is most likely to be considered as a 
    # user's miss-operation. We can avoid this case with
    # 'opposite' process.
    del_cnt = 0
    if (@imp_errs.empty? and mode == 'update')
      all_addresses.each do |address|
        address.destroy
        del_cnt += 1
      end
    end

    if @imp_errs.empty?
      flash[:notice] = t('address.imported', :count => addresses.length)
      if (del_cnt > 0)
        flash[:notice] << '<br/>' + t('address.deleted', :count => del_cnt)
      end
    end

    list
    render(:action => 'list')
  end


 private
  #=== check_owner
  #
  #Filter method to check if current User is owner of specified Item.
  #
  def check_owner

    login_user = session[:login_user]

    return if (params[:id].nil? or params[:id].empty? or login_user.nil?)

    address = Address.find(params[:id])

    if !login_user.admin?(User::AUTH_ADDRESSBOOK) and address.owner_id != login_user.id
      Log.add_check(request, '[check_owner]'+request.to_s)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
