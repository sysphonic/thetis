class CreateUserTitles < ActiveRecord::Migration
  def self.up
    create_table :user_titles do |t|
      t.column :user_id,                :integer
      t.column :official_title_id,      :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :user_titles
  end
end
