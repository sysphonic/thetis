class Changes2ForVer110 < ActiveRecord::Migration
  def self.up
    add_column(:users, :email_sub1, :string)
    add_column(:users, :email_sub1_type, :string)
    add_column(:users, :email_sub2, :string)
    add_column(:users, :email_sub2_type, :string)

    add_column(:mail_accounts, :xtype, :string)
    add_column(:mail_folders, :mail_account_id, :integer)
    add_column(:emails, :size, :integer)

    add_column(:settings, :group_id,  :integer, :null => true)
    change_column(:settings, :user_id, :integer, :null => true)
  end

  def self.down
    remove_column(:users, :email_sub1)
    remove_column(:users, :email_sub1_type)
    remove_column(:users, :email_sub2)
    remove_column(:users, :email_sub2_type)

    remove_column(:mail_accounts, :xtype)
    remove_column(:mail_folders, :mail_account_id)
    remove_column(:emails, :size)

    remove_column(:settings, :group_id)
    change_column(:settings, :user_id, :integer, :null => false)
  end
end
