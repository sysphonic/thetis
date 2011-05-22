class CreateEquipment < ActiveRecord::Migration
  def self.up
    create_table :equipment do |t|
      t.column :name, :string, :default => "", :null => false
      t.column :note, :text
      t.column :users, :text
      t.column :groups, :text
      t.column :teams, :text
    end
  end

  def self.down
    drop_table :equipment
  end
end
