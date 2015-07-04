class CreateSchedules < ActiveRecord::Migration
  def self.up
    create_table :schedules do |t|
      t.column :title, :string, :default => "", :null => false
      t.column :detail, :text
      t.column :created_by, :integer
      t.column :created_at, :datetime
      t.column :updated_by, :integer
      t.column :updated_at, :datetime
      t.column :users, :text
      t.column :equipment, :text
      t.column :start, :datetime
      t.column :end, :datetime
      t.column :public, :boolean, :null => false, :default => false
      t.column :repeat_start, :datetime
      t.column :repeat_end, :datetime
      t.column :repeat_rule, :text
      t.column :except, :text
      t.column :allday, :boolean
      t.column :items, :text
    end
  end

  def self.down
    drop_table :schedules
  end
end
