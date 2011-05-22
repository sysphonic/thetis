class ChangesForVer093 < ActiveRecord::Migration
  def self.up
    rename_column :schedules, :public, :scope
    change_column :schedules, :scope, :string, :null => false
    add_column :schedules, :xtype, :string
    add_column :paintmails, :smtpAuth, :boolean
    add_column :paintmails, :smtpUser, :string
    add_column :paintmails, :smtpPassword, :string
  end

  def self.down
    rename_column :schedules, :scope, :public
    change_column :schedules, :public, :boolean, :null => false, :default => false
    remove_column :schedules, :xtype
    remove_column :paintmails, :smtpAuth
    remove_column :paintmails, :smtpUser
    remove_column :paintmails, :smtpPassword
  end
end
