#
#= LogsController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#The Action-Controller about Logs.
#
#== Note:
#
#*
#
class LogsController < ApplicationController
  layout 'base'

  before_action :check_login
  before_action do |controller|
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
        con << SqlHelper.get_sql_like(['Log.access_path'], "/#{params[:filter]}/")
    end

    include_user = false

    keyword = params[:keyword]
    unless keyword.blank?
      arr = []

      key_array = keyword.split(nil)
      key_array.each do |key|
        arr << "((User.id = Log.user_id) and #{SqlHelper.get_sql_like(['User.name', 'User.fullname'], key)})"
        arr << SqlHelper.get_sql_like(['Log.updated_at', 'Log.updated_at', :remote_ip, :log_type, :access_path, :detail], key)
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
      @sort_col = "updated_at"
      @sort_type = "DESC"
    end
    SqlHelper.validate_token([@sort_col, @sort_type], ['.'])
    order_by = ' order by ' + @sort_col + " " + @sort_type
    if @sort_col != 'Log.id'
      order_by << ', Log.id ' + @sort_type
    end

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

    raise(RequestPostOnlyException) unless request.post?

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

    raise(RequestPostOnlyException) unless request.post?

    Log.delete_all

    flash[:notice] = t('msg.delete_success')
    redirect_to(:action => 'list')
  end
end
