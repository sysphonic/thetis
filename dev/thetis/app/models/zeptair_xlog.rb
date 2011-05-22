#
#= ZeptairXlog
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#ZeptairXlog represents each network log of Zeptair VPN,
#which can be shown only to administrators.
#
#== Note:
#
#* 
#
class ZeptairXlog < ActiveRecord::Base

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
        logs = ZeptairXlog.find(:all, {:limit => over_num, :order => 'id ASC'})
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

    xlogs = ZeptairXlog.find(:all, :order => 'id ASC')

    csv_line = ''

    opt = {
      :force_quotes => true,
      :encoding => 'UTF-8'
    }

    csv_line << CSV.generate(opt) do |csv|

      # Header
      ary = []
      ary << I18n.t('activerecord.attributes.id')
      ary << ZeptairXlog.human_attribute_name('fin_at')
      ary << ZeptairXlog.human_attribute_name('req_at')
      ary << ZeptairXlog.human_attribute_name('time_taken')
      ary << User.human_name
      ary << I18n.t('zeptair.id')
      ary << ZeptairXlog.human_attribute_name('c_addr')
      ary << ZeptairXlog.human_attribute_name('c_port')
      ary << ZeptairXlog.human_attribute_name('s_addr')
      ary << ZeptairXlog.human_attribute_name('s_port')
      ary << ZeptairXlog.human_attribute_name('cs_protocol')
      ary << ZeptairXlog.human_attribute_name('cs_operation')
      ary << ZeptairXlog.human_attribute_name('cs_uri')
      ary << ZeptairXlog.human_attribute_name('c_agent')
      ary << ZeptairXlog.human_attribute_name('sc_status')

      csv << ary

      # Records
      xlogs.each do |xlog|
        ary = []
        ary << xlog.id
        ary << xlog.fin_at
        ary << xlog.req_at
        ary << xlog.time_taken
        ary << xlog.user_id
        ary << xlog.zeptair_id
        ary << xlog.c_addr
        ary << xlog.c_port
        ary << xlog.s_addr
        ary << xlog.s_port
        ary << xlog.cs_protocol
        ary << xlog.cs_operation
        ary << xlog.cs_uri
        ary << xlog.c_agent
        ary << xlog.sc_status

        csv << ary
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
