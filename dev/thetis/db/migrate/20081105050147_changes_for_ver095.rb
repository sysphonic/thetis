class ChangesForVer095 < ActiveRecord::Migration
  def self.up
    add_column :attachments, :location, :string
    add_column :items, :original_by, :integer
    add_column :workflows, :original_by, :integer
    add_column :workflows, :decided_at, :datetime
  end

  def self.down
    remove_column :attachments, :location
    remove_column :items, :original_by
    remove_column :workflows, :original_by
    remove_column :workflows, :decided_at
  end
end
