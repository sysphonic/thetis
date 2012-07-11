#
#= OfficeMap
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#OfficeMap preferences and configurations related to each User.
#
#== Note:
#
#* 
#
class OfficeMap < ActiveRecord::Base
  attr_accessible(:group_id, :img_enabled, :file)

  validates_length_of(:img_content, :within => 1..THETIS_IMAGE_MAX_KB*1024, :allow_nil => true)
  validates_format_of(:img_content_type, :with => /^image\/(p?jpeg|gif|(x-)?png)$/i, :allow_nil => true)


  #=== self.get_for_group
  #
  #Gets OfficeMap of the specified Group.
  #If not exists, returns default settings.
  #
  #_group_id_:: Target Group-ID.
  #_incl_img_content_::Flag to include image content.
  #return:: OfficeMap of the specified Group.
  #
  def self.get_for_group(group_id, incl_img_content=false)

    if group_id.nil?
      office_map = nil
    else
      if incl_img_content
        begin
          office_map = OfficeMap.find(:first, :conditions => ['group_id=?', group_id])
        rescue
        end
      else
        sql = 'select id, group_id, img_enabled, img_name, img_size, img_content_type, created_at, updated_at from office_maps'
        sql << " where group_id=#{group_id}"
        begin
          office_map = OfficeMap.find_by_sql(sql).first
        rescue
        end
      end
    end

    if office_map.nil?
      office_map = OfficeMap.new
      office_map.group_id = group_id.to_i unless group_id.nil?
      office_map.img_enabled = false
    end

    return office_map
  end

  #=== file
  #
  #
  #
  def file
  end
 
  #=== file=
  #
  #
  #
  def file=(file)
    write_attribute(:img_name, file.original_filename)
    write_attribute(:img_size, file.size)
    write_attribute(:img_content_type, file.content_type.strip)
    write_attribute(:img_content, file.read)
  end
end
