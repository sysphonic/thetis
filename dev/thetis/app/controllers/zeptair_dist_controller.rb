#
#= ZeptairDistController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Zeptair Distribution feature.
#
#== Note:
#
#* 
#
class ZeptairDistController < ApplicationController
  layout 'base'

  before_filter :check_login
  before_filter :only => [:users] do |controller|
    controller.check_auth(User::AUTH_ZEPTAIR)
  end


  #=== users
  #
  #Shows list of Users' status of Zeptair Distribution.
  #This method takes input of filter, keywords, sort options
  #and pagination parameters.
  #
  def users
    Log.add_info(request, params.inspect)

    @item = Item.find(params[:item_id])

    con = []

    if params[:keyword]
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        key = "\'%" + key + "%\'"
        con << "(name like #{key} or email like #{key} or fullname like #{key} or address like #{key} or organization like #{key})"
      end
    end

    @group_id = nil
    if !params[:thetisBoxSelKeeper].nil?
      @group_id = params[:thetisBoxSelKeeper].split(':').last
    elsif !params[:group_id].nil? and !params[:group_id].empty?
      @group_id = params[:group_id]
    end
    unless @group_id.nil?
      con << "(groups like '%|#{@group_id}|%')"
    end

    include_comment = false

    filter_status = params[:filter_status]

    unless filter_status.nil? or filter_status.empty?
      case filter_status
        when ZeptairDistHelper::STATUS_REPLIED
          con << "((Comment.item_id=#{@item.id}) and (Comment.xtype='#{Comment::XTYPE_DIST_ACK}') and (Comment.user_id=User.id))"
          include_comment = true
        when ZeptairDistHelper::STATUS_COMPLETE
          ack_msg = ZeptairDistHelper.completed_ack_message(@item.id)
          con << "((Comment.item_id=#{@item.id}) and (Comment.xtype='#{Comment::XTYPE_DIST_ACK}') and (Comment.user_id=User.id) and (Comment.message='#{ack_msg}'))"
          include_comment = true
        when ZeptairDistHelper::STATUS_NO_REPLY
          comments = Comment.find(:all, :conditions => "((Comment.item_id=#{@item.id}) and (Comment.xtype='#{Comment::XTYPE_DIST_ACK}'))")
          except_users = []
          unless comments.nil?
            comments.each do |comment|
              except_users << comment.user_id
            end
          end
          unless except_users.empty?
            con << '(User.id not in (' + except_users.join(',') + '))'
          end
        else
          ;
      end
    end

    order_by = nil
    @sort_col = params[:sort_col]
    @sort_type = params[:sort_type]

    if @sort_col.nil? or @sort_col.empty? or @sort_type.nil? or @sort_type.empty?
      @sort_col = 'id'
      @sort_type = 'ASC'
    end

    fields = ['User.*']
    unless @sort_col.index('Comment.').nil?
      if include_comment
        fields << @sort_col
      else
        sort_alias = @sort_col.downcase.gsub('.', '_')
        fields << "(select distinct #{@sort_col} from comments Comment where (Comment.item_id=#{@item.id}) and (Comment.xtype='#{Comment::XTYPE_DIST_ACK}') and (Comment.user_id=User.id)) as #{sort_alias}"
        order_by = ' order by ' + sort_alias + ' ' + @sort_type
      end
    end

    order_by = " order by #{@sort_col} #{@sort_type}" if order_by.nil?

    where = ''
    unless con.empty?
      where = ' where ' + con.join(' and ')
    end

    sql = "select distinct #{fields.join(',')} from users User"
    if include_comment
      sql << ', comments Comment'
    end
    sql << where + order_by

    @user_pages, @users, @total_num = paginate_by_sql(User, sql, 50)
  end

  #=== reply
  #
  #Receives replies to the distribution from Zeptair Clients.
  #Their status may be 'saved' or 'canceled' for each attachment file.
  #
  def reply
    Log.add_info(request, '')   # Not to show passwords.

    login_user = session[:login_user]

    attach = Attachment.find(params[:attach_id])
    if attach.nil? or attach.item.nil? \
        or attach.item.xtype != Item::XTYPE_ZEPTAIR_DIST
      render(:text => 'ERROR:' + t('msg.system_error'))
      return
    end
    item = attach.item

    comment = ZeptairDistHelper.get_comment_of(item.id, login_user.id)

    case params[:status]
      when 'saved'
        new_entry = "#{attach.id}#{ZeptairDistHelper::ACK_ID_SEP}#{params[:timestamp]}"

        if comment.nil?
          comment = Comment.new
          comment.user_id = login_user.id
          comment.item_id = item.id
          comment.xtype = Comment::XTYPE_DIST_ACK
          comment.message = new_entry + "\n"
          comment.save!
        else

          entries = ZeptairDistHelper.get_ack_array_of(comment)

          unless entries.include?(new_entry)
            msg = ''
            inserted = false

            entries.each do |entry|
              next if entry.nil? or entry.empty?

              entry_attach_id = entry.scan(/^(\d+)[=]/).flatten.first.to_i
              if entry_attach_id == attach.id
                msg << new_entry + "\n"
                inserted = true
              elsif !inserted and attach.id < entry_attach_id
                msg << new_entry + "\n"
                msg << entry + "\n"
                inserted = true
              else
                msg << entry + "\n"
              end
            end
            unless inserted
              msg << new_entry + "\n"
            end
            comment.update_attribute(:message, msg)
          end
        end
      when 'canceled'
        unless comment.nil?
          if comment.message.nil?
            entries = []
          else
            entries = comment.message.split("\n")
          end
          msg = ''
          exp = "^#{attach.id}#{ZeptairDistHelper::ACK_ID_SEP}"

          entries.each do |entry|
            next if entry.nil? or entry.empty?

            if entry.match(exp).nil?
              msg << entry + "\n"
            end
          end

          if msg.empty?
            comment.destroy
          else
            comment.update_attribute(:message, msg)
          end
        end
    end
    render(:text => '')
  end
end
