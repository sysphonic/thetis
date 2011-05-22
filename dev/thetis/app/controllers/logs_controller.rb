#
#= LogsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Logs.
#
#== Note:
#
#*
#
class LogsController < ApplicationController
  layout 'base'

  include LoginChecker

  before_filter :check_login
  before_filter do |controller|
    controller.check_auth(User::AUTH_LOG)
  end


  #=== configure
  #
  #Shows form to edit configuration about Log.
  #
  def configure
    @yaml = ApplicationHelper.get_config_yaml
  end

  #=== index
  #
  #Shows logs list as default page.
  #
  def index
    list
    render(:action => 'list')
  end

  #=== list
  #
  #Shows list of Logs.
  #This method takes input of filter, keywords, sort options
  #and pagination parameters.
  #
  def list
    con = []

    case params[:filter]
     when 'all', '', nil
        ;
     when 'emails'
        con << "((Log.access_path like '%/mail_folders/%') or (Log.access_path like '%/mail_accounts/%') or (Log.access_path like '%/send_mails/%'))"
     else
        con << "(Log.access_path like '%/#{params[:filter]}/%')"
    end

    include_user = false

    keyword = params[:keyword]
    unless keyword.nil? or keyword.empty?
      ary = []

      key_array = keyword.split(nil)
      key_array.each do |key|
        key = "%" + key + "%"
        ary << "((User.id = Log.user_id) and (User.name like '#{key}' or User.fullname like '#{key}'))"
        ary << "(Log.updated_at like '#{key}' or remote_ip like '#{key}' or log_type like '#{key}' or access_path like '#{key}' or detail like '#{key}' )"
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
      @sort_col = "updated_at"
      @sort_type = "DESC"
    end
    order_by = ' order by ' + @sort_col + " " + @sort_type

    sql = 'select distinct Log.* from logs Log'
    if include_user
      sql << ', users User'
    end
    sql << where + order_by

    @log_pages, @logs, @total_num = paginate_by_sql(Log, sql, 50)
  end

  #=== search
  #
  #Shows search result.
  #Does same as list-action except rendered rhtml.
  #
  def search
    list
    render(:action => 'list')
  end

  #=== destroy
  #
  #Deletes Logs.
  #
  def destroy
    if params[:check_log].nil?
      list
      render(:action => 'list')
      return
    end

    count = 0
    params[:check_log].each do |key, value|
      if value == '1'
        Log.delete(key)
        count += 1
      end
    end

    list
    flash[:notice] = count.to_s + t('log.deleted')
    render(:action => 'list')
  end

  #=== destroy_all
  #
  #Deletes all Logs.
  #
  def destroy_all

    Log.delete_all

    flash[:notice] = t('msg.delete_success')
    redirect_to(:action => 'list')
  end
end
