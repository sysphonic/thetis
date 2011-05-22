class CreatePaidHolidays < ActiveRecord::Migration
  def self.up
    create_table :paid_holidays do |t|
      t.column :user_id,  :integer, :null => false
      t.column :year,     :integer, :limit => 4, :null => false
      t.column :num,      :float
    end
  end

  def self.down
    drop_table :paid_holidays
  end
end
