class CreateToys < ActiveRecord::Migration
  def self.up
    create_table :toys do |t|
      t.column :user_id, :integer
      t.column :name, :string
      t.column :xtype, :string
      t.column :target_id, :integer
      t.column :address, :string
      t.column :x, :integer
      t.column :y, :integer
      t.column :parent_id, :integer
      t.column :memo, :string
      t.column :message, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :accessed_at, :datetime
    end
  end

  def self.down
    drop_table :toys
  end
end
