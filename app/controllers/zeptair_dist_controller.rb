#
#= ZeptairDistController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class ZeptairDistController < ApplicationController
  layout('base')

  before_action(:check_login)
  before_action :only => [:users] do |controller|
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

    unless params[:keyword].blank?
      key_array = params[:keyword].split(nil)
      key_array.each do |key| 
        con << SqlHelper.get_sql_like([:name, :email, :fullname, :address, :organization], key)
      end
    end

    @group_id = nil
    if !params[:tree_node_id].nil?
      @group_id = params[:tree_node_id]
    elsif !params[:group_id].blank?
      @group_id = params[:group_id]
    end
    SqlHelper.validate_token([@group_id])

    unless @group_id.nil?
      con << SqlHelper.get_sql_like([:groups], "|#{@group_id}|")
    end

    include_comment = false

    filter_status = params[:filter_status]
    SqlHelper.validate_token([filter_status])

    unless filter_status.blank?
      case filter_status
        when ZeptairDistHelper::STATUS_REPLIED
          con << "((Comment.item_id=#{@item.id}) and (Comment.xtype='#{Comment::XTYPE_DIST_ACK}') and (Comment.user_id=User.id))"
          include_comment = true
        when ZeptairDistHelper::STATUS_COMPLETE
          ack_msg = ZeptairDistHelper.completed_ack_message(@item.id)
          con << "((Comment.item_id=#{@item.id}) and (Comment.xtype='#{Comment::XTYPE_DIST_ACK}') and (Comment.user_id=User.id) and (Comment.message='#{ack_msg}'))"
          include_comment = true
        when ZeptairDistHelper::STATUS_NO_REPLY
          comments = Comment.where("((Comment.item_id=#{@item.id}) and (Comment.xtype='#{Comment::XTYPE_DIST_ACK}'))").to_a
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

    if (@sort_col.blank? or @sort_type.blank?)
      @sort_col = 'id'
      @sort_type = 'ASC'
    end
    SqlHelper.validate_token([@sort_col, @sort_type], ['.'])

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

    raise(RequestPostOnlyException) unless request.post?

    unless params[:attach_id].blank?
      target = Attachment.find(params[:attach_id])
    end
    unless params[:cmd_id].blank?
      target = ZeptairCommand.find(params[:cmd_id])
    end
    if (target.nil? or target.item.nil? \
        or (target.item.xtype != Item::XTYPE_ZEPTAIR_DIST))
      render(:plain => 'ERROR:' + t('msg.system_error'))
      return
    end
    
    item = target.item

    comment = ZeptairDistHelper.get_comment_of(item.id, @login_user.id)

    case params[:status]
      when ZeptairDistHelper::ENTRY_STATUS_SAVED, ZeptairDistHelper::ENTRY_STATUS_EXECUTED, ZeptairDistHelper::ENTRY_STATUS_ERROR
        new_entry = "#{target.class}#{ZeptairDistHelper::ACK_CLASS_SEP}#{target.id}#{ZeptairDistHelper::ACK_ID_SEP}#{params[:timestamp]}#{ZeptairDistHelper::ACK_TS_SEP}#{params[:status]}"

        if comment.nil?
          comment = Comment.new
          comment.user_id = @login_user.id
          comment.item_id = item.id
          comment.xtype = Comment::XTYPE_DIST_ACK
          comment.message = new_entry + "\n"
          comment.save!
        else
          class_order = {'Attachment' => 0, 'ZeptairCommand' => 1}
          target_order = class_order[target.class.to_s]

          entries = ZeptairDistHelper.get_ack_array_of(comment)

          unless entries.include?(new_entry)
            msg = ''
            inserted = false

            entries.each do |entry|
              next if (entry.nil? or entry.empty?)

              regexp = Regexp.new("^([a-zA-Z]+)#{ZeptairDistHelper::ACK_CLASS_SEP}(\\d+)[#{ZeptairDistHelper::ACK_ID_SEP}]")
              matched_arr = entry.scan(regexp)
              next if matched_arr.nil?
              matched_arr = matched_arr.flatten
              next if (matched_arr.length < 2)

              entry_class = matched_arr.first
              entry_order = class_order[entry_class]
              entry_id = matched_arr.last.to_i
              if ((entry_class == target.class.to_s) \
                  and (entry_id == target.id))
                msg << new_entry + "\n"
                inserted = true
              elsif !inserted \
                  and \
                    ((entry_class == target.class.to_s and target.id < entry_id) \
                      or (entry_class != target.class.to_s and target_order < entry_order))
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
          exp = "^#{target.class}#{ZeptairDistHelper::ACK_CLASS_SEP}#{target.id}#{ZeptairDistHelper::ACK_ID_SEP}"

          entries.each do |entry|
            next if (entry.nil? or entry.empty?)

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
    render(:plain => '')
  end
end
