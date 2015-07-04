class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :name, :string
      t.column :password, :string
      t.column :fullname, :string
      t.column :address, :text
      t.column :organization, :text
      t.column :email, :string
      t.column :tel1, :string
      t.column :tel1_note, :string
      t.column :tel2, :string
      t.column :tel2_note, :string
      t.column :tel3, :string
      t.column :tel3_note, :string
      t.column :fax, :string
      t.column :url, :string
      t.column :postalcode, :string
      t.column :auth, :string
      t.column :groups, :text
      t.column :item_id, :integer
      t.column :created_at, :datetime
      t.column :login_at, :datetime
      t.column :title, :string
      t.column :pass_md5, :string
    end
  end

  def self.down
    drop_table :users
  end
end
