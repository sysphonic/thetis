class CreateOfficialTitles < ActiveRecord::Migration
  def self.up
    create_table :official_titles do |t|
      t.column :name,           :string, :null => false
      t.column :group_id,       :integer
      t.column :xorder,         :integer, :default => 9999

      t.timestamps
    end
  end

  def self.down
    drop_table :official_titles
  end
end
