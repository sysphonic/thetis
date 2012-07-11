#
#= ApplicationController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
# 
#
#== Note:
#
#* Filters added to this controller will be run for all controllers in the application.
#* Likewise, all the methods added will be available for all controllers.
#

class ApplicationController < ActionController::Base

  require 'will_paginate'
  require RAILS_ROOT+'/lib/iain-http_accept_language/lib/http_accept_language'

# helper :all # include all helpers, all the time
  protect_from_forgery

  before_filter :set_locale
  before_filter :gate_process

  include LoginChecker

  begin
    if (User.count <= 0)
      User.create_init_user
    end
  rescue
  end

  def set_locale
    if params[:locale]
      cookies[:locale] = {
        :value => params[:locale],
        :expires => 1.year.from_now
      }
    end

    I18n.locale = params[:locale] || cookies[:locale] || request.compatible_language_from(I18n.available_locales)

    # logger.fatal "* Locale available : " + I18n.available_locales.inspect
    # logger.fatal "* Locale " + request.env['HTTP_ACCEPT_LANGUAGE'].inspect
    # logger.fatal "* Locale set to '#{I18n.locale}'"
  end

  #=== render
  #
  #Overrides ActionController::Base#render() to force layout XHR response.
  #
  #_action_:: Same as the corresponding argument of the super method.
  #_options_:: Same as the corresponding argument of the super method.
  #_&blk_:: Same as the corresponding argument of the super method.
  #
  def render(action=nil, options={}, &blk)
    opts = options
    if opts.empty? and !action.nil? and action.kind_of?(Hash)
      opts = action
    end
    unless opts.nil?
      if opts[:layout] == false
        opts[:layout] = 'layouts/xhr'
      end
    end
    super(action, options, &blk)
  end

 public
  #=== paginate_by_sql
  #
  def paginate_by_sql(model, sql, per_page, options={})
    if options[:count]
      if options[:count].is_a?(Integer)
        total = options[:count]
      else
        total = model.count_by_sql(options[:count])
      end
    else
      total = model.count_by_sql_wrapping_select_query(sql)
    end

    object_pages = model.paginate_by_sql(sql, {:page => params['page'], :per_page => per_page})
    #objects = model.find_by_sql_with_limit(sql, object_pages.current.to_sql[1], per_page)
    return [object_pages, object_pages, total]
  end

 protected
  #=== gate_process
  #
  #Does processes requiered for each access.
  #
  def gate_process

    HistoryHelper.keep_last(request)

    @login_user = User.find_by_id(session[:login_user_id])

    begin
      if @login_user.nil? \
           or @login_user.time_zone.nil? or @login_user.time_zone.empty?
        unless THETIS_USER_TIMEZONE_DEFAULT.nil? or THETIS_USER_TIMEZONE_DEFAULT.empty?
          Time.zone = THETIS_USER_TIMEZONE_DEFAULT
        end
      else
        Time.zone = @login_user.time_zone
      end
    rescue => evar
      logger.fatal(evar.to_s)
    end
  end
end

module ActiveRecord
  class Base
    def self.find_by_sql_with_limit(sql, offset, limit)
      sql = sanitize_sql(sql)
      add_limit!(sql, {:limit => limit, :offset => offset})
      find_by_sql(sql)
    end

    def self.count_by_sql_wrapping_select_query(sql)
      sql = sanitize_sql(sql)
      count_by_sql("select count(*) from (#{sql}) as my_table")
    end
  end
end

