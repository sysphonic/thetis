#
#= WorkflowsHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
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
      con = ['parent_id=? and name=?', my_folder.id, MY_WF_ROOT]

      begin
        my_wf_folder = Folder.find(:first, :conditions => con)
      rescue
      end
      if my_wf_folder.nil?
        folder = Folder.new
        folder.name = MY_WF_ROOT
        folder.parent_id = my_folder.id
        folder.owner_id = user_id.to_i
        folder.xtype = Folder::XTYPE_SYSTEM
        folder.read_users = '|' + user_id.to_s + '|'
        folder.write_users = '|' + user_id.to_s + '|'
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
      con = ['parent_id=? and name=?', my_folder.id, Workflow.decided_inbox]

      begin
        decided_inbox = Folder.find(:first, :conditions => con)
      rescue
      end
      if decided_inbox.nil?
        folder = Folder.new
        folder.name = Workflow.decided_inbox
        folder.parent_id = my_folder.id
        folder.owner_id = user_id.to_i
        folder.xtype = nil
        folder.read_users = '|' + user_id.to_s + '|'
        folder.write_users = '|' + user_id.to_s + '|'
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
      con = ['parent_id=? and name=?', my_folder.id, Workflow.decided_inbox]

      begin
        decided_inbox = Folder.find(:first, :conditions => con)
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

    sql = 'select distinct Workflow.* from workflows Workflow, items Item'

    where = " where (Workflow.user_id = #{user_id})"
    where << ' and (Workflow.original_by is null)'
    where << ' and (Workflow.item_id = Item.id)'
    where << " and (Item.folder_id = #{folder_id})"

    order_by = ' order by Workflow.id DESC'

    sql << where + order_by

    return sql
  end
end
