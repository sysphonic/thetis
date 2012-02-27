#
#= Log
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Log represents each access log, which can be shown only to administrators.
#
#== Note:
#
#* 
#
class Log < ActiveRecord::Base

  public::INFO = 'INFO'
  public::CHECK = 'CHECK'
  public::WARM = 'WARN'
  public::ERROR = 'ERROR'

  #=== self.trim
  #
  #Trims records within specified number.
  #
  #_max_:: Max number.
  #
  def self.trim(max)
    begin
      count = Log.count
      if count > max
        over_num = count - max
        logs = Log.find(:all, {:limit => over_num, :order => 'id ASC'})
        logs.each do |log|
          log.destroy
        end
      end
    rescue
    end
  end

  #=== self.add_info
  #
  #Adds a INFO-Log.
  #
  #_request_:: Request parameters from client.
  #_detail_:: Detail information.
  #
  def self.add_info(request, detail)

    Log.add(INFO, request, detail)
  end

  #=== self.add_check
  #
  #Adds a CHECK-Log.
  #
  #_request_:: Request parameters from client.
  #_detail_:: Detail information.
  #
  def self.add_check(request, detail)

    Log.add(CHECK, request, detail)
  end

  #=== self.add_warn
  #
  #Adds a WARN-Log.
  #
  #_request_:: Request parameters from client.
  #_detail_:: Detail information.
  #
  def self.add_warn(request, detail)

    Log.add(WARN, request, detail)
  end

  #=== self.add_error
  #
  #Adds a ERROR-Log.
  #
  #_request_:: Request parameters from client.
  #_err_:: Error.
  #_detail_:: Detail information.
  #
  def self.add_error(request, err, detail=nil)

    detail = '' if detail.nil?

    unless err.nil?
      detail << ': <br/>' unless detail.empty?
      detail <<  err.to_s[0, 512] + '<br/>' + err.backtrace.join('<br/>')

      logger.fatal(err.to_s)
    end

    logger.fatal(detail) unless detail.nil?

    Log.add(ERROR, request, detail)
  end

  #=== self.add
  #
  #Adds a Log.
  #
  #_type_:: Log type.
  #_request_:: Request parameters from client.
  #_detail_:: Detail information.
  #
  def self.add(type, request, detail)

    Log.trim($thetis_config[:log]['max_num'].to_i - 1)

    detail = detail.gsub(/'/m, '\\\\\'')

    log = self.new
    log._build(type, request, detail)
    begin
      log.save
    rescue
    end
  end

  #=== info?
  #
  #Checks if the type of the log is INFO.
  #
  #return:: true if type is INFO, false otherwise.
  #
  def info?

    return (self.log_type == INFO)
  end

  #=== error?
  #
  #Check if the type of the log is ERROR.
  #
  #return:: true if type is ERROR, false otherwise.
  #
  def error?

    return (self.log_type == ERROR)
  end

  #=== _build
  #
  #Builds a Log-record.
  #
  #_type_:: Log type.
  #_request_:: Request parameters from client.
  #_detail_:: Detail information.
  #
  def _build(type, request, detail)

    self.updated_at = Time.now

    unless request.nil?
      unless request.session[:login_user].nil?
        self.user_id = request.session[:login_user].id
      end
      self.remote_ip = request.remote_ip
      self.access_path = request.path
    end
    self.log_type = type

    self.detail = ((request.nil? or request.env['HTTP_USER_AGENT'].nil?)?'':(request.env['HTTP_USER_AGENT']+': ')) + detail
  end
end
