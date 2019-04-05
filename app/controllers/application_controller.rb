#
#= ApplicationController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class ApplicationController < ActionController::Base

  require('will_paginate')
  require(Rails.root.to_s+'/lib/iain-http_accept_language/lib/http_accept_language')

  protect_from_forgery(with: :exception)
  config.filter_parameters(:password)

  before_action(:set_locale)
  before_action(:gate_proc)

  include(LoginChecker)

  begin
    if (User.count <= 0)
      User.create_init_user
    end
  rescue
  end

  def set_locale
    if params[:locale]
      session[:locale] = params[:locale]
    end

    I18n.locale = (params[:locale] || session[:locale] || request.compatible_language_from(I18n.available_locales))

    # logger.fatal "* Locale available : " + I18n.available_locales.inspect
    # logger.fatal "* Locale " + request.env['HTTP_ACCEPT_LANGUAGE'].inspect
    # logger.fatal "* Locale set to '#{I18n.locale}'"
  end

 public
  #=== paginate_by_sql
  #
  def paginate_by_sql(model, sql, per_page, options={})

    total = nil
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
    opts = {
      :page => params['page'],
      :per_page => per_page,
      :total_entries => total
    }
    object_pages = model.paginate_by_sql(sql, opts)
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
      if (@login_user.nil? or @login_user.time_zone.blank?)
        Time.zone = THETIS_USER_TIMEZONE_DEFAULT unless THETIS_USER_TIMEZONE_DEFAULT.blank?
      else
        Time.zone = @login_user.time_zone
      end
    rescue => evar
      logger.fatal(evar.to_s)
    end
  end
end

