class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items, :force => true do |t|
      t.column :title, :string, :default => "", :null => false
      t.column :summary, :string
      t.column :folder_id, :integer
      t.column :description, :text
      t.column :updated_at, :datetime
      t.column :public, :boolean, :null => false, :default => false
      t.column :user_id, :integer, :null => false
      t.column :layout, :string
      t.column :update_message, :text
      t.column :xtype, :string
      t.column :xorder, :integer
    end
  end

  def self.down
    drop_table :items
  end
end
