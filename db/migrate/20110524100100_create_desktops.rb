class CreateDesktops < ActiveRecord::Migration
  def self.up
    create_table :desktops do |t|
      t.column :user_id, :integer
      t.column :theme, :string
      t.column :background_color, :string
      t.column :popup_news, :boolean
      t.column :popup_timecard, :boolean
      t.column :popup_schedule, :boolean
      t.column :img_enabled, :boolean
      t.column :img_name, :string
      t.column :img_size, :integer
      t.column :img_content_type, :string
      t.column :img_content, :longblob

      t.timestamps
    end
  end

  def self.down
    drop_table :desktops
  end
end
