#
#= TeamsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Teams.
#
#== Note:
#
#* 
#
class TeamsController < ApplicationController
  layout 'base'

  include LoginChecker

  before_filter :check_login
  before_filter do |controller|
    controller.check_auth(User::AUTH_TEAM)
  end


  #=== index
  #
  #Shows Teams list as default page.
  #
  def index
    Log.add_info(request, params.inspect)

    list
    render(:action => 'list')
  end

  #=== list
  #
  #Shows list of Teams.
  #This method takes input of filter, keywords, sort options
  #and pagination parameters.
  #
  def list
    if params[:action] == 'list'
      Log.add_info(request, params.inspect)
    end

    if params[:filter].nil? or params[:filter] == 'all'
      con = ['Team.id > 0']
    else
      con = ["(Team.status = '#{params[:filter]}')"]
    end
    
    keyword = params[:keyword]
    unless keyword.nil? or keyword.empty?
      key_array = keyword.split(nil)
      key_array.each do |key| 
        con << "(name like '%#{key}%' or item_id = '#{key}')"
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
      @sort_col = "Team.id"
      @sort_type = "ASC"
    end
    order_by = ' order by ' + @sort_col + ' ' + @sort_type

    sql = 'select distinct Team.* from teams Team'
    sql << where + order_by

    @team_pages, @teams, @total_num = paginate_by_sql(Team, sql, 10)
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
  #Deletes the specified Team.
  #
  def destroy
    Log.add_info(request, params.inspect)

    begin
      Team.destroy(params[:id])
    rescue
    end

    list
    flash[:notice] = t('msg.delete_success')
    render(:action => 'list')
  end

  #=== get_users_a
  #
  #Gets Users array who belong to this Team.
  #
  #return:: Groups array without empty element. If no Groups, returns empty array.
  #
  def get_groups_a
    Log.add_info(request, params.inspect)

    return [] if self.groups.nil? or self.groups.empty?

    array = self.groups.split('|')
    array.compact!
    array.delete('')

    return array
  end

 private
  #=== check_member
  #
  #Filter method to check if current User is member of specified Team.
  #
  def check_member

    return if params[:id].nil? or params[:id].empty? or !session[:login_user]

    if Item.find(params[:id]).user_id != session[:login_user].id
      Log.add_check(request, '[check_member]'+request.to_s)

      flash[:notice] = t('team.need_to_be_member')
      redirect_to(:controller => 'desktop', :action => 'show')
    end
  end
end
