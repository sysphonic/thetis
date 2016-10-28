#
#= Log
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Log represents each access log, which can be shown only to administrators.
#
#== Note:
#
#* 
#
class Log < ApplicationRecord

  public::INFO = 'INFO'
  public::CHECK = 'CHECK'
  public::WARN = 'WARN'
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
        logs = Log.where(nil).limit(over_num).order('id ASC').to_a
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
      detail <<  err.to_s[0, 512] + '<br/>' + ApplicationHelper.stacktrace(err).join('<br/>')

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
    if log._build(type, request, detail)
      begin
        log.save
      rescue
      end
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
  #return:: true if succeeded, false otherwise.
  #
  def _build(type, request, detail)

    self.updated_at = Time.now

    unless request.nil?
      unless request.session[:login_user_id].nil?
        self.user_id = request.session[:login_user_id]
      end
      self.remote_ip = request.remote_ip
      self.access_path = request.path
    end
    self.log_type = type.to_s

    user_agent = ((request.nil? or request.env['HTTP_USER_AGENT'].nil?)?'':(request.env['HTTP_USER_AGENT']+': '))
    ['Googlebot', 'bingbot', 'Baiduspider'].each do |bot|
      return false if user_agent.include?(bot)
    end

    self.detail = user_agent + detail
    return true
  end
end
