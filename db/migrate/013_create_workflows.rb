class CreateWorkflows < ActiveRecord::Migration
  def self.up
    create_table :workflows do |t|
      t.column :item_id, :integer
      t.column :user_id, :integer
      t.column :users, :text
      t.column :status, :string
      t.column :issued_at, :datetime
    end
  end

  def self.down
    drop_table :workflows
  end
end
