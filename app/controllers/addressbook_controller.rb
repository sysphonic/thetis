#
#= AddressbookController
#
#Copyright:: Copyright (c) 2007-2016 MORITA Shintaro, Sysphonic. All rights reserved.
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

  before_action(:check_login)
  before_action(:check_owner, :only => [:edit, :update])

  require 'digest/md5'
  require 'cgi'
  require 'csv'


  #=== query
  #
  #Shows form to edit Address information.
  #
  def query
    Log.add_info(request, params.inspect)

    email = params[:email]
    unless email.nil?
      email = EmailsHelper.extract_addr(email)
    end
    disp_name = params[:disp_name]

    @address = Address.get_by_email(email, @login_user, Address::BOOK_BOTH).first

    if @address.nil?
      @address = Address.new
      @address.name = EmailsHelper.get_sender_exp(disp_name)
      @address.email1 = email
      new
    else
      show
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

  #=== create
  #
  #Creates Address.
  #
  def create
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @address = Address.new(params.require(:address).permit(Address::PERMIT_BASE))

    @address = AddressbookHelper.arrange_per_scope(@address, @login_user, params[:scope], params[:groups], params[:teams])
    if @address.nil?
      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
      return
    end

    begin
      @address.save!
    rescue
      render(:controller => 'addressbook', :action => 'edit', :layout => (!request.xhr?))
      return
    end

    flash[:notice] = t('msg.register_success')

    if request.xhr?
      render(:partial => 'common/flash_notice', :layout => false)
    else
      list
      render(:action => 'list')
    end
  end

  #=== edit
  #
  #Shows form to edit Address information.
  #
  def edit
    Log.add_info(request, params.inspect)

    address_id = params[:id]

    begin
      @address = Address.find(address_id)
    rescue => evar
      @address = nil
      Log.add_error(request, evar)
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
    if params[:action] == 'show'
      Log.add_info(request, params.inspect)
    end

    @address ||= Address.find(params[:id])
    if @address.nil?
      render(:plain => 'ERROR:' + t('msg.already_deleted', :name => Address.model_name.human))
      return
    else
      unless @address.visible?(@login_user)
        render(:plain => 'ERROR:' + t('msg.need_auth_to_access'))
        return
      end
    end
    render(:action => 'show', :layout => (!request.xhr?))
  end

  #=== update
  #
  #Updates Address information.
  #
  def update
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @address = Address.find(params[:id])
    @address.attributes = params[:address]

    @address = AddressbookHelper.arrange_per_scope(@address, @login_user, params[:scope], params[:groups], params[:teams])
    if @address.nil?
      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
      return
    end

    if @address.save
      flash[:notice] = t('msg.update_success')
      if request.xhr?
        render(:partial => 'common/flash_notice', :layout => false)
      else
        list
        render(:action => 'list')
      end
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

    if params[:filter_book].blank?
      params[:filter_book] = Address::BOOK_BOTH
    end

    con = []
    if !@login_user.nil? \
        and @login_user.admin?(User::AUTH_ADDRESSBOOK) \
        and params[:admin] == 'true'
      con = ['(owner_id=0)']
    else
      con << AddressbookHelper.get_scope_condition_for(@login_user, params[:filter_book])
    end

    unless params[:keyword].blank?
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        con << SqlHelper.get_sql_like([:name, :email1, :email2, :email3, :name_ruby, :nickname, :screenname, :address, :organization, :tel1, :tel2, :tel3, :fax, :url, :postalcode, :title, :memo], key)
      end
    end

    where = ''
    unless con.empty?
      where = ' where ' + con.join(' and ')
    end

    order_by = nil
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if (@sort_col.blank? or @sort_type.blank?)
      @sort_col = 'xorder'
      @sort_type = 'ASC'
    end

    SqlHelper.validate_token([@sort_col, @sort_type], ['.'])
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

    raise(RequestPostOnlyException) unless request.post?

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
          address.destroy if address.editable?(@login_user)
        rescue => evar
          Log.add_error(request, evar)
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

    book = params[:filter_book]
    book = Address::BOOK_PRIVATE unless @login_user.admin?(User::AUTH_ADDRESSBOOK)

    csv = Address.export_csv(@login_user, book)

    begin
      csv.encode!(params[:enc], Encoding::UTF_8, {:invalid => :replace, :undef => :replace, :replace => ' '})
    rescue => evar
      Log.add_error(request, evar)
    end

    send_data(csv, :type => 'application/octet-stream;charset=UTF-8', :disposition => 'attachment;filename="addressbook.csv"')
  end

  #=== import_csv
  #
  #Imports Address list as a CSV file.
  #
  def import_csv
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    file = params[:imp_file]
    mode = params[:mode]
    enc = params[:enc]
    book = params[:filter_book]
    book = Address::BOOK_PRIVATE unless @login_user.admin?(User::AUTH_ADDRESSBOOK)

    all_addresses = Address.get_for(@login_user, book)

    address_names = []
    if (mode == 'add')
      all_addresses.each do |address|
        address_names << address.name
      end
    end

    @imp_errs = {}
    count = -1  # 0 for Header-line
    addresses = [] 

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
    err_col_names = nil
    col_idxs = []

    CSV.parse(csv, opt) do |row|
      unless row.first.nil?
        next if row.first.lstrip.index('#') == 0
      end
      next if row.compact.empty?

      count += 1
      if count == 0  # for Header Line
        err_col_names = Address.check_csv_header(row, book)
        if err_col_names.nil? or err_col_names.empty?
          header_cols = Address.csv_header_cols(book)
          col_idxs = header_cols.collect{|col_name| row.index(col_name)}
          next
        else
        logger.fatal('@@@ ' + err_col_names.inspect)
          @imp_errs[0] = []
          err_col_names.each do |err_col_name|
            @imp_errs[0] << t('address.invalid_column_names') + err_col_name
          end
          break
        end
      end

      address = Address.parse_csv_row(row, book, col_idxs, @login_user)

      check = address.check_import(mode, address_names)

      @imp_errs[count] = check unless check.empty?

      addresses << address

      if (mode == 'update')
        update_address = all_addresses.find do |rec|
          rec.id == address.id
        end
        unless update_address.nil?
          all_addresses.delete(update_address)
          found_update = true
        end
      end
    end

    if err_col_names.nil? or err_col_names.empty?
      if addresses.empty?
        @imp_errs[0] = [t('address.nothing_to_import')]
      else
        if (mode == 'update') and !found_update
          @imp_errs[0] = [t('address.nothing_to_update')]
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

          @imp_cnt += 1

        rescue => evar
          @imp_errs[count] = [t('address.save_failed') + evar.to_s]
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

    return if (params[:id].blank? or @login_user.nil?)

    address = Address.find(params[:id])

    if !@login_user.admin?(User::AUTH_ADDRESSBOOK) and address.owner_id != @login_user.id
      Log.add_check(request, '[check_owner]'+params.inspect)

      flash[:notice] = t('msg.need_to_be_owner')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
