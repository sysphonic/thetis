#
#= ZeptairXlog
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#ZeptairXlog represents each network log of Zeptair VPN,
#which can be shown only to administrators.
#
class ZeptairXlog < ApplicationRecord

  #=== self.trim
  #
  #Trims records within specified number.
  #
  #_max_:: Max number.
  #
  def self.trim(max)
    begin
      count = ZeptairXlog.count
      if count > max
        over_num = count - max
        logs = ZeptairXlog.where(nil).limit(over_num).order('id ASC').to_a
        logs.each do |log|
          log.destroy
        end
      end
    rescue
    end
  end

  #=== self.export_csv
  #
  #Gets CSV description of all Users.
  #
  def self.export_csv

    xlogs = ZeptairXlog.where(nil).order('id ASC').to_a

    csv_line = ''

    opt = {
      :force_quotes => true,
      :encoding => 'UTF-8'
    }

    csv_line << CSV.generate(opt) do |csv|

      # Header
      arr = []
      arr << I18n.t('activerecord.attributes.id')
      arr << ZeptairXlog.human_attribute_name('fin_at')
      arr << ZeptairXlog.human_attribute_name('req_at')
      arr << ZeptairXlog.human_attribute_name('time_taken')
      arr << User.model_name.human
      arr << I18n.t('zeptair.id')
      arr << ZeptairXlog.human_attribute_name('c_addr')
      arr << ZeptairXlog.human_attribute_name('c_port')
      arr << ZeptairXlog.human_attribute_name('s_addr')
      arr << ZeptairXlog.human_attribute_name('s_port')
      arr << ZeptairXlog.human_attribute_name('cs_protocol')
      arr << ZeptairXlog.human_attribute_name('cs_operation')
      arr << ZeptairXlog.human_attribute_name('cs_uri')
      arr << ZeptairXlog.human_attribute_name('c_agent')
      arr << ZeptairXlog.human_attribute_name('sc_status')

      csv << arr

      # Records
      xlogs.each do |xlog|
        arr = []
        arr << xlog.id
        arr << xlog.fin_at
        arr << xlog.req_at
        arr << xlog.time_taken
        arr << xlog.user_id
        arr << xlog.zeptair_id
        arr << xlog.c_addr
        arr << xlog.c_port
        arr << xlog.s_addr
        arr << xlog.s_port
        arr << xlog.cs_protocol
        arr << xlog.cs_operation
        arr << xlog.cs_uri
        arr << xlog.c_agent
        arr << xlog.sc_status

        csv << arr
      end
    end

    return csv_line
  end

  #=== get_detail
  #
  #Gets detail of this ZeptairXlog.
  #
  def get_detail
    return self.inspect
  end
end
