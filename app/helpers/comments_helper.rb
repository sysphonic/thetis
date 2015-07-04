#
#= CommentsHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about Items.
#
#== Note:
#
#* 
#
module CommentsHelper

  #=== self.get_list_sql
  #
  #Gets SQL for list of latest Comments.
  #
  #_user_:: Target User.
  #return:: SQL to get list.
  #
  def self.get_list_sql(user)

    return nil if user.nil?

    sql = "select distinct Comment.* from comments Comment, (select distinct items.id from items, comments where items.user_id=#{user.id} or (comments.user_id=#{user.id} and comments.item_id=items.id)) as Item"
    sql << " where (Comment.item_id=Item.id) and not (Comment.xtype='#{Comment::XTYPE_DIST_ACK}')"
# ... or if you would like to except Comment::XTYPE_APPLY
#   sql << " where (Comment.item_id=Item.id) and not (Comment.xtype='#{Comment::XTYPE_APPLY}' or Comment.xtype='#{Comment::XTYPE_DIST_ACK}')"

#   sql = 'select distinct Comment.* from comments Comment, items Item'
#   sql << " where (Comment.item_id=Item.id and Item.user_id=#{user.id})"
#
#    team_items = []
#    user.get_teams_a.each do |team_id|
#      begin
#        team = Team.find team_id
#        team_items << team.item_id
#      rescue => evar
#        Log.add_error(nil, evar)
#      end
#    end
#
#    unless team_items.empty?
#      sql << ' or (Comment.item_id in (' + team_items.join(',') + ') and not (Comment.xtype=\''+Comment::XTYPE_APPLY+'\'))'
#    end

    sql << ' order by updated_at DESC limit 0,10'

    return sql
  end
end
