#
#= MailFolder
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#== Note:
#
#* 
#
class MailFolder < ActiveRecord::Base
  has_many(:emails, :dependent => :destroy)

  extend CachedRecord
  include TreeElement

  public::XTYPE_INBOX = 'inbox'
  public::XTYPE_SENT = 'sent'
  public::XTYPE_DRAFTS = 'drafts'
  public::XTYPE_TRASH = 'trash'
  public::XTYPE_ACCOUNT_ROOT = 'account_root'

  #=== get_icons
  #
  #Get icons by types of the MailFolder.
  #
  #return:: Array of the path of icons ([normal, open, close]).
  #
  def get_icons
    return MailFolder.get_icons(self.xtype)
  end

  #=== self.get_icons
  #
  #Get icons related with the specified xtype.
  #
  #_xtype_:: Target xtype.
  #return:: Array of the path of icons ([normal, open, close]).
  #
  def self.get_icons(xtype)

    img_root = THETIS_RELATIVE_URL_ROOT + '/images/'

    case xtype
      when MailFolder::XTYPE_INBOX
        normal = img_root + 'mail/mail_folder.gif'
        open = img_root + 'mail/tree_mail_open.gif'
        close = img_root + 'mail/tree_mail_close.gif'
      when MailFolder::XTYPE_SENT
        normal = img_root + 'mail/mail_folder.gif'
        open = img_root + 'mail/tree_mail_open.gif'
        close = img_root + 'mail/tree_mail_close.gif'
      when MailFolder::XTYPE_DRAFTS
        normal = img_root + 'mail/mail_folder.gif'
        open = img_root + 'mail/tree_mail_open.gif'
        close = img_root + 'mail/tree_mail_close.gif'
      when MailFolder::XTYPE_TRASH
        normal = img_root + 'mail/trash_open.png'
        open = img_root + 'mail/trash_open.png'
        close = img_root + 'mail/trash_close.png'
      when MailFolder::XTYPE_ACCOUNT_ROOT
        normal = img_root + 'mail/account_open.gif'
        open = img_root + 'mail/account_open.gif'
        close = img_root + 'mail/account_close.gif'
      else
        normal = img_root + 'mail/mail_folder.gif'
        open = img_root + 'mail/tree_mail_open.gif'
        close = img_root + 'mail/tree_mail_close.gif'
    end
    return [normal, open, close]
  end

  #=== self.sort_tree
  #
  #Sorts MailFolder tree.
  #
  #_folder_tree_:: MailFolder tree.
  #return:: MailFolder tree.
  #
  def self.sort_tree(folder_tree)

    return folder_tree if folder_tree.nil? or folder_tree.empty?

    folder_tree['0'].sort! { |folder_a, folder_b|

      if folder_a.xtype == folder_b.xtype
          idx_a = folder_a.name.to_i
          idx_b = folder_b.name.to_i
      else
        case folder_a.xtype
          when MailFolder::XTYPE_INBOX;       idx_a = 1;
          when MailFolder::XTYPE_DRAFTS;      idx_a = 2;
          when MailFolder::XTYPE_SENT;        idx_a = 3;
          when MailFolder::XTYPE_TRASH;       idx_a = 4;
          else; idx_a = 6;
        end
        case folder_b.xtype
          when MailFolder::XTYPE_INBOX;       idx_b = 1;
          when MailFolder::XTYPE_DRAFTS;      idx_b = 2;
          when MailFolder::XTYPE_SENT;        idx_b = 3;
          when MailFolder::XTYPE_TRASH;       idx_b = 4;
          else; idx_b = 6;
        end
      end

      idx_a - idx_b
    }

    return folder_tree
  end

  #=== self.get_condtions_for
  #
  #Gets conditions parameter for specified User.
  #
  #_user_:: Target User.
  #_mail_account_ids_:: Array of the target MailAccount-IDs.
  #return:: Conditions.
  #
  def self.get_condtions_for(user, mail_account_ids)

    if mail_account_ids.nil? or mail_account_ids.empty?
      con = ["user_id=? and (mail_account_id is null)"]
    else
      con = ["user_id=? and (mail_account_id is null or mail_account_id in (#{mail_account_ids.join(',')}))"]
    end
    con << user.id

    return con
  end

  #=== self.get_for
  #
  #Gets MailFolder for specified User and type.
  #
  #_user_:: Target User.
  #_mail_account_id_:: Target MailAccount-ID.
  #_xtype_:: Target type.
  #return:: MailFolder.
  #
  def self.get_for(user, mail_account_id, xtype)

    return nil if user.nil? or mail_account_id.blank?

    if user.kind_of?(User)
      user_id = user.id
    else
      user_id = user.to_s
    end

    con = []
    con << "(user_id=#{user_id})"
    con << "(mail_account_id=#{mail_account_id})"
    con << "(xtype='#{xtype}')"

    return MailFolder.find(:first, :conditions => con.join(' and '))
  end

  #=== self.get_account_roots_for
  #
  #Gets MailFolders of account root for specified User.
  #
  #_user_:: Target User.
  #return:: MailFolders of account root.
  #
  def self.get_account_roots_for(user)

    return nil if user.nil?

    if user.kind_of?(User)
      user_id = user.id
    else
      user_id = user.to_s
    end

    con = []
    con << "(user_id=#{user_id})"
    con << "(xtype='#{MailFolder::XTYPE_ACCOUNT_ROOT}')"

    order_by = 'xorder ASC, id ASC'

    return MailFolder.find(:all, :conditions => con.join(' and '), :order => order_by)
  end

  #=== self.get_tree_for
  #
  #Gets MailFolder tree for specified User.
  #
  #_user_:: Target User.
  #_mail_account_ids_:: Array of the target MailAccount-IDs.
  #return:: MailFolder tree.
  #
  def self.get_tree_for(user, mail_account_ids)

    con = MailFolder.get_condtions_for(user, mail_account_ids)

    # '0' for ROOT
    folder_tree = MailFolder.get_tree(Hash.new, con, '0')
    return MailFolder.sort_tree(folder_tree)
  end

  #=== self.get_tree
  #
  #Gets MailFolder tree.
  #Called recursive.
  #
  #_folder_tree_:: MailFolder tree.
  #_conditions_:: Conditions.
  #_tree_id_:: Tree-ID.
  #return:: MailFolder tree.
  #
  def self.get_tree(folder_tree, conditions, tree_id)

    return TreeElement.get_tree(self, folder_tree, conditions, tree_id, 'xorder ASC, id ASC')
  end

  #=== self.get_childs
  #
  #Gets childs array of the specified MailFolder.
  #
  #_mail_folder_id_:: Target MailFolder-ID.
  #_recursive_:: Specify true if recursive search is required.
  #_ret_obj_:: Flag to require MailFolder instances by return.
  #return:: Array of child MailFolder-IDs, or MailFolders if ret_obj is true.
  #
  def self.get_childs(mail_folder_id, recursive, ret_obj)

    TreeElement.get_childs(self, mail_folder_id, recursive, ret_obj)
  end

  #=== self.delete_tree
  #
  #Deletes nodes in the MailFolder tree.
  #Called recursive.
  #
  #_folder_tree_:: MailFolder tree.
  #_parent_id_:: Parent MailFolder-ID.
  #_delete_ary_:: Array of Folders to remove.
  #return:: MailFolder tree.
  #
  def self.delete_tree(folder_tree, parent_id, delete_ary)

    return folder_tree if delete_ary.nil? or delete_ary.empty?

    delete_ary.each do |folder|
      folder_tree = MailFolder.delete_tree(folder_tree, folder.id, folder_tree[folder.id.to_s])
      folder_tree.delete folder.id.to_s
    end

    folder_tree[parent_id.to_s] -= delete_ary

    return folder_tree
  end

  #=== self.get_name
  #
  #Gets the name of the specified MailFolder.
  #
  #_mail_folder_id_:: MailFolder-ID.
  #return:: MailFolder name. If not found, prearranged string.
  #
  def self.get_name(mail_folder_id)

    return '(root)' if mail_folder_id.to_s == '0'

    begin
      folder = MailFolder.find(mail_folder_id)
    rescue => evar
      Log.add_error(nil, evar)
    end
    if folder.nil?
      return mail_folder_id.to_s + ' '+ I18n.t('paren.deleted')
    else
      return folder.name
    end
  end

  #=== self.get_path
  #
  #Gets path-string which represents location of specified MailFolder.
  #
  #_mail_folder_id_:: MailFolder-ID.
  #_folders_cache_:: Hash to accelerate response. {mail_folder.id, path}
  #_folder_obj_cache_:: Hash to accelerate response. {mail_folder.id, mail_folder}
  #return:: MailFolder path like "/parent_name1/parent_name2/this_name".
  #
  def self.get_path(mail_folder_id, folders_cache=nil, folder_obj_cache=nil)

    unless folders_cache.nil?
      path = folders_cache[mail_folder_id.to_i]
      if path.nil?
        id_ary = []
        name_ary = []
      else
        return path
      end
    end

    if mail_folder_id.to_s == '0'  # '0' for ROOT
      path = '/(root)'
      folders_cache[mail_folder_id.to_i] = path unless folders_cache.nil?
      return path
    end

    path = ''
    cached_path = nil

    while mail_folder_id.to_s != '0'  # '0' for ROOT

      unless folders_cache.nil?
        cached_path = folders_cache[mail_folder_id.to_i]
        unless cached_path.nil?
          path = cached_path + path
          break
        end
      end

      folder = MailFolder.find_with_cache(mail_folder_id, folder_obj_cache)

      id_ary.unshift(mail_folder_id.to_i) unless folders_cache.nil?

      if folder.nil?
        path = '/' + I18n.t('paren.deleted') + path
        name_ary.unshift(I18n.t('paren.deleted')) unless folders_cache.nil?
        break
      else
        folder_name = folder.name
        if (folder_name.nil? or folder_name.empty?) \
            and (folder.xtype == MailFolder::XTYPE_ACCOUNT_ROOT)
          folder_name = MailAccount.get_title(folder.mail_account_id)
        end
        path = '/' + folder_name + path
        name_ary.unshift(folder_name) unless folders_cache.nil?
      end

      mail_folder_id = folder.parent_id
    end

    unless folders_cache.nil?
      path_to_cache = ''
      unless cached_path.nil?
        path_to_cache << cached_path
      end
      id_ary.each_with_index do |f_id, idx|
        path_to_cache << '/' + name_ary[idx]

        folders_cache[f_id] = path_to_cache.dup
      end
    end

    return path
  end


  #=== get_path
  #
  #Gets path-string which represents location of this folder.
  #
  #_folders_cache_:: Hash to accelerate response. {mail_folder.id, path}
  #_folder_obj_cache_:: Hash to accelerate response. {mail_folder.id, mail_folder}
  #return:: MailFolder path like "/parent_name1/parent_name2/this_name".
  #
  def get_path(folders_cache=nil, folder_obj_cache=nil)

    return MailFolder.get_path(self.id, folders_cache, folder_obj_cache)
  end


  #=== self.get_mails
  #
  #Gets Mails in specified MailFolder.
  #Implemented as a class-method because of considering about root MailFolder
  #which has no record in DB.
  #
  #_mail_folder_id_:: Target MailFolder-ID.
  #_user_:: Owner of Emails.
  #_add_con_:: Additional condition to query by.
  #_order_by_:: Order. ex. 'xorder ASC'
  #return:: Mails in the MailFolder.
  #
  def self.get_mails(mail_folder_id, user, add_con=nil, order_by=nil)

    order_by = 'sent_at desc' if order_by.nil? or order_by.empty?

    if user.instance_of?(User)
      user_id = user.id
    else
      user_id = user.to_s
    end

    sql = 'select emails.* from emails'
    sql << " where mail_folder_id=#{mail_folder_id} and user_id=#{user_id}"
    sql << " and (#{add_con})" unless add_con.nil? or add_con.empty?
    sql << " order by #{order_by}"

    return Email.find_by_sql(sql)
  end

  #=== self.get_mails_to_show
  #
  #Gets Mails in specified MailFolder, without those of temporary.
  #
  #_mail_folder_id_:: Target MailFolder-ID.
  #_user_:: Owner of Emails.
  #return:: Mails in the MailFolder, without those of temporary.
  #
  def self.get_mails_to_show(mail_folder_id, user)

    return MailFolder.get_mails(mail_folder_id, user, "(status is null) or not(status='#{Email::STATUS_TEMPORARY}')")
  end

  #=== count_mails
  #
  #Counts Mails in this MailFolder as Administrator and returns the value.
  #
  #_recursive_:: Specify true if recursive search is required.
  #return:: Count of Items.
  #
  def count_mails(recursive)

    count = Email.count_by_sql("SELECT COUNT(*) FROM emails WHERE mail_folder_id=#{self.id}")

    childs = MailFolder.get_childs(self.id, recursive, false)
    childs.each do |child_id|
      count = count + Email.count_by_sql("SELECT COUNT(*) FROM emails WHERE mail_folder_id=#{child_id}")
    end

    return count
  end

  #=== force_destroy
  #
  #Destroys with all sub MailFolders and their Mails.
  #
  def force_destroy

    childs = MailFolder.get_childs(self.id, true, true)
    childs.each do |folder|

      begin
        folder.destroy
      rescue => evar
        Log.add_error(nil, evar)
      end

      mails = Email.find(:all, :conditions => ['mail_folder_id=?', folder.id])
      mails.each do |mail|
        mail.destroy
      end
    end

    mails = Email.find(:all, :conditions => ['mail_folder_id=?', self.id])
    mails.each do |mail|
      mail.destroy
    end
    self.destroy
  end

  #=== self.exists?
  #
  #Gets if the specified MailFolder exists.
  #
  #_mail_folder_id_:: Target Folder_ID.
  #return::True if it exists. false otherwise.
  #
  def self.exists?(mail_folder_id)

    return false if mail_folder_id.nil?

    return true if mail_folder_id.to_s == '0'

    folder = nil
    begin
      folder = MailFolder.find(mail_folder_id)
    rescue
    end

    return (!folder.nil?)
  end

  #=== exists?
  #
  #Gets if the MailFolder exists.
  #
  #return::True if it exists. false otherwise.
  #
  def exists?
    return MailFolder.exists?(self.id)
  end
end
