class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.column :user_id,  :integer, :null => false
      t.column :category, :string
      t.column :xkey,     :string
      t.column :xvalue,   :string

      t.timestamps
    end
  end

  def self.down
    drop_table :settings
  end
end
