class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table :teams do |t|
      t.column :name, :string
      t.column :item_id, :integer, :null => false, :default => '0'
      t.column :users, :text
      t.column :status, :string
    end
  end

  def self.down
    drop_table :teams
  end
end
