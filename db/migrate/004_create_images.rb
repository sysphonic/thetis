class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.column :title, :string
      t.column :memo, :text
      t.column :name, :string
      t.column :size, :integer
      t.column :content_type, :string
      t.column :content, :longblob
      t.column :item_id, :integer
      t.column :xorder, :integer
    end
  end

  def self.down
    drop_table :images
  end
end
