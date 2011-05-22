class ChangesForVer096 < ActiveRecord::Migration
  def self.up
    add_column :attachments, :comment_id, :integer
    rename_column :toys, :parent_id, :posted_by
  end

  def self.down
    remove_column :attachments, :comment_id
    rename_column :toys, :posted_by, :parent_id
  end
end
