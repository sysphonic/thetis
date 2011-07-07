class CreateZeptairCommands < ActiveRecord::Migration
  def self.up
    create_table :zeptair_commands do |t|
      t.column :item_id,  :integer, :null => false
      t.column :commands, :text
      t.column :enabled,  :boolean, :null => false, :default => false
      t.column :confirm_exec, :boolean, :null => false, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :zeptair_commands
  end
end
