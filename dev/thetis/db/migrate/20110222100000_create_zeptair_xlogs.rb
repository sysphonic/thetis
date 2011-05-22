class CreateZeptairXlogs < ActiveRecord::Migration
  def self.up
    create_table :zeptair_xlogs do |t|
      t.integer :user_id
      t.string  :zeptair_id
      t.integer :descriptor
      t.string  :c_addr
      t.integer :c_port
      t.string  :s_addr
      t.integer :s_port
      t.integer :time_taken
      t.integer :cs_bytes
      t.integer :sc_bytes
      t.integer :cs_org_bytes
      t.integer :sc_org_bytes
      t.float   :cs_comp_ratio
      t.float   :sc_comp_ratio
      t.string  :cs_protocol
      t.string  :cs_operation
      t.string  :cs_uri
      t.string  :sc_status
      t.string  :c_agent
      t.datetime :req_at, :null => false
      t.datetime :fin_at, :null => false
    end
  end

  def self.down
    drop_table :zeptair_xlogs
  end
end
