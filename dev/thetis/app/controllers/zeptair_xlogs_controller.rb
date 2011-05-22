#
#= ZeptairXlogsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about ZeptairXlogs.
#
#== Note:
#
#* 
#
class ZeptairXlogsController < ApplicationController
  layout 'base'

  include LoginChecker

  before_filter :check_login
  before_filter do |controller|
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
        con << "(ZeptairXlog.cs_protocol like '%/#{params[:filter]}/%')"
    end

    include_user = false

    keyword = params[:keyword]
    unless keyword.nil? or keyword.empty?
      ary = []

      key_array = keyword.split(nil)
      key_array.each do |key|
        key = "%" + key + "%"
        ary << "((User.id = ZeptairXlog.user_id) and (User.name like '#{key}' or User.fullname like '#{key}'))"
        ary << "(ZeptairXlog.req_at like '#{key}' or cs_uri like '#{key}' or c_agent like '#{key}' or cs_protocol like '#{key}' or s_port like '#{key}' or zeptair_id like '#{key}' )"
        con << '(' + ary.join(' or ') + ')'
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

    if @sort_col.nil? or @sort_col.empty? or @sort_type.nil? or @sort_type.empty?
      @sort_col = 'fin_at'
      @sort_type = 'DESC'
    end
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

    if params[:check_xlog].nil?
      list
      render(:action => 'list')
      return
    end

    count = 0
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

    send_data(csv, :type => 'application/octet-stream;charset=UTF-8', :disposition => 'attachment;filename="zeptair_network_logs.csv"')
  end
end
