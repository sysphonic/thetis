#
#= Setting
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Setting represents a setting of User.
#
#== Note:
#
#* 
#
class Setting < ActiveRecord::Base
  belongs_to :user

  public::CATEGORY_SCHEDULE = 'schedule'

  public::KEY_CALENDAR_WITH_TIMECARD_ICONS = 'calendar_with_timecard_icons'

  #=== self.get_for
  #
  #Gets Settings hash of the specified User.
  #
  #_user_id_:: Target User-ID.
  #_category_:: Target category. If not required, specify nil.
  #return:: Hash of Settings. { key => value }
  #
  def self.get_for(user_id, category=nil)
    begin
      con = ['user_id = ?', user_id]
      unless category.nil?
        con[0] << ' and category = ?'
        con << category
      end

      settings =  Setting.find(:all, :conditions => con)
    rescue
    end

    return nil if settings.nil? or settings.empty?

    hash = Hash.new

    settings.each do |setting|
      hash[setting.xkey] = setting.xvalue
    end

    return hash
  end

  #=== self.get_value
  #
  #Gets Setting value of the specified User.
  #
  #_user_id_:: Target User-ID.
  #_category_:: Target category.
  #_key_:: Target key.
  #return:: Setting value.
  #
  def self.get_value(user_id, category, key)
    begin
      con = ['user_id = ? and category = ? and xkey = ?', user_id, category, key]
      setting =  Setting.find(:first, :conditions => con)

      return setting.xvalue unless setting.nil?
    rescue
    end
    return nil
  end

  #=== self.save_value
  #
  #Saves Setting value for the specified User.
  #
  #_user_id_:: Target User-ID.
  #_category_:: Target category.
  #_key_:: Target key.
  #_value_:: Value to save.
  #
  def self.save_value(user_id, category, key, value)
    begin
      con = ['user_id = ? and category = ? and xkey = ?', user_id, category, key]
      setting =  Setting.find(:first, :conditions => con)
    rescue
    end

    if value.nil?
      unless setting.nil?
        setting.destroy
      end
    else
      if setting.nil?
        setting = Setting.new
        setting.user_id = user_id
        setting.category = category
        setting.xkey = key
        setting.xvalue = value
        setting.save!
      else
        setting.update_attribute(:xvalue, value)
      end
    end
  end

  # for Group

  #=== self.get_for_group
  #
  #Gets Settings hash of the specified Group.
  #
  #_group_id_:: Target Group-ID.
  #_category_:: Target category. If not required, specify nil.
  #return:: Hash of Settings. { key => value }
  #
  def self.get_for_group(group_id, category=nil)
    begin
      con = ['group_id = ?', group_id]
      unless category.nil?
        con[0] << ' and category = ?'
        con << category
      end

      settings =  Setting.find(:all, :conditions => con)
    rescue
    end

    return nil if settings.nil? or settings.empty?

    hash = Hash.new

    settings.each do |setting|
      hash[setting.xkey] = setting.xvalue
    end

    return hash
  end

  #=== self.get_group_value
  #
  #Gets Setting value of the specified Group.
  #
  #_group_id_:: Target Group-ID.
  #_category_:: Target category.
  #_key_:: Target key.
  #return:: Setting value.
  #
  def self.get_group_value(group_id, category, key)
    begin
      con = ['group_id = ? and category = ? and xkey = ?', group_id, category, key]
      setting = Setting.find(:first, :conditions => con)

      return setting.xvalue unless setting.nil?
    rescue
    end
    return nil
  end

  #=== self.save_group_value
  #
  #Saves Setting value for the specified Group.
  #
  #_group_id_:: Target Group-ID.
  #_category_:: Target category.
  #_key_:: Target key.
  #_value_:: Value to save.
  #
  def self.save_group_value(group_id, category, key, value)
    begin
      con = ['group_id = ? and category = ? and xkey = ?', group_id, category, key]
      setting = Setting.find(:first, :conditions => con)
    rescue
    end

    if value.nil?
      unless setting.nil?
        setting.destroy
      end
    else
      if setting.nil?
        setting = Setting.new
        setting.group_id = group_id
        setting.category = category
        setting.xkey = key
        setting.xvalue = value
        setting.save!
      else
        setting.update_attribute(:xvalue, value)
      end
    end
  end
end
