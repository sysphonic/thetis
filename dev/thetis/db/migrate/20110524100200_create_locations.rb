class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.column :user_id, :integer, :null => false
      t.column :group_id, :integer
      t.column :x, :integer
      t.column :y, :integer
      t.column :memo, :string

      t.timestamps
    end
  end

  def self.down
    drop_table :locations
  end
end
