#
#= WorkflowsHelper
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Provides utility methods and constants about Workflows.
#
#== Note:
#
#* 
#
module WorkflowsHelper

  private::MY_WF_ROOT = '$Workflows'


  #=== self.get_my_wf_folder
  #
  #Gets the Workflows folder in My Folder.
  #If not found, sets up and initializes it.
  #
  #_user_id_:: Target User-ID.
  #return:: $Workflows folder.
  #
  def self.get_my_wf_folder(user_id)

    my_folder = User.get_my_folder(user_id)

    unless my_folder.nil?
      con = "(parent_id=#{my_folder.id}) and (name='#{MY_WF_ROOT}')"

      begin
        my_wf_folder = Folder.where(con).first
      rescue
      end
      if my_wf_folder.nil?
        folder = Folder.new
        folder.name = MY_WF_ROOT
        folder.parent_id = my_folder.id
        folder.owner_id = user_id.to_i
        folder.xtype = Folder::XTYPE_SYSTEM
        folder.read_users = ApplicationHelper.a_to_attr([user_id])
        folder.write_users = ApplicationHelper.a_to_attr([user_id])
        folder.save!

        my_wf_folder = folder
      end
    end

    return my_wf_folder
  end

  #=== self.get_decided_inbox
  #
  #Gets the inbox Folder of decided Workflows in My Folder.
  #If not found, sets up and initializes it.
  #
  #_user_id_:: Target User-ID.
  #return:: Inbox Folder of decided Workflows.
  #
  def self.get_decided_inbox(user_id)

    my_folder = User.get_my_folder(user_id)

    unless my_folder.nil?
      con = "(parent_id=#{my_folder.id}) and (name='#{Workflow.decided_inbox}')"

      begin
        decided_inbox = Folder.where(con).first
      rescue
      end
      if decided_inbox.nil?
        folder = Folder.new
        folder.name = Workflow.decided_inbox
        folder.parent_id = my_folder.id
        folder.owner_id = user_id.to_i
        folder.xtype = nil
        folder.read_users = ApplicationHelper.a_to_attr([user_id])
        folder.write_users = ApplicationHelper.a_to_attr([user_id])
        folder.save!

        decided_inbox = folder
      end
    end

    return decided_inbox
  end

  #=== self.exists_decided_inbox?
  #
  #Checks if the inbox Folder of decided Workflows in My Folder.
  #
  #_user_id_:: Target User-ID.
  #return:: true if Inbox Folder of decided Workflows exists, false otherwise.
  #
  def self.exists_decided_inbox?(user_id)

    my_folder = User.get_my_folder(user_id)

    unless my_folder.nil?
      con = "(parent_id=#{my_folder.id}) and (name='#{Workflow.decided_inbox}')"

      begin
        decided_inbox = Folder.where(con).first
      rescue
      end
    end

    return !decided_inbox.nil?
  end

  #=== self.get_list_sql
  #
  #Gets SQL for list of Workflows.
  #
  #_user_id_:: Owner's User-ID.
  #_folder_id_:: Folder-ID.
  #return:: SQL for list of Workflows.
  #
  def self.get_list_sql(user_id, folder_id)

    SqlHelper.validate_token([user_id, folder_id])

    sql = 'select distinct Workflow.* from workflows Workflow, items Item'

    where = " where (Workflow.user_id = #{user_id})"
    where << ' and (Workflow.original_by is null)'
    where << ' and (Workflow.item_id = Item.id)'
    where << " and (Item.folder_id = #{folder_id})"

    order_by = ' order by Workflow.id DESC'

    sql << where + order_by

    return sql
  end

  #=== self.get_tmpl_list_sql
  #
  #Gets SQL for templates list of Workflows.
  #
  #_folder_id_:: Folder-ID of templates of Workflows.
  #_group_ids_:: Array of target Group-IDs.
  #return:: SQL for templates list of Workflows.
  #
  def self.get_tmpl_list_sql(folder_id, group_ids=nil)

    SqlHelper.validate_token([folder_id, group_ids])

    sql = 'select distinct Workflow.* from workflows Workflow, items Item'

    where = " where (Item.folder_id = #{folder_id})"
    where << ' and (Workflow.item_id = Item.id)'

    unless group_ids.blank?
      scope_con = []
      [group_ids].flatten.each do |group_id|
        if group_id.to_s == '0'
          scope_con << "(Workflow.groups is null)"
        else
          scope_con << SqlHelper.get_sql_like(['Workflow.groups'], "|#{group_id}|")
        end
      end
      unless scope_con.empty?
        where << " and (#{scope_con.join(' or ')})"
      end
    end

    order_by = ' order by Item.xorder ASC'

    sql << where + order_by

    return sql
  end
end
