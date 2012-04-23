#
#= ApplicationHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Methods added to this helper will be available to all templates in the application.
#
#== Note:
#
#* 
#
module ApplicationHelper
  require 'tempfile'
  require 'uri'     # for URI.extract()


  #=== self.split_preserving_quot
  #
  #Splits string preserving quotations.
  #
  #_quot_:: Quotation character.
  #_delim_:: Delimiter.
  #return:: Array of the parts.
  #
  def self.split_preserving_quot(str, quot, delim)

    return nil if str.nil?
    return str if quot.nil? or delim.nil?

    regexp = Regexp.new("([#{quot}](\\#{quot}|[^#{quot}])*[#{quot}])*#{delim}")
    return str.split(regexp)
  end

  #=== self.get_timestamp
  #
  #Gets timestamp string for the specified ActiveRecord object.
  #Useful to display images always up-to-date.
  #
  #_obj_:: Target ActiveRecord.
  #return:: Timestamp string.
  #
  def self.get_timestamp(obj)

    if obj.updated_at.nil?
      return nil
    else
      return obj.updated_at.utc.strftime('%Y%m%d%H%M%S')
    end
  end

  #=== self.extract_uri_a
  #
  #Gets the URI expression from the specified string.
  #
  #_str_:: Target string.
  #return:: Array of extracted URI.
  #
  def self.extract_uri_a(str)

    return URI.extract(str)
  end

  #=== self.get_sort_direction_exp
  #
  #Gets the expression of the sorting direction for the specified column.
  #
  #_col_name_:: Name of the target column.
  #_sort_col_:: Name of the currently selected column to sort by.
  #_sort_type_:: Currently selected sorting direction. 'ASC' or 'DESC'.
  #
  def self.get_sort_direction_exp(col_name, sort_col, sort_type)

    return (sort_col==col_name)?((sort_type=='ASC')?I18n.t('sort.asc'):I18n.t('sort.desc')):''
  end

  #=== self.sort_updated_at
  #
  #Sorts an array by updated_at field.
  #
  #_ary_:: Target array.
  #
  def self.sort_updated_at(ary)

    ary.sort! { |elem_a, elem_b|

      idx_a = elem_a.updated_at || DateTime.new
      idx_b = elem_b.updated_at || DateTime.new

      idx_b - idx_a
    }
  end

  #=== self.get_overlapped_span
  #
  #Gets overlapped span.
  #
  #_t1_start_:: Start time of the first span.
  #_t1_end_:: End time of the first span.
  #_t2_start_:: Start time of the second span.
  #_t2_end_:: End time of the second span.
  #return:: Array of the start and end time of the overlapped span. If not exists, returns nil.
  #
  def self.get_overlapped_span(t1_start, t1_end, t2_start, t2_end)

    if (t1_start <= t2_start) and (t2_start < t1_end)
      span_from = t2_start
    elsif t2_start <= t1_start and t1_start < t2_end
      span_from = t1_start
    else
      return nil
    end
    span_to = (t1_end < t2_end)?t1_end:t2_end
    return [span_from, span_to]
  end

  #=== self.float_exp
  #
  #Gets float expression.
  #ex. (max_prec = 2)
  #  100 -> 100.0, 1.33333 -> 1.33
  #
  #_f_:: Target float.
  #_max_prec_:: Max precision.
  #return:: Escaped string.
  #
  def self.float_exp(f, max_prec)

    exp = f.to_s
    vals = exp.split('.')
    if vals.length <= 1 or vals.last.length <= max_prec
      return exp
    else
      return sprintf("%.#{max_prec}f", f)
    end
  end

  #=== self.h_s_quote
  #
  #Escapes a specified string as an argument with single-quotes of JavaScript.
  #
  #_str_:: Target string.
  #return:: Escaped string.
  #
  def self.h_s_quote(str)

    return nil if str.nil? or str.empty?

    return ERB::Util.html_escape(str).gsub("'"){"\\'"}
  end

  #=== self.chmod_parent
  #
  #Changes mode of the parent directory of the specified file.
  #
  #_mode_:: New mode.
  #_path_:: Target file path.
  #return:: Old mode.
  #
  def self.chmod_parent(mode, path)

    return nil if path.nil? or mode.nil?

    ret = nil
    begin
      parent = File.dirname(path)
      ret = File.stat(parent).mode
      File.chmod(mode, parent)
    rescue => evar
      Log.add_error(nil, evar, ("%o" % mode))
    end

    return ret
  end

  #=== self.delete_file_safe
  #
  #Removes the specified files safe.
  #
  #_paths_:: Target file paths.
  #return:: Number of deleted files.
  #
  def self.delete_file_safe(paths)

    return if paths.nil?

    paths = paths.to_a

    ret = 0

    paths.each do |path|
      if FileTest.exist?(path)
        begin
          ret = File.delete(path)
        rescue
          mode = ApplicationHelper.chmod_parent(0666, path)
          begin
            ret = File.delete(path)
          rescue => evar
            Log.add_error(nil, evar)
          end
          ApplicationHelper.chmod_parent(mode, path)
        end
      end
    end

    return ret
  end

  #=== self.config
  #
  #Gets path of the configuration file of Thetis.
  #
  #return:: Path of the configuration file of Thetis.
  #
  def self.config

    return "#{RAILS_ROOT}/config/_config.yml"
  end

  #=== self.get_config_yaml
  #
  #Gets YAML data from the configuration file.
  #
  #return:: YAML.
  #
  def self.get_config_yaml

    config = ApplicationHelper.config

    if FileTest.exist?(config) and !FileTest.zero?(config) 
      yaml = YAML.load_file config
    else
      yaml = Hash.new
    end

    return yaml
  end

  #=== self.save_config_yaml
  #
  #Saves YAML data into the configuration file.
  #
  #_yaml_:: Target YAML
  #_force_restart_:: Flag to force restarted on Passenger.
  #
  def self.save_config_yaml(yaml, force_restart=true)

    config = ApplicationHelper.config

    ApplicationHelper.f_ensure_exist(config)
    mode = ApplicationHelper.f_chmod(0666, config)

    begin
      f = File.open(config, 'w')
      f.write(yaml.ya2yaml(:syck_compatible => true))
      f.close
    rescue => evar
      Log.add_error(nil, evar)
    end

    ApplicationHelper.f_chmod(mode, config)

    if force_restart
      ApplicationHelper.touch_to_restart
    end
  end

  #=== self.touch_to_restart
  #
  #Creates tmp/restart.txt to force restarted on Passenger.
  #
  def self.touch_to_restart

    restart_txt = "#{RAILS_ROOT}/tmp/restart.txt"

    ApplicationHelper.f_ensure_exist(restart_txt)
    begin
      File.chmod(0666, restart_txt)
    rescue => evar
      Log.add_error(nil, evar)
    end
  end

  #=== self.root_url
  #
  #Gets root URL.
  #
  #_request_:: Request.
  #return:: Root URL.
  #
  def self.root_url(request)

    return request.protocol + request.host_with_port
  end

  #=== self.format_text_block
  #
  #Format text of multi-lines to HTML style like <pre></pre>.
  #
  #_text_:: Source text.
  #return:: Formatted text.
  #
  def self.format_text_block(text)
    return text.gsub("\n", '<br/>').gsub('  ', '&nbsp; ')
  end

  #=== self.url_for
  #
  #Custom url_for for use in models.
  #
  #_opt_:: URL path parameters.
  #return:: URL.
  #
  def self.url_for(opt=nil)

    return THETIS_RELATIVE_URL_ROOT.clone if opt.nil?

    url = ''
    prms = []

    opt.each do |key, value|
      case key.to_s
        when 'controller'
          url = THETIS_RELATIVE_URL_ROOT + '/' + value + url
        when 'action'
          url << '/' + value
        else
          value = value.to_s
          value = value.gsub(' ', '+'  )
          value = value.gsub('!', '%21')
          value = value.gsub('"', '%22')
          value = value.gsub('#', '%23')
          value = value.gsub('$', '%24')
          value = value.gsub('%', '%25')
          value = value.gsub('&', '%26')
          value = value.gsub('\'','%27')
          value = value.gsub('(', '%28')
          value = value.gsub(')', '%29')
          value = value.gsub('*', '%2A')
          value = value.gsub('+', '%2B')
          value = value.gsub(',', '%2C')
          value = value.gsub('/', '%2F')
          value = value.gsub(':', '%3A')
          value = value.gsub(';', '%3B')
          value = value.gsub('<', '%3C')
          value = value.gsub('=', '%3D')
          value = value.gsub('>', '%3E')
          value = value.gsub('?', '%3F')
          value = value.gsub('@', '%40')
          value = value.gsub('[', '%5B')
          value = value.gsub('\\','%5C')
          value = value.gsub(']', '%5D')
          value = value.gsub('^', '%5E')
          value = value.gsub('`', '%60')
          value = value.gsub('|', '%7C')
          value = value.gsub('~', '%7E')

          prms << key.to_s + '=' + value.to_s
      end
    end

    return [url, prms.join('&')].join('?')
  end

  #=== self.dup_hash
  #
  #Duplicates hashtable.
  #
  #_hash_:: Hashtable.
  #return:: Duplicated hashtable.
  #
  def self.dup_hash(hash)

    return nil if hash.nil?

    begin
      ret = Marshal.load(Marshal.dump(hash))
    rescue
      ret = {}
      hash.each{|key, value|
        begin
          ret[key] = Marshal.load(Marshal.dump(value))
        rescue
        end
      }
    end

    return ret
  end

  #=== self.get_fwd_params
  #
  #Gets params to forward.
  #(Removes :controller and :action from the specified params)
  #
  #_params_:: Request parameters.
  #return:: Parameters to forward.
  #
  def self.get_fwd_params(params)

    return nil if params.nil?

    prms = ApplicationHelper.dup_hash(params)
    prms.delete(:controller)
    prms.delete(:action)

    return prms
  end

  #=== self.config_dir
  #
  #Gets the path of the config directory.
  #
  #return:: Path of the config directory.
  #
  def self.config_dir
    "#{RAILS_ROOT}/config"
  end

  #=== self.trim_comment
  #
  #Removes comment part from a line.
  #
  #_line_:: Target line.
  #return:: Result string.
  #
  def self.trim_comment(line)

    return line if line.nil? or line.empty?

    quot = nil
    last_ch = nil
    comment_idx = 0
    line.scan(/./m){ |ch|
      if last_ch != '\\' and ch == quot
        quot = nil
      elsif last_ch != '\\' and (ch == '"' or ch == '\'')
        quot = ch
      elsif quot.nil? and ch == '#'
        break
      end

      last_ch = ch
      comment_idx += 1
    }

    return line[0, comment_idx]
  end

  #=== self.f_ensure_exist
  #
  #Ensures existing of the specified file.
  #
  #_file_:: Path of the file.
  #
  def self.f_ensure_exist(file)

    return if FileTest.exist?(file)

    mode = ApplicationHelper.chmod_parent(0666, file)

    begin
      f = File.open(file, 'w')
      f.close
    rescue => evar
      Log.add_error(nil, evar)
    end

    ApplicationHelper.chmod_parent(mode, file)
  end

  #=== self.f_chmod
  #
  #Changes mode of the specified file.
  #Special thanks to: masr
  #
  #_mode_:: New mode.
  #_path_:: Target file path.
  #return:: Old mode.
  #
  def self.f_chmod(mode, path)

    return nil if path.nil? or mode.nil?

    ret = nil
    begin
      ret = File.stat(path).mode
      File.chmod(mode, path)
    rescue => evar
      Log.add_error(nil, evar, ("%o" % mode))
    end

    return ret
  end

  #=== self.f_insert
  #
  #Inserts data into the specified file.
  # from "Ruby Recipe Book"
  #
  #_path_:: Path of the target file.
  #_line_idx_:: Line index to insert data. Specify -1 to append.
  #_data_:: Data to insert.
  #
  def self.f_insert(path, line_idx, data)

    return if path.nil? or data.nil? or data.to_s.empty?

    mode = ApplicationHelper.f_chmod(0666, path)

    begin
      temp = Tempfile.new('_thetis')

      File.open(path){ |file|
        if line_idx < 0
          while line = file.gets
            temp.write(line)
          end
          temp.write(data)
        else
          line_idx.times {
            if line = file.gets
              temp.write(line)
            end
          }
          temp.write(data)
          while line = file.gets
            temp.write(line)
          end
        end
      }
      temp.close(false)
      FileUtils.mv(temp.path, path)

    rescue => evar
      Log.add_error(nil, evar)
    end

    ApplicationHelper.f_chmod(mode, path)
  end

  #=== self.f_replace
  #
  #Replaces data in the specified file.
  #
  #_path_:: Path of the target file.
  #_line_idx_:: Line index to start to replace.
  #_line_num_:: Lines to replace.
  #_data_:: Data to replace with.
  #
  def self.f_replace(path, line_idx, line_num, data)

    return if path.nil?

    data = '' if data.nil?

    mode = ApplicationHelper.f_chmod(0666, path)

    begin
      temp = Tempfile.new('_thetis')

      File.open(path){ |file|
        line_idx.times {
          if line = file.gets
            temp.write(line)
          end
        }
        temp.write(data)
        while line = file.gets
          if line_num > 0
            line_num -= 1
            next
          end 
          temp.write(line)
        end
      }
      temp.close(false)
      FileUtils.mv(temp.path, path)

    rescue => evar
      Log.add_error(nil, evar)
    end

    ApplicationHelper.f_chmod(mode, path)
  end

  #=== self.f_find
  #
  #Finds line in the specified file.
  #
  #_path_:: Path of the target file.
  #_exp_:: Expression to find.
  #return:: Line index if found, -1 otherwise.
  #
  def self.f_find(path, exp)

    return -1 if path.nil? or exp.nil?

    line_idx = -1

    File.open(path){ |file|
      while line = file.gets
        line_idx += 1
        if line.match(exp)
          return line_idx
        end 
      end
    }
    return -1;
  end

  #=== self.custom_pagination
  #
  #Replace data in specified file.
  #
  #_pagination_:: Pagination links.
  #return:: Customized pagination links.
  #
  def self.custom_pagination(pagination)
    unless pagination.nil?
      pagination = pagination.gsub('<div class="pagination">', '<div class="pagination" style="display:inline;">')
      pagination = pagination.gsub(' Previous', I18n.t('btn.prev_page'))
      pagination = pagination.gsub('Next ', I18n.t('btn.next_page'))
      pagination = pagination.gsub('<a ', '<a class="a_pagination" ')
      pagination = pagination.gsub(/href="([^"]+)"/, 'href="#" onclick="prog(\'TOP-RIGHT\'); location.href=\'\1\'; return false;"')
    end
    return pagination
  end

  #=== self.take_nbytes(str, n, dots)
  #
  #Gets sub-string of first n bytes or less.
  # from "Ruby Recipe Book"
  #
  #_str_:: Target string.
  #_n_:: Length within which the specified string is trimmed.
  #_dots_:: Abbreviation mark to append when omitted. If not required, specify nil.
  #return:: Trimmed string.
  #
  def self.take_nbytes(str, n, dots)
    buf = ''
    str.split(//).each do |ch|
      break if buf.size + ch.size > n
      buf << ch
    end

    buf << dots if !dots.nil? and buf.length < str.length

    return buf
  end

  #=== self.take_ncols(str, n, dots)
  #
  #Gets sub-string of first n columns or less.
  #
  #_str_:: Target string.
  #_n_:: Length within which the specified string is trimmed.
  #_dots_:: Abbreviation mark to append when omitted. If not required, specify nil.
  #return:: Trimmed string.
  #
  def self.take_ncols(str, n, dots)
    buf = ''
    cols = 0
    str.split(//).each do |ch|
      cols += (ch.size > 1)?2:1
      break if cols > n
      buf << ch
    end

    buf << dots if !dots.nil? and buf.length < str.length

    return buf
  end
end
