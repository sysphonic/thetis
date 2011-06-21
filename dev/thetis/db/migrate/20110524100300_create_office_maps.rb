class CreateOfficeMaps < ActiveRecord::Migration
  def self.up
    create_table :office_maps do |t|
      t.column :group_id, :integer, :null => false
      t.column :img_enabled, :boolean
      t.column :img_name, :string
      t.column :img_size, :integer
      t.column :img_content_type, :string
      t.column :img_content, :longblob
      t.column :img_width, :integer
      t.column :img_height, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :office_maps
  end
end
