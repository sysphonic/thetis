class ChangesForVer092 < ActiveRecord::Migration
  def self.up
    add_column :users, :birthday, :datetime
    add_column :users, :xorder, :integer, :default => 9999
    add_column :folders, :xtype, :string
    rename_column :folders, :user_id, :owner_id
    add_column :items, :created_at, :datetime
    add_column :folders, :created_at, :datetime
  end

  def self.down
    remove_column :users, :birthday
    remove_column :users, :xorder
    remove_column :folders, :xtype
    rename_column :folders, :owner_id, :user_id
    remove_column :items, :created_at
    remove_column :folders, :created_at
  end
end
