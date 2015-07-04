class CreateTimecards < ActiveRecord::Migration
  def self.up
    create_table :timecards do |t|
      t.column :date,         :date
      t.column :user_id,      :integer
      t.column :item_id,      :integer
      t.column :workcode,     :string
      t.column :start,        :datetime
      t.column :end,          :datetime
      t.column :breaks,       :text
      t.column :comment,      :text
      t.column :updated_at,   :datetime
      t.column :status,       :integer
      t.column :options,      :string
    end
  end

  def self.down
    drop_table :timecards
  end
end
