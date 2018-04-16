#
#= ZeptairPostHelper
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
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

    post_item = Item.where("(user_id=#{user.id}) and (xtype='#{Item::XTYPE_ZEPTAIR_POST}')").first

    if post_item.nil? and auto_create
      post_item = Item.new_by_type(Item::XTYPE_ZEPTAIR_POST, user.get_my_folder.id)
      post_item.save!
    end

    return post_item
  end
end
