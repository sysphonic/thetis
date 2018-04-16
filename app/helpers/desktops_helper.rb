#
#= DesktopsHelper
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
module DesktopsHelper

  #=== self.get_user_before_login
  #
  #Gets User specified to be taken before LOGIN.
  #
  #return:: User specified to be taken before LOGIN.
  #
  def self.get_user_before_login

    user = nil

    yaml = ApplicationHelper.get_config_yaml

    user_before_login = YamlHelper.get_value(yaml, 'desktop.user_before_login', nil)

    unless user_before_login.nil? or user_before_login.empty?
      begin
        user = User.find(user_before_login)
      rescue => evar
        Log.add_error(nil, evar)
      end
    end

    return user
  end

  #=== self.merge_toys
  #
  #Merges Toys on the desktop with on the latest-tray.
  #
  #_desktop_toys_:: Array of the Toys on the desktop.
  #_latests_toys_:: Array of the Toys on the latest-tray.
  #_deleted_arr_:: Array in which the duplicated Toys should be added.
  #return:: deleted_arr.
  #
  def self.merge_toys(desktop_toys, latests_toys, deleted_arr)

    latests_toys.each do |tray_toy|
      found_toy = desktop_toys.find{ |toy|
            ((toy.xtype == tray_toy.xtype) and (toy.target_id == tray_toy.target_id))
          }
      unless found_toy.nil?
        deleted_arr << tray_toy
      end
    end

    return deleted_arr
  end

  #=== self.find_empty_block
  #
  #Finds an empty block on the desktop.
  #
  #_user_:: Target User.
  #return:: Empty block [x, y].
  #
  def self.find_empty_block(user)

    cols = [10, 15, 20, 25, 30, 35, 40, 45, 50]
    rows = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70]

    blocks = []

    cols.each do |col|
      rows.each do |row|
        blocks << [col, row]
      end
    end

    if user.nil?
      t = Time.now
      srand(t.sec ^ t.usec ^ Process.pid)
      block = blocks[rand(blocks.length)]
      return [block[0]*100, block[1]*100]
    end

    reserved = []
    
    toys = Toy.get_for_user(user)
    
    toys.each do |toy|
      reserved << [toy.x / 100 / 5 * 5, toy.y / 100 / 5 * 5]
    end

    count = Hash.new(0)
    reserved.each { |elem| count[elem] += 1 }

    min_block = nil
    min_count = 0
    blocks.each do |block|
      if min_block == nil
        min_block = block
        min_count = count[block]
      else
        if count[block] < min_count
          min_block = block
          min_count = count[block]
        end
      end
      
    end

    return [min_block[0]*100, min_block[1]*100]
  end

end
