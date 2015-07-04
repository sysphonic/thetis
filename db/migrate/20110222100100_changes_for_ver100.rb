class ChangesForVer100 < ActiveRecord::Migration
  def self.up
    add_column :users, :zeptair_id, :string
    add_column :users, :time_zone,  :string

    add_column :attachments, :digest_md5, :string
    change_table :attachments do |t|
      t.timestamps
    end

    change_table :images do |t|
      t.timestamps
    end

    change_column :schedules, :repeat_start, :date
    change_column :schedules, :repeat_end, :date

    remove_column :comments, :attachments

    add_column :schedules, :groups, :text
    add_column :schedules, :teams,  :text
  end

  def self.down
    remove_column :users, :zeptair_id
    remove_column :users, :time_zone

    remove_column :attachments, :digest_md5
    remove_column :attachments, :created_at
    remove_column :attachments, :updated_at

    remove_column :images, :created_at
    remove_column :images, :updated_at

    change_column :schedules, :repeat_start, :datetime
    change_column :schedules, :repeat_end, :datetime

    add_column :comments, :attachments, :text

    remove_column :schedules, :groups
    remove_column :schedules, :teams
  end
end
