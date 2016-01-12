#
#= Research
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Research represents each answer (including not commited) to the questionnaire.
#
#== Note:
#
#* 
#
class Research < ActiveRecord::Base
  public::PERMIT_BASE = [:status, :q01_01, :q01_02, :q01_03, :q01_04, :q01_05, :q01_06, :q01_07, :q01_08, :q01_09, :q01_10, :q01_11, :q01_12, :q01_13, :q01_14, :q01_15, :q01_16, :q01_17, :q01_18, :q01_19, :q01_20, :q02_01, :q02_02, :q02_03, :q02_04, :q02_05, :q02_06, :q02_07, :q02_08, :q02_09, :q02_10, :q02_11, :q02_12, :q02_13, :q02_14, :q02_15, :q02_16, :q02_17, :q02_18, :q02_19, :q02_20, :q03_01, :q03_02, :q03_03, :q03_04, :q03_05, :q03_06, :q03_07, :q03_08, :q03_09, :q03_10, :q03_11, :q03_12, :q03_13, :q03_14, :q03_15, :q03_16, :q03_17, :q03_18, :q03_19, :q03_20]

  public::U_STATUS_IN_ACTON = 0
  public::U_STATUS_COMMITTED = 1

  public::STATUS_STOPPED = 0
  public::STATUS_STARTED = 1


  #=== self.page_dir
  #
  #Gets the path of the page directory.
  #
  #return:: Path of the pages directory.
  #
  def self.page_dir
    THETIS_RESEARCH_PAGE_DIR
  end

  #=== get_by_q_code
  #
  #Gets value of specified question-code.
  #
  #_q_code_:: Question-code.
  #return:: Value of specified question-code.
  #
  def get_by_q_code(q_code)
    case q_code
      when 'q01_01' then return self.q01_01
      when 'q01_02' then return self.q01_02
      when 'q01_03' then return self.q01_03
      when 'q01_04' then return self.q01_04
      when 'q01_05' then return self.q01_05
      when 'q01_06' then return self.q01_06
      when 'q01_07' then return self.q01_07
      when 'q01_08' then return self.q01_08
      when 'q01_09' then return self.q01_09
      when 'q01_10' then return self.q01_10
      when 'q01_11' then return self.q01_11
      when 'q01_12' then return self.q01_12
      when 'q01_13' then return self.q01_13
      when 'q01_14' then return self.q01_14
      when 'q01_15' then return self.q01_15
      when 'q01_16' then return self.q01_16
      when 'q01_17' then return self.q01_17
      when 'q01_18' then return self.q01_18
      when 'q01_19' then return self.q01_19
      when 'q01_20' then return self.q01_20

      when 'q02_01' then return self.q02_01
      when 'q02_02' then return self.q02_02
      when 'q02_03' then return self.q02_03
      when 'q02_04' then return self.q02_04
      when 'q02_05' then return self.q02_05
      when 'q02_06' then return self.q02_06
      when 'q02_07' then return self.q02_07
      when 'q02_08' then return self.q02_08
      when 'q02_09' then return self.q02_09
      when 'q02_10' then return self.q02_10
      when 'q02_11' then return self.q02_11
      when 'q02_12' then return self.q02_12
      when 'q02_13' then return self.q02_13
      when 'q02_14' then return self.q02_14
      when 'q02_15' then return self.q02_15
      when 'q02_16' then return self.q02_16
      when 'q02_17' then return self.q02_17
      when 'q02_18' then return self.q02_18
      when 'q02_19' then return self.q02_19
      when 'q02_20' then return self.q02_20

      when 'q03_01' then return self.q03_01
      when 'q03_02' then return self.q03_02
      when 'q03_03' then return self.q03_03
      when 'q03_04' then return self.q03_04
      when 'q03_05' then return self.q03_05
      when 'q03_06' then return self.q03_06
      when 'q03_07' then return self.q03_07
      when 'q03_08' then return self.q03_08
      when 'q03_09' then return self.q03_09
      when 'q03_10' then return self.q03_10
      when 'q03_11' then return self.q03_11
      when 'q03_12' then return self.q03_12
      when 'q03_13' then return self.q03_13
      when 'q03_14' then return self.q03_14
      when 'q03_15' then return self.q03_15
      when 'q03_16' then return self.q03_16
      when 'q03_17' then return self.q03_17
      when 'q03_18' then return self.q03_18
      when 'q03_19' then return self.q03_19
      when 'q03_20' then return self.q03_20
    end
  end

  #=== self.get_pages
  #
  #Gets paths of questionnaire pages.
  #
  #return:: Array of paths of questionnaire pages.
  #
  def self.get_pages

    pages = Dir.glob(Research.page_dir+"/_q[0-9][0-9].html.erb")
    pages = [] if pages.nil?

    return pages
  end

  #=== self.config
  #
  #Gets path of the configuration file about Research.
  #
  #return:: Path of the configuration file about Research.
  #
  def self.config

    return "#{::Rails.root.to_s}/config/_research.yml"
  end

  #=== self.get_config_yaml
  #
  #Gets YAML data from the configuration file.
  #
  #return:: YAML.
  #
  def self.get_config_yaml

    config = Research.config

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
  #
  def self.save_config_yaml(yaml)

    config = Research.config

    ApplicationHelper.f_ensure_exist(config)
    mode = ApplicationHelper.f_chmod(0666, config)

    begin
      f = File.open(config, 'w')
      f.write(yaml.ya2yaml(:syck_compatible => true))
      f.close
    rescue => evar
      logger.fatal(evar.to_s)
    end

    ApplicationHelper.f_chmod(mode, config)
  end

  #=== self.trim_config_yaml
  #
  #Removes disused YAML data of the configuration file.
  #
  #_valid_q_codes_:: Array of the valid q_code.
  #
  def self.trim_config_yaml(valid_q_codes)

    valid_q_codes = [] if valid_q_codes.nil?

    yaml = Research.get_config_yaml

    delete_keys = []

    yaml.each do |key, val|

      next if key.to_s.match(/^q\d{2}_\d{2}$/).nil?

      unless valid_q_codes.include?(key)
        delete_keys << key
      end
    end

    delete_keys.each do |key|
      yaml.delete key
    end

    Research.save_config_yaml yaml
  end

  #=== self.get_statistics_groups
  #
  #Gets Group-IDs for statistics.
  #
  #return:: Array of Group-IDs for statistics.
  #
  def self.get_statistics_groups

    yaml = Research.get_config_yaml

    unless yaml.nil? or yaml[:statistics].nil?
      groups = yaml[:statistics][:groups]
      unless groups.nil?
        return groups.split('|')
      end
    end

    return []
  end

  #=== self.set_statistics_groups
  #
  #Sets Group-IDs for statistics.
  #
  #_group_ids_:: Group-IDs.
  #
  def self.set_statistics_groups(group_ids)

    yaml = Research.get_config_yaml

    yaml = Hash.new if yaml.nil?

    if group_ids.nil?

      unless yaml[:statistics].nil?
        yaml[:statistics].delete(:groups)
      end

    else

      if yaml[:statistics].nil?
        yaml[:statistics] = Hash.new
      end

      yaml[:statistics][:groups] = group_ids.join('|')
    end

    Research.save_config_yaml(yaml)
  end

  #=== self.add_statistics_group
  #
  #Adds Group-ID for statistics.
  #
  #_group_id_:: Group-ID.
  #return:: Array of Group-IDs for statistics.
  #
  def self.add_statistics_group(group_id)

    yaml = Research.get_config_yaml

    yaml = Hash.new if yaml.nil?

    if yaml[:statistics].nil?
      yaml[:statistics] = Hash.new
    end

    groups = yaml[:statistics][:groups]

    if groups.nil?

      yaml[:statistics][:groups] = group_id
      arr = [group_id.to_s]

    else

      arr = groups.split('|')
      arr << group_id

      arr.compact!
      arr.delete('')

      yaml[:statistics][:groups] = arr.join('|')
    end

    Research.save_config_yaml(yaml)

    return arr
  end

  #=== self.delete_statistics_group
  #
  #Deletes Group-ID for statistics.
  #
  #_group_id_:: Group-ID.
  #return:: Array of Group-IDs for statistics.
  #
  def self.delete_statistics_group(group_id)

    yaml = Research.get_config_yaml

    if yaml.nil? or yaml[:statistics].nil?
      return []
    end

    groups = yaml[:statistics][:groups]

    return [] if groups.nil?

    arr = groups.split('|')
    arr.delete group_id.to_s

    arr.compact!
    arr.delete('')

    yaml[:statistics][:groups] = arr.join('|')

    Research.save_config_yaml(yaml)

    return arr
 end

  #=== self.get_status
  #
  #Gets research status.
  #
  #return:: String which represents the current research status.
  #
  def self.get_status

    pages = Research.get_pages

    if pages.nil? or pages.empty?
      return STATUS_STOPPED
    else
      return STATUS_STARTED
    end
  end

  #=== self.get_for
  #
  #Gets Research-record of specified User.
  #
  #_user_id_:: Target User-ID.
  #return:: Research-record of specified User.
  #
  def self.get_for(user_id)

    SqlHelper.validate_token([user_id])

    return Research.where("user_id=#{user_id.to_i}").first
  end

  #=== self.get_q_codes
  #
  #Gets String array of all question-codes.
  #
  #return:: String array of all question-codes.
  #
  def self.get_q_codes

    arr = []

    (1..ResearchesHelper::MAX_PAGES).each do |page|
      (1..ResearchesHelper::MAX_Q_BY_PAGE).each do |q|
        arr << sprintf('q%02d_%02d', page, q)
      end
    end

    return arr
  end

  #=== self.find_q_codes
  #
  #Finds question-codes in the specified HTML.
  #
  #_html_:: Target HTML.
  #return:: Hash of found question-codes and its form parameters |q_code, q_param|.
  #
  def self.find_q_codes(html)

    q_hash = {}   # |q_code, q_param|

    return q_hash if html.nil?

    all = Research.get_q_codes

    q_codes = html.scan(/[$](q\d{2}_\d{2})/)

    unless q_codes.nil?

      yaml = Research.get_config_yaml

      q_codes.each do |q_code_a|

        q_code = q_code_a.first

        if all.include?(q_code)
          if yaml[q_code].nil?
            q_hash[q_code] = nil
          else
            q_hash[q_code] = Marshal.load(Marshal.dump(yaml[q_code]))
          end
        end
      end
    end

    return q_hash
  end

  #=== self.select_q_caps
  #
  #Selects question-captions in the specified HTML.
  #
  #_html_:: Target HTML.
  #return:: Hash of found question-codes and its captions |q_code, q_cap|.
  #
  def self.select_q_caps(html)

    q_caps_h = {}   # |q_code, q_cap|

    return q_caps_h if html.nil?

    all = Research.get_q_codes

    q_codes = html.scan(/[$](q\d{2}_\d{2})/)

    unless q_codes.nil?
      q_codes.each do |q_code_a|

        q_code = q_code_a.first

        if all.include?(q_code)

          trimmed = html.gsub(/([\r\n]|&nbsp;)/, " ").gsub(/>\s+?</m, "><")
          trimmed = trimmed.gsub(/<[^>]*>/, "<")

#Debug
#File.open(Research.page_dir+"/#{trimmed.gsub(/[<>\/\\\"'%*]/, '')[0,10]}", 'w') do |file|
#  file.write(trimmed);
#end

          #x pattern = "([$]q\d{2}_\d{2})??.*?>([^<>]+?)<.+?[$]#{q_code}"
          #x pattern = ">([^<>]+?)<(?:(?!>[^<>]+<).)*[$]#{q_code}"
          #pattern = ">([^<>]+?)<.+?[$]#{q_code}"
          pattern = "(?:^|<)([^<]+?)[<\s]*?[$]#{q_code}"
          founds = trimmed.scan(Regexp.new(pattern, Regexp::MULTILINE))
          if founds.nil? or founds.empty?
            q_cap = nil
          else
            q_caps = founds.first
            q_cap = q_caps[0].strip
          end
          q_caps_h[q_code] = q_cap
        end
      end
    end

    return q_caps_h
  end

  #=== self.replaceCtrl
  #
  #Replaces tags on the page with proper input-controls.
  #
  #_html_:: Target HTML.
  #_q_code_:: ID of the tag.
  #_q_param_:: Control informations of the tag.
  #return:: Result HTML.
  #
  def self.replaceCtrl(html, q_code, q_param)

    return html if html.nil? or q_param.nil?

    q_type = q_param[:type]
    q_vals = q_param[:values]

    ctrl = ''
    ctrl_id = "research_#{q_code}"
    ctrl_name = "research[#{q_code}]"
    case q_type
      when 'radio'
        ctrl_name << '[]' if q_type == 'checkbox'
        vals = q_vals.gsub(/\r\n/, "\n").split("\n")
        vals.each do |val|
          ctrl += "<%= radio_button('research', '#{q_code}', h('#{val}')) %> <%= h('#{val}') %><br/>\n"
        end

      when 'checkbox'
        vals = q_vals.gsub(/\r\n/, "\n").split("\n")
        vals.each do |val|
          ctrl += "<%\n"
          ctrl += "checked = ''\n"
          ctrl += "if !@research.#{q_code}.nil? and @research.#{q_code}.split(\"\\n\").include?(\"#{val}\")\n"
          ctrl += "  checked = 'checked'\n"
          ctrl += "end\n"
          ctrl += "%>\n"
          ctrl += "<input type='checkbox' name='research[#{q_code}][]' value='<%= h('#{val}') %>' <%= checked %>> <%= h('#{val}') %><br/>\n"
          ctrl += "<input type='hidden' name='research[#{q_code}][]' value=''>\n"
        end

      when 'select'
        vals = q_vals.gsub(/\r\n/, "\n").split("\n")
        opts = []
        opts << "[h('" + I18n.t('msg.select_item') + "'), h('')]"
        vals.each do |val|
          opts << "[h('#{val}'), h('#{val}')]"
        end

        ctrl += "<% opts = options_for_select([#{opts.join(',')}], @research.#{q_code}) %>\n"
        ctrl += "<%= select_tag('research[#{q_code}]', opts) %>\n"

      when 'textarea'
        if q_vals.to_i == 1
          ctrl += "<%= text_field('research', '#{q_code}', :style => 'width:100%') %><br/>\n"
        else
          ctrl += "<%= text_area('research', '#{q_code}', :rows => '#{q_vals}', :style => 'width:100%') %><br/>\n"
        end
    end

    pattern = '[$]' + q_code
    html.gsub!(Regexp.new(pattern, Regexp::MULTILINE), ctrl)

    return html
  end

end
