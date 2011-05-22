class CreateMailAttachments < ActiveRecord::Migration
  def self.up
    create_table :mail_attachments do |t|
      t.integer :email_id
      t.string  :name
      t.integer :size
      t.string  :content_type
      t.integer :xorder

      t.timestamps
    end
  end

  def self.down
    drop_table :mail_attachments
  end
end
