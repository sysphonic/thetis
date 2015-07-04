class CreateMailFilters < ActiveRecord::Migration
  def self.up
    create_table :mail_filters do |t|
      t.string  :title
      t.integer :mail_account_id, :null => false
      t.boolean :enabled
      t.string  :triggers
      t.string  :and_or
      t.text    :conditions
      t.text    :actions
      t.integer :xorder

      t.timestamps
    end
  end

  def self.down
    drop_table :mail_filters
  end
end
