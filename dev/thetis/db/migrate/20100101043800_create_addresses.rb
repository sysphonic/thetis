class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.integer :owner_id
      t.string  :name
      t.string  :name_ruby
      t.string  :nickname
      t.string  :screenname
      t.string  :email1
      t.string  :email2
      t.string  :email3
      t.string  :postalcode
      t.text    :address
      t.string  :tel1
      t.string  :tel1_note
      t.string  :tel2
      t.string  :tel2_note
      t.string  :tel3
      t.string  :tel3_note
      t.string  :fax
      t.string  :url
      t.text    :organization
      t.string  :title
      t.text    :memo
      t.integer :xorder

      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
