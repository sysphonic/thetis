#
#= ZeptairXlogsController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#The Action-Controller about ZeptairXlogs.
#
#== Note:
#
#* 
#
class ZeptairXlogsController < ApplicationController
  layout 'base'

  before_action :check_login
  before_action do |controller|
    controller.check_auth(User::AUTH_ZEPTAIR)
  end


  #=== list
  #
  #Shows list of ZeptairXlogs.
  #This method takes input of filter, keywords, sort options
  #and pagination parameters.
  #
  def list
    if params[:action] == 'list'
      Log.add_info(request, params.inspect)
    end

    con = []

    case params[:filter]
     when 'all', '', nil
        ;
     else
        con << SqlHelper.get_sql_like(['ZeptairXlog.cs_protocol'], "/#{params[:filter]}/")
    end

    include_user = false

    keyword = params[:keyword]
    unless keyword.blank?
      arr = []

      key_array = keyword.split(nil)
      key_array.each do |key|
        arr << "((User.id = ZeptairXlog.user_id) and #{SqlHelper.get_sql_like(['User.name', 'User.fullname'], key)})"
        arr << SqlHelper.get_sql_like(['ZeptairXlog.req_at', :cs_uri, :c_agent, :cs_protocol, :s_port, :zeptair_id], key)
        con << '(' + arr.join(' or ') + ')'
        include_user = true
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
      @sort_col = 'fin_at'
      @sort_type = 'DESC'
    end
    SqlHelper.validate_token([@sort_col, @sort_type], ['.'])
    order_by = ' order by ' + @sort_col + ' ' + @sort_type

    sql = 'select distinct ZeptairXlog.* from zeptair_xlogs ZeptairXlog'
    if include_user
      sql << ', users User'
    end
    sql << where + order_by

    @xlog_pages, @xlogs, @total_num = paginate_by_sql(ZeptairXlog, sql, 50)
  end

  #=== search
  #
  #Shows search result.
  #Does same as list-action except rendered rhtml.
  #
  def search
    Log.add_info(request, params.inspect)

    list
    render(:action => 'list')
  end

  #=== destroy
  #
  #Deletes ZeptairXlogs.
  #
  def destroy
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    if params[:check_xlog].nil?
      list
      render(:action => 'list')
      return
    end

    count = 0
    SqlHelper.validate_token([params[:check_xlog].keys])
    params[:check_xlog].each do |key, value|
      if value == '1'
        ZeptairXlog.delete(key)
        count += 1
      end
    end

    list
    flash[:notice] = count.to_s + t('log.deleted')
    render(:action => 'list')
  end

  #=== destroy_all
  #
  #Deletes all ZeptairXlogs.
  #
  def destroy_all
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    ZeptairXlog.delete_all

    flash[:notice] = t('msg.delete_success')
    redirect_to(:action => 'list')
  end

  #=== export_csv
  #
  #Exports Xlogs' list as a CSV file.
  #
  def export_csv
    Log.add_info(request, params.inspect)

    csv = ZeptairXlog.export_csv

    begin
      csv.encode!(params[:enc], Encoding::UTF_8, {:invalid => :replace, :undef => :replace, :replace => ' '})
    rescue => evar
      Log.add_error(request, evar)
    end

    send_data(csv, :type => 'application/octet-stream;charset=UTF-8', :disposition => 'attachment;filename="zeptair_network_logs.csv"')
  end
end
