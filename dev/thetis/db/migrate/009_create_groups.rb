class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.column :name, :string
      t.column :parent_id, :integer, :null => false, :default => '0'
      t.column :auth, :text
      t.column :xorder, :integer
    end
  end

  def self.down
    drop_table :groups
  end
end
