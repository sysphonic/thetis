class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :user_id, :integer, :null => false
      t.column :item_id, :integer, :null => false
      t.column :message, :text
      t.column :updated_at, :datetime
      t.column :xtype, :string
      t.column :attachments, :text
    end
  end

  def self.down
    drop_table :comments
  end
end
