#
#= TemplatesHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about templates of Items.
#
#== Note:
#
#* 
#
module TemplatesHelper

  public::TMPL_ROOT = '$Templates'

  public::TMPL_SYSTEM = 'System'
  public::TMPL_WORKFLOWS = 'Workflows'
  public::TMPL_LOCAL = 'Local'
  public::TMPL_RESEARCH = 'Research'

  #=== self.setup_tmpl_folder
  #
  #Sets up and initializes template folders.
  #
  #return:: Array of Folders. [$Templates, System, Workflows, Local, Research].
  #
  def self.setup_tmpl_folder

    begin
      tmpl_folder = Folder.find(:first, :conditions => ["folders.name = ?", TMPL_ROOT])
    rescue
    end
    if tmpl_folder.nil?
      # Setup initial template-folders
      folder = Folder.new
      folder.name = TMPL_ROOT
      folder.parent_id = 0
      folder.owner_id = 0
      folder.xtype = Folder::XTYPE_SYSTEM
      folder.save!
      tmpl_folder = folder
    end

    begin
      con = ["folders.parent_id = ?"]
      con << tmpl_folder.id
      childs = Folder.find(:all, :conditions => con)
    rescue
    end

    # System
    tmpl_system_folder = childs.find{|child| child.name == TMPL_SYSTEM}
    if tmpl_system_folder.nil?
      folder = Folder.new
      folder.name = TMPL_SYSTEM
      folder.parent_id = tmpl_folder.id
      folder.owner_id = 0
      folder.xtype = Folder::XTYPE_SYSTEM
      folder.save!
      tmpl_system_folder = folder

      # System - Profile Sheet
      item = Item.new_profile(tmpl_system_folder.id)
      item.title = Item.profile_title_def
      item.user_id = 0
      item.save!
    end

    # Workflow
    tmpl_workflows_folder = childs.find{|child| child.name == TMPL_WORKFLOWS}
    if tmpl_workflows_folder.nil?
      folder = Folder.new
      folder.name = TMPL_WORKFLOWS
      folder.parent_id = tmpl_folder.id
      folder.owner_id = 0
      folder.xtype = Folder::XTYPE_SYSTEM
      folder.save!
      tmpl_workflows_folder = folder
    end

    # Local
    tmpl_local_folder = childs.find{|child| child.name == TMPL_LOCAL}
    if tmpl_local_folder.nil?
      folder = Folder.new
      folder.name = TMPL_LOCAL
      folder.parent_id = tmpl_folder.id
      folder.owner_id = 0
      folder.xtype = Folder::XTYPE_SYSTEM
      folder.save!
      tmpl_local_folder = folder
    end

    # Research
    tmpl_q_folder = childs.find{|child| child.name == TMPL_RESEARCH}
    if tmpl_q_folder.nil?
      folder = Folder.new
      folder.name = TMPL_RESEARCH
      folder.parent_id = tmpl_folder.id
      folder.owner_id = 0
      folder.xtype = Folder::XTYPE_SYSTEM
      folder.save!
      tmpl_q_folder = folder
    end

    return [tmpl_folder, tmpl_system_folder, tmpl_workflows_folder, tmpl_local_folder, tmpl_q_folder]

  rescue StandardError => err
    Log.add_error(nil, err)
    return nil
  end

  #=== self.get_tmpl_folder
  #
  #Gets the templates Folder.
  #If not found, sets up and initializes it.
  #
  #return:: Array of Folders. [$Templates, System, Workflows, Local, Research].
  #
  def self.get_tmpl_folder

    begin
      con = ["folders.name = ?", TMPL_ROOT]
      tmpl_folder = Folder.find(:first, :conditions => con)
    rescue
    end

    if tmpl_folder.nil?

      ary = self.setup_tmpl_folder

      unless ary.nil? or ary.empty?
        tmpl_folder = ary[0]
        tmpl_system_folder = ary[1]
        tmpl_workflows_folder = ary[2]
        tmpl_local_folder = ary[3]
        tmpl_q_folder = ary[4]
      end

    else

      con = ['parent_id=?', tmpl_folder.id]
      folders = Folder.find(:all, :conditions => con)
      unless folders.nil?
        folders.each do |child|
          case child.name
            when TMPL_SYSTEM
              tmpl_system_folder = child
            when TMPL_WORKFLOWS
              tmpl_workflows_folder = child
            when TMPL_LOCAL
              tmpl_local_folder = child
            when TMPL_RESEARCH
              tmpl_q_folder = child
          end
        end
      end
    end

    return [tmpl_folder, tmpl_system_folder, tmpl_workflows_folder, tmpl_local_folder, tmpl_q_folder]

  rescue StandardError => err
    Log.add_error(nil, err)
    return nil
  end

  #=== self.get_tmpl_subfolder
  #
  #Destroys specified Workflow.
  #
  #_name_:: Sub Folder name.
  #return:: Array of Folders. [$Templates, specified sub Folder].
  #
  def self.get_tmpl_subfolder(name)

    begin
      condition = ["folders.name = ?", TMPL_ROOT]
      tmpl_folder = Folder.find(:first, :conditions => condition)
    rescue StandardError => err
      Log.add_error(nil, err)
    end

    unless tmpl_folder.nil?
      condition = ['parent_id=? and name=?', tmpl_folder.id, name]
      begin
        child = Folder.find(:first, :conditions => condition)
      rescue StandardError => err
        Log.add_error(nil, err)
      end
    end

    return [tmpl_folder, child]
  end

end
