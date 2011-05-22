#
#= ZeptairPostHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about Zeptair Distribution feature.
#
#== Note:
#
#* 
#
module ZeptairPostHelper

  #=== self.get_item_for
  #
  #Gets Web feeds of specified User.
  #
  #_user_:: The target User.
  #_auto_create_:: Flag to create if not exists.
  #return:: An Item instance to post Attachments into.
  #
  def self.get_item_for(user, auto_create=true)

    return nil unless user.allowed_zept_connect?

    post_item = Item.find(:first, :conditions => ['user_id=? and xtype=?', user.id, Item::XTYPE_ZEPTAIR_POST])

    if post_item.nil? and auto_create
      post_item = Item.new_by_type(Item::XTYPE_ZEPTAIR_POST, user.get_my_folder.id)
      post_item.save!
    end

    return post_item
  end
end
