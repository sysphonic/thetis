# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110524100100) do

  create_table "addresses", :force => true do |t|
    t.integer  "owner_id"
    t.string   "name"
    t.string   "name_ruby"
    t.string   "nickname"
    t.string   "screenname"
    t.string   "email1"
    t.string   "email2"
    t.string   "email3"
    t.string   "postalcode"
    t.text     "address"
    t.string   "tel1"
    t.string   "tel1_note"
    t.string   "tel2"
    t.string   "tel2_note"
    t.string   "tel3"
    t.string   "tel3_note"
    t.string   "fax"
    t.string   "url"
    t.text     "organization"
    t.string   "title"
    t.text     "memo"
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "groups"
    t.text     "teams"
  end

  create_table "attachments", :force => true do |t|
    t.string   "title"
    t.text     "memo"
    t.string   "name"
    t.integer  "size"
    t.string   "content_type"
    t.binary   "content",      :limit => 2147483647
    t.integer  "item_id"
    t.integer  "xorder"
    t.string   "location"
    t.integer  "comment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "digest_md5"
  end

  create_table "comments", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "item_id",    :null => false
    t.text     "message"
    t.datetime "updated_at"
    t.string   "xtype"
  end

  create_table "desktops", :force => true do |t|
    t.integer  "user_id"
    t.string   "theme"
    t.string   "background_color"
    t.boolean  "popup_news"
    t.boolean  "popup_timecard"
    t.boolean  "popup_schedule"
    t.boolean  "img_enabled"
    t.string   "img_name"
    t.integer  "img_size"
    t.string   "img_content_type"
    t.binary   "img_content",      :limit => 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emails", :force => true do |t|
    t.integer  "user_id",         :null => false
    t.integer  "mail_account_id"
    t.integer  "mail_folder_id"
    t.string   "from_address"
    t.string   "subject"
    t.text     "to_addresses"
    t.text     "cc_addresses"
    t.text     "bcc_addresses"
    t.string   "uid"
    t.integer  "priority"
    t.datetime "sent_at"
    t.string   "status"
    t.string   "xtype"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "message"
    t.string   "reply_to"
  end

  create_table "equipment", :force => true do |t|
    t.string "name",   :default => "", :null => false
    t.text   "note"
    t.text   "users"
    t.text   "groups"
    t.text   "teams"
  end

  create_table "folders", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id",    :default => 0, :null => false
    t.integer  "owner_id"
    t.integer  "xorder"
    t.text     "read_users"
    t.text     "write_users"
    t.text     "read_groups"
    t.text     "write_groups"
    t.text     "read_teams"
    t.text     "write_teams"
    t.text     "disp_ctrl"
    t.string   "xtype"
    t.datetime "created_at"
  end

  create_table "groups", :force => true do |t|
    t.string  "name"
    t.integer "parent_id", :default => 0, :null => false
    t.text    "auth"
    t.integer "xorder"
  end

  create_table "images", :force => true do |t|
    t.string   "title"
    t.text     "memo"
    t.string   "name"
    t.integer  "size"
    t.string   "content_type"
    t.binary   "content",      :limit => 2147483647
    t.integer  "item_id"
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", :force => true do |t|
    t.string   "title",          :default => "",    :null => false
    t.string   "summary"
    t.integer  "folder_id"
    t.text     "description"
    t.datetime "updated_at"
    t.boolean  "public",         :default => false, :null => false
    t.integer  "user_id",                           :null => false
    t.string   "layout"
    t.text     "update_message"
    t.string   "xtype"
    t.integer  "xorder"
    t.datetime "created_at"
    t.integer  "original_by"
    t.integer  "source_id"
  end

  create_table "logs", :force => true do |t|
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "remote_ip"
    t.string   "log_type"
    t.string   "access_path"
    t.text     "detail"
  end

  create_table "mail_accounts", :force => true do |t|
    t.string   "title"
    t.integer  "user_id",            :null => false
    t.boolean  "is_default"
    t.string   "smtp_server"
    t.integer  "smtp_port"
    t.string   "smtp_secure_conn"
    t.string   "smtp_auth_method"
    t.string   "smtp_username"
    t.string   "smtp_password"
    t.string   "pop_server"
    t.integer  "pop_port"
    t.string   "pop_username"
    t.string   "pop_password"
    t.string   "pop_secure_conn"
    t.boolean  "pop_secure_auth"
    t.string   "from_name"
    t.string   "from_address"
    t.string   "reply_to"
    t.string   "organization"
    t.boolean  "remove_from_server"
    t.text     "uidl"
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "smtp_auth"
  end

  create_table "mail_attachments", :force => true do |t|
    t.integer  "email_id"
    t.string   "name"
    t.integer  "size"
    t.string   "content_type"
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mail_folders", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "parent_id"
    t.integer  "user_id"
    t.string   "xtype"
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "paid_holidays", :force => true do |t|
    t.integer "user_id", :null => false
    t.integer "year",    :null => false
    t.float   "num"
  end

  create_table "paintmails", :force => true do |t|
    t.integer "user_id"
    t.string  "smtpSenderAddress"
    t.string  "smtpServerAddress"
    t.integer "smtpServerPort"
    t.string  "popServerAddress"
    t.integer "popServerPort"
    t.string  "popUser"
    t.string  "popPassword"
    t.string  "popInterval"
    t.text    "toAddresses"
    t.text    "confDir"
    t.boolean "checkNew"
    t.boolean "smtpAuth"
    t.string  "smtpUser"
    t.string  "smtpPassword"
  end

  create_table "researches", :force => true do |t|
    t.integer "user_id", :null => false
    t.integer "status"
    t.string  "q01_01"
    t.string  "q01_02"
    t.string  "q01_03"
    t.string  "q01_04"
    t.string  "q01_05"
    t.string  "q01_06"
    t.string  "q01_07"
    t.string  "q01_08"
    t.string  "q01_09"
    t.string  "q01_10"
    t.string  "q01_11"
    t.string  "q01_12"
    t.string  "q01_13"
    t.string  "q01_14"
    t.string  "q01_15"
    t.string  "q01_16"
    t.string  "q01_17"
    t.string  "q01_18"
    t.string  "q01_19"
    t.string  "q01_20"
    t.string  "q02_01"
    t.string  "q02_02"
    t.string  "q02_03"
    t.string  "q02_04"
    t.string  "q02_05"
    t.string  "q02_06"
    t.string  "q02_07"
    t.string  "q02_08"
    t.string  "q02_09"
    t.string  "q02_10"
    t.string  "q02_11"
    t.string  "q02_12"
    t.string  "q02_13"
    t.string  "q02_14"
    t.string  "q02_15"
    t.string  "q02_16"
    t.string  "q02_17"
    t.string  "q02_18"
    t.string  "q02_19"
    t.string  "q02_20"
    t.string  "q03_01"
    t.string  "q03_02"
    t.string  "q03_03"
    t.string  "q03_04"
    t.string  "q03_05"
    t.string  "q03_06"
    t.string  "q03_07"
    t.string  "q03_08"
    t.string  "q03_09"
    t.string  "q03_10"
    t.string  "q03_11"
    t.string  "q03_12"
    t.string  "q03_13"
    t.string  "q03_14"
    t.string  "q03_15"
    t.string  "q03_16"
    t.string  "q03_17"
    t.string  "q03_18"
    t.string  "q03_19"
    t.string  "q03_20"
  end

  create_table "schedules", :force => true do |t|
    t.string   "title",        :default => "", :null => false
    t.text     "detail"
    t.integer  "created_by"
    t.datetime "created_at"
    t.integer  "updated_by"
    t.datetime "updated_at"
    t.text     "users"
    t.text     "equipment"
    t.datetime "start"
    t.datetime "end"
    t.string   "scope",                        :null => false
    t.date     "repeat_start"
    t.date     "repeat_end"
    t.text     "repeat_rule"
    t.text     "except"
    t.boolean  "allday"
    t.text     "items"
    t.string   "xtype"
    t.text     "groups"
    t.text     "teams"
  end

  create_table "settings", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "category"
    t.string   "xkey"
    t.string   "xvalue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teams", :force => true do |t|
    t.string   "name"
    t.integer  "item_id",       :default => 0, :null => false
    t.text     "users"
    t.string   "status"
    t.datetime "req_to_del_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timecards", :force => true do |t|
    t.date     "date"
    t.integer  "user_id"
    t.integer  "item_id"
    t.string   "workcode"
    t.datetime "start"
    t.datetime "end"
    t.text     "breaks"
    t.text     "comment"
    t.datetime "updated_at"
    t.integer  "status"
    t.string   "options"
  end

  create_table "toys", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "xtype"
    t.integer  "target_id"
    t.string   "address"
    t.integer  "x"
    t.integer  "y"
    t.integer  "posted_by"
    t.string   "memo"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "accessed_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "password"
    t.string   "fullname"
    t.text     "address"
    t.text     "organization"
    t.string   "email"
    t.string   "tel1"
    t.string   "tel1_note"
    t.string   "tel2"
    t.string   "tel2_note"
    t.string   "tel3"
    t.string   "tel3_note"
    t.string   "fax"
    t.string   "url"
    t.string   "postalcode"
    t.string   "auth"
    t.text     "groups"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "login_at"
    t.string   "title"
    t.string   "pass_md5"
    t.date     "birthday"
    t.integer  "xorder",       :default => 9999
    t.string   "zeptair_id"
    t.string   "time_zone"
  end

  create_table "workflows", :force => true do |t|
    t.integer  "item_id"
    t.integer  "user_id"
    t.text     "users"
    t.string   "status"
    t.datetime "issued_at"
    t.integer  "original_by"
    t.datetime "decided_at"
    t.text     "groups"
  end

  create_table "zeptair_xlogs", :force => true do |t|
    t.integer  "user_id"
    t.string   "zeptair_id"
    t.integer  "descriptor"
    t.string   "c_addr"
    t.integer  "c_port"
    t.string   "s_addr"
    t.integer  "s_port"
    t.integer  "time_taken"
    t.integer  "cs_bytes"
    t.integer  "sc_bytes"
    t.integer  "cs_org_bytes"
    t.integer  "sc_org_bytes"
    t.float    "cs_comp_ratio"
    t.float    "sc_comp_ratio"
    t.string   "cs_protocol"
    t.string   "cs_operation"
    t.string   "cs_uri"
    t.string   "sc_status"
    t.string   "c_agent"
    t.datetime "req_at",        :null => false
    t.datetime "fin_at",        :null => false
  end

end
