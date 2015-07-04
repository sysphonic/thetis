class CreateMailFolders < ActiveRecord::Migration
  def self.up
    create_table :mail_folders do |t|
      t.string    :name, :null => false
      t.integer   :parent_id
      t.integer   :user_id
      t.string    :xtype
      t.integer   :xorder

      t.timestamps
    end
  end

  def self.down
    drop_table :mail_folders
  end
end
