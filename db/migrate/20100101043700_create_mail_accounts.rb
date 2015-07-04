class CreateMailAccounts < ActiveRecord::Migration
  def self.up
    create_table :mail_accounts do |t|
      t.string  :title
      t.integer :user_id, :null => false
      t.boolean :is_default
      t.string  :smtp_server
      t.integer :smtp_port
      t.string  :smtp_secure_conn
      t.boolean :smtp_auth
      t.string  :smtp_auth_method
      t.string  :smtp_username
      t.string  :smtp_password
      t.string  :pop_server
      t.integer :pop_port
      t.string  :pop_username
      t.string  :pop_password
      t.string  :pop_secure_conn
      t.boolean :pop_secure_auth
      t.string  :from_name
      t.string  :from_address
      t.string  :reply_to
      t.string  :organization
      t.boolean :remove_from_server
      t.text    :uidl
      t.integer :xorder

      t.timestamps
    end
  end

  def self.down
    drop_table :mail_accounts
  end
end
