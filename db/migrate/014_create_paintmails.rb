class CreatePaintmails < ActiveRecord::Migration
  def self.up
    create_table :paintmails do |t|
      t.column :user_id, :integer
      t.column :smtpSenderAddress, :string
      t.column :smtpServerAddress, :string
      t.column :smtpServerPort, :integer
      t.column :popServerAddress, :string
      t.column :popServerPort, :integer
      t.column :popUser, :string
      t.column :popPassword, :string
      t.column :popInterval, :string
      t.column :toAddresses, :text
      t.column :confDir, :text
      t.column :checkNew, :boolean
    end
  end

  def self.down
    drop_table :paintmails
  end
end
