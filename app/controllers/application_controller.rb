#
#= ApplicationController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#== Note:
#
#* Filters added to this controller will be run for all controllers in the application.
#* Likewise, all the methods added will be available for all controllers.
#

class ApplicationController < ActionController::Base

  require 'will_paginate'
  require ::Rails.root.to_s+'/lib/iain-http_accept_language/lib/http_accept_language'

  protect_from_forgery(with: :exception)
  config.filter_parameters(:password)

  before_action :set_locale
  before_action :gate_proc

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

 public
  #=== paginate_by_sql
  #
  def paginate_by_sql(model, sql, per_page, options={})
    if options[:count].blank?
      total = model.count_by_sql_wrapping_select_query(sql)
    else
      if options[:count].is_a?(Integer)
        total = options[:count]
      #else
      #  total = model.count_by_sql(options[:count])
      end
    end

    SqlHelper.validate_token([params['page']])
    object_pages = model.paginate_by_sql(sql, {:page => params['page'], :per_page => per_page})
    return [object_pages, object_pages, total]
  end

 protected
  #=== gate_proc
  #
  #Does procedure called by each access.
  #
  def gate_proc

    HistoryHelper.keep_last(request, params)

    if (request.get? and request.xhr?)
      unless valid_authenticity_token?(session, form_authenticity_param)
        logger.fatal("[ERROR] CSRF token mismatched: #{form_authenticity_param}")
        render(:partial => 'common/login_watcher')
        return
      end
    end

    SqlHelper.validate_token([session[:login_user_id]])
    begin
      @login_user = User.find(session[:login_user_id])
    rescue => evar
      @login_user = nil
    end

    begin
      if @login_user.nil? or @login_user.time_zone.blank?
        Time.zone = THETIS_USER_TIMEZONE_DEFAULT unless THETIS_USER_TIMEZONE_DEFAULT.blank?
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
    def self.count_by_sql_wrapping_select_query(sql)
      sql = sanitize_sql(sql)
      count_by_sql("select count(*) from (#{sql}) as my_table")
    end

    #=== get_timestamp_exp
    #
    #Gets expression of timestamp.
    #
    #_req_full_:: Flag to require full expression.
    #_attr_:: Timestamp attribute.
    #return:: Expression of timestamp.
    #
    def get_timestamp_exp(req_full=true, attr=:updated_at)
      val = self.send(attr)
      if val.nil?
        return I18n.t('msg.hyphen')
      else
        if req_full
          format = THETIS_DATE_FORMAT_YMD+' %H:%M'
        else
          if UtilDate.create(val).get_date == Date.today
            format = '%H:%M'
          else
            format = THETIS_DATE_FORMAT_YMD
          end
        end
        return val.strftime(format)
      end
    end
  end
end

