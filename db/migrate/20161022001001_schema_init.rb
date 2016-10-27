class SchemaInit < ActiveRecord::Migration
 def self.up

  force = :cascade

  # Below is modified output of the following command:
  # $ rake db:schema:dump RAILS_ENV=production THETIS_DATABASE_PASSWORD=

  create_table "addresses", force: force do |t|
    t.integer  "owner_id"
    t.string   "name"
    t.string   "name_ruby"
    t.string   "nickname"
    t.string   "screenname"
    t.string   "email1"
    t.string   "email2"
    t.string   "email3"
    t.string   "postalcode"
    t.text     "address",      limit: 65535
    t.string   "tel1"
    t.string   "tel1_note"
    t.string   "tel2"
    t.string   "tel2_note"
    t.string   "tel3"
    t.string   "tel3_note"
    t.string   "fax"
    t.string   "url"
    t.text     "organization", limit: 65535
    t.string   "title"
    t.text     "memo",         limit: 65535
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "groups",       limit: 65535
    t.text     "teams",        limit: 65535
  end

  create_table "attachments", force: force do |t|
    t.string   "title"
    t.text     "memo",         limit: 65535
    t.string   "name"
    t.integer  "size"
    t.string   "content_type"
    t.binary   "content",      limit: 4294967295
    t.integer  "item_id"
    t.integer  "xorder"
    t.string   "location"
    t.integer  "comment_id"
    t.string   "digest_md5"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: force do |t|
    t.integer  "user_id",                  null: false
    t.integer  "item_id",                  null: false
    t.text     "message",    limit: 65535
    t.datetime "updated_at"
    t.string   "xtype"
  end

  create_table "desktops", force: force do |t|
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
    t.binary   "img_content",      limit: 4294967295
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emails", force: force do |t|
    t.integer  "user_id",                       null: false
    t.integer  "mail_account_id"
    t.integer  "mail_folder_id"
    t.string   "from_address"
    t.string   "subject"
    t.text     "to_addresses",    limit: 65535
    t.text     "cc_addresses",    limit: 65535
    t.text     "bcc_addresses",   limit: 65535
    t.string   "reply_to"
    t.text     "message",         limit: 65535
    t.string   "uid"
    t.integer  "priority"
    t.datetime "sent_at"
    t.string   "status"
    t.string   "xtype"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "size"
  end

  create_table "equipment", force: force do |t|
    t.string "name",                 default: "", null: false
    t.text   "note",   limit: 65535
    t.text   "users",  limit: 65535
    t.text   "groups", limit: 65535
    t.text   "teams",  limit: 65535
  end

  create_table "folders", force: force do |t|
    t.string   "name"
    t.integer  "parent_id",                  default: 0, null: false
    t.integer  "owner_id",                   default: 0, null: false
    t.integer  "xorder"
    t.text     "read_users",   limit: 65535
    t.text     "write_users",  limit: 65535
    t.text     "read_groups",  limit: 65535
    t.text     "write_groups", limit: 65535
    t.text     "read_teams",   limit: 65535
    t.text     "write_teams",  limit: 65535
    t.text     "disp_ctrl",    limit: 65535
    t.string   "xtype"
    t.datetime "created_at"
  end

  create_table "groups", force: force do |t|
    t.string  "name"
    t.integer "parent_id",               default: 0, null: false
    t.text    "auth",      limit: 65535
    t.integer "xorder"
    t.string  "xtype"
  end

  create_table "images", force: force do |t|
    t.string   "title"
    t.text     "memo",         limit: 65535
    t.string   "name"
    t.integer  "size"
    t.string   "content_type"
    t.binary   "content",      limit: 4294967295
    t.integer  "item_id"
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", force: force do |t|
    t.string   "title",                        default: "",    null: false
    t.string   "summary"
    t.integer  "folder_id"
    t.text     "description",    limit: 65535
    t.datetime "updated_at"
    t.boolean  "public",                       default: false, null: false
    t.integer  "user_id",                                      null: false
    t.string   "layout"
    t.text     "update_message", limit: 65535
    t.string   "xtype"
    t.integer  "xorder"
    t.datetime "created_at"
    t.integer  "original_by"
    t.integer  "source_id"
  end

  create_table "locations", force: force do |t|
    t.integer  "user_id",    null: false
    t.integer  "group_id"
    t.integer  "x"
    t.integer  "y"
    t.string   "memo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logs", force: force do |t|
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "remote_ip"
    t.string   "log_type"
    t.string   "access_path"
    t.text     "detail",      limit: 65535
  end

  create_table "mail_accounts", force: force do |t|
    t.string   "title"
    t.integer  "user_id",                          null: false
    t.boolean  "is_default"
    t.string   "smtp_server"
    t.integer  "smtp_port"
    t.string   "smtp_secure_conn"
    t.boolean  "smtp_auth"
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
    t.text     "uidl",               limit: 65535
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "xtype"
  end

  create_table "mail_attachments", force: force do |t|
    t.integer  "email_id"
    t.string   "name"
    t.integer  "size"
    t.string   "content_type"
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mail_filters", force: force do |t|
    t.string   "title"
    t.integer  "mail_account_id",               null: false
    t.boolean  "enabled"
    t.string   "triggers"
    t.string   "and_or"
    t.text     "conditions",      limit: 65535
    t.text     "actions",         limit: 65535
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mail_folders", force: force do |t|
    t.string   "name",            null: false
    t.integer  "parent_id"
    t.integer  "user_id"
    t.string   "xtype"
    t.integer  "xorder"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mail_account_id"
  end

  create_table "office_maps", force: force do |t|
    t.integer  "group_id",                            null: false
    t.boolean  "img_enabled"
    t.string   "img_name"
    t.integer  "img_size"
    t.string   "img_content_type"
    t.binary   "img_content",      limit: 4294967295
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "official_titles", force: force do |t|
    t.string   "name",                      null: false
    t.integer  "group_id"
    t.integer  "xorder",     default: 9999
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "paid_holidays", force: force do |t|
    t.integer "user_id",            null: false
    t.integer "year",               null: false
    t.float   "num",     limit: 24
  end

  create_table "paintmails", force: force do |t|
    t.integer "user_id"
    t.string  "smtpSenderAddress"
    t.string  "smtpServerAddress"
    t.integer "smtpServerPort"
    t.string  "popServerAddress"
    t.integer "popServerPort"
    t.string  "popUser"
    t.string  "popPassword"
    t.string  "popInterval"
    t.text    "toAddresses",       limit: 65535
    t.text    "confDir",           limit: 65535
    t.boolean "checkNew"
    t.boolean "smtpAuth"
    t.string  "smtpUser"
    t.string  "smtpPassword"
  end

  create_table "researches", force: force do |t|
    t.integer "user_id", null: false
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

  create_table "schedules", force: force do |t|
    t.string   "title",                      default: "",  null: false
    t.text     "detail",       limit: 65535
    t.integer  "created_by"
    t.datetime "created_at"
    t.integer  "updated_by"
    t.datetime "updated_at"
    t.text     "users",        limit: 65535
    t.text     "equipment",    limit: 65535
    t.datetime "start"
    t.datetime "end"
    t.string   "scope",                      default: "0", null: false
    t.date     "repeat_start"
    t.date     "repeat_end"
    t.text     "repeat_rule",  limit: 65535
    t.text     "except",       limit: 65535
    t.boolean  "allday"
    t.text     "items",        limit: 65535
    t.string   "xtype"
    t.text     "groups",       limit: 65535
    t.text     "teams",        limit: 65535
  end

  create_table "settings", force: force do |t|
    t.integer  "user_id"
    t.string   "category"
    t.string   "xkey"
    t.string   "xvalue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
  end

  create_table "teams", force: force do |t|
    t.string   "name"
    t.integer  "item_id",                     default: 0, null: false
    t.text     "users",         limit: 65535
    t.string   "status"
    t.datetime "req_to_del_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timecards", force: force do |t|
    t.date     "date",                     null: false
    t.integer  "user_id",                  null: false
    t.string   "workcode",   limit: 30,    null: false
    t.datetime "start"
    t.datetime "end"
    t.text     "breaks",     limit: 65535
    t.text     "comment",    limit: 65535
    t.datetime "updated_at"
    t.string   "status"
    t.string   "options"
    t.index ["date", "user_id"], name: "index_1_on_timecards", unique: true, using: :btree
  end

  create_table "toys", force: force do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "xtype"
    t.integer  "target_id"
    t.string   "address"
    t.integer  "x"
    t.integer  "y"
    t.integer  "posted_by"
    t.string   "memo"
    t.text     "message",     limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "accessed_at"
  end

  create_table "user_titles", force: force do |t|
    t.integer  "user_id"
    t.integer  "official_title_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: force do |t|
    t.string   "name"
    t.string   "password"
    t.string   "fullname"
    t.text     "address",         limit: 65535
    t.text     "organization",    limit: 65535
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
    t.text     "groups",          limit: 65535
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "login_at"
    t.string   "title"
    t.string   "pass_md5"
    t.date     "birthday"
    t.integer  "xorder",                        default: 9999
    t.string   "zeptair_id"
    t.string   "time_zone"
    t.string   "figure"
    t.string   "email_sub1"
    t.string   "email_sub1_type"
    t.string   "email_sub2"
    t.string   "email_sub2_type"
  end

  create_table "workflows", force: force do |t|
    t.integer  "item_id"
    t.integer  "user_id"
    t.text     "users",       limit: 65535
    t.string   "status"
    t.datetime "issued_at"
    t.integer  "original_by"
    t.datetime "decided_at"
    t.text     "groups",      limit: 65535
  end

  create_table "zeptair_commands", force: force do |t|
    t.integer  "item_id",                                    null: false
    t.text     "commands",     limit: 65535
    t.boolean  "enabled",                    default: false, null: false
    t.boolean  "confirm_exec",               default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "zeptair_xlogs", force: force do |t|
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
    t.float    "cs_comp_ratio", limit: 24
    t.float    "sc_comp_ratio", limit: 24
    t.string   "cs_protocol"
    t.string   "cs_operation"
    t.string   "cs_uri"
    t.string   "sc_status"
    t.string   "c_agent"
    t.datetime "req_at",                   null: false
    t.datetime "fin_at",                   null: false
  end

 end

 def self.down
  drop_table "addresses"
  drop_table "attachments"
  drop_table "comments"
  drop_table "desktops"
  drop_table "emails"
  drop_table "equipment"
  drop_table "folders"
  drop_table "groups"
  drop_table "images"
  drop_table "items"
  drop_table "locations"
  drop_table "logs"
  drop_table "mail_accounts"
  drop_table "mail_attachments"
  drop_table "mail_filters"
  drop_table "mail_folders"
  drop_table "office_maps"
  drop_table "official_titles"
  drop_table "paid_holidays"
  drop_table "paintmails"
  drop_table "researches"
  drop_table "schedules"
  drop_table "settings"
  drop_table "teams"
  drop_table "timecards"
  drop_table "toys"
  drop_table "user_titles"
  drop_table "users"
  drop_table "workflows"
  drop_table "zeptair_commands"
  drop_table "zeptair_xlogs"
 end
end
