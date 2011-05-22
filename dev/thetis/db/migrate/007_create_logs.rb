class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.column :updated_at, :datetime
      t.column :user_id, :integer
      t.column :remote_ip, :string
      t.column :log_type, :string
      t.column :access_path, :string
      t.column :detail, :text
    end
  end

  def self.down
    drop_table :logs
  end
end
