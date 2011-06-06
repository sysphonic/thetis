class ChangesForVer110 < ActiveRecord::Migration
  def self.up
    add_column :items, :source_id, :integer

    add_column :addresses, :groups, :text
    add_column :addresses, :teams, :text

    add_column :workflows, :groups, :text
  end

  def self.down
    remove_column :items, :source_id

    remove_column :addresses, :groups
    remove_column :addresses, :teams

    remove_column :workflows, :groups
  end
end
