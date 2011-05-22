class CreateFolders < ActiveRecord::Migration
  def self.up
    create_table :folders do |t|
      t.column :name, :string
      t.column :parent_id, :integer, :null => false, :default => 0
      t.column :user_id, :integer, :null => false, :default => 0
      t.column :xorder, :integer
      t.column :read_users, :text
      t.column :write_users, :text
      t.column :read_groups, :text
      t.column :write_groups, :text
      t.column :read_teams, :text
      t.column :write_teams, :text
      t.column :disp_ctrl, :text
    end
  end

  def self.down
    drop_table :folders
  end
end
