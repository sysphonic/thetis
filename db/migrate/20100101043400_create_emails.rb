class CreateEmails < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      t.integer   :user_id, :null => false
      t.integer   :mail_account_id
      t.integer   :mail_folder_id
      t.string    :from_address
      t.string    :subject
      t.text      :to_addresses
      t.text      :cc_addresses
      t.text      :bcc_addresses
      t.string    :reply_to
      t.text      :message
      t.string    :uid
      t.integer   :priority
      t.datetime  :sent_at
      t.string    :status
      t.string    :xtype

      t.timestamps
    end
  end

  def self.down
    drop_table :emails
  end
end
