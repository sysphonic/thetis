class ChangesForVer110 < ActiveRecord::Migration
  def self.up
    add_column :items, :source_id, :integer
  end

  def self.down
    remove_column :items, :source_id
  end
end
