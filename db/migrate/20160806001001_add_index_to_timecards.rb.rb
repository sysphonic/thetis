class AddIndexToTimecards < ActiveRecord::Migration
  def self.up
    change_column(:timecards, :date, :date, :null => false)
    change_column(:timecards, :user_id, :integer, :null => false)
    change_column(:timecards, :workcode, :string, :limit => 30, :null => false)
    change_column(:timecards, :status, :string)

    remove_column(:timecards, :item_id)

    add_index(:timecards, [:date, :user_id], {:unique => true, :name => 'index_1_on_timecards'})
  end

  def self.down
    change_column(:timecards, :date, :date, :null => true)
    change_column(:timecards, :user_id, :integer, :null => true)
    change_column(:timecards, :workcode, :string, :null => true)
    change_column(:timecards, :status, :integer)

    add_column(:timecards, :item_id, :integer)

    remove_index(:timecards, :name => 'index_1_on_timecards')
  end
end
