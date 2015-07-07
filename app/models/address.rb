#
#= Address
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#== Note:
#
#* 
#
class Address < ActiveRecord::Base
  public::PERMIT_BASE = [:name, :name_ruby, :nickname, :screenname, :email1, :email2, :email3, :postalcode, :address, :tel1, :tel1_note, :tel2, :tel2_note, :tel3, :tel3_note, :fax, :url, :organization, :title, :memo]

  require 'csv'

  validates_presence_of(:name)

  public::BOOK_PRIVATE = 'book_private'
  public::BOOK_COMMON = 'book_common'
  public::BOOK_BOTH = 'book_both'

  public::EXP_IMP_FOR_ALL = 'all'


  #=== self.get_by_email
  #
  #Get an Array of Addresses with specified email.
  #
  #_mail_addr_:: Target E-mail address.
  #_user_:: Target User.
  #_book_:: Book type.
  #return:: Array of Addresses.
  #
  def self.get_by_email(mail_addr, user, book=Address::BOOK_BOTH)

    SqlHelper.validate_token([mail_addr])

    email_con = []
    email_con.push("(email1='#{mail_addr}')")
    email_con.push("(email2='#{mail_addr}')")
    email_con.push("(email3='#{mail_addr}')")
    con = []
    con.push('('+email_con.join(' or ')+')')
    con.push(AddressbookHelper.get_scope_condition_for(user, book))

    return Address.where(con.join(' and ')).to_a
  end

  #=== self.csv_header_cols
  #
  #Gets an Array of CSV header columns.
  #
  #_book_:: Book type.
  #return:: Array of CSV header columns.
  #
  def self.csv_header_cols(book)
    ary = []
    ary << I18n.t('activerecord.attributes.id')
    ary << Address.human_attribute_name('name')
    ary << Address.human_attribute_name('name_ruby')
    ary << Address.human_attribute_name('nickname')
    ary << Address.human_attribute_name('screenname')
    ary << Address.human_attribute_name('email1')
    ary << Address.human_attribute_name('email2')
    ary << Address.human_attribute_name('email3')
    ary << Address.human_attribute_name('postalcode')
    ary << Address.human_attribute_name('address')
    ary << Address.human_attribute_name('tel1_note')
    ary << Address.human_attribute_name('tel1')
    ary << Address.human_attribute_name('tel2_note')
    ary << Address.human_attribute_name('tel2')
    ary << Address.human_attribute_name('tel3_note')
    ary << Address.human_attribute_name('tel3')
    ary << Address.human_attribute_name('fax')
    ary << Address.human_attribute_name('url')
    ary << Address.human_attribute_name('organization')
    ary << Address.human_attribute_name('title')
    ary << Address.human_attribute_name('memo')
    ary << Address.human_attribute_name('xorder')
    if book == Address::BOOK_COMMON or book == Address::BOOK_BOTH
      ary << I18n.t('schedule.scope') + I18n.t('cap.suffix') + User.human_attribute_name('groups')
      ary << I18n.t('schedule.scope') + I18n.t('cap.suffix') + I18n.t('team.plural')
    end
    return ary
  end

  #=== self.export_csv
  #
  #Gets CSV description of all Addresses.
  #
  #_user_:: Subjective User.
  #_book_:: Book type.
  #return:: CSV String.
  #
  def self.export_csv(user, book)

    return nil if user.nil? or book.nil?

    book = Address::BOOK_PRIVATE unless user.admin?(User::AUTH_ADDRESSBOOK)

    con_or = []
    if book == Address::BOOK_PRIVATE or book == Address::BOOK_BOTH
      con_or << "owner_id=#{user.id}"
    end
    if book == Address::BOOK_COMMON or book == Address::BOOK_BOTH
      con_or << "owner_id=0"
    end

    addresses = Address.where(con_or.join(' or ')).order('id ASC').to_a

    csv_line = ''

    if book == Address::BOOK_COMMON or book == Address::BOOK_BOTH
      csv_line << I18n.t('address.export.rem1') + "\n"
      csv_line << I18n.t('address.export.rem2') + "\n"
      csv_line << I18n.t('address.export.rem3') + "\n"
      csv_line << "\n"

      csv_line << I18n.t('address.export.rem_groups') + "\n"
      groups = Group.where(nil).to_a
      unless groups.nil?
        groups_cache = {}
        group_obj_cache = Group.build_cache(groups)
        groups.each do |group|
          csv_line << '#   ' + group.id.to_s + ' = ' + Group.get_path(group.id, groups_cache, group_obj_cache) + "\n"
        end
      end
      csv_line << "\n"
    end

    opt = {
      :force_quotes => true,
      :encoding => 'UTF-8'
    }

    csv_line << CSV.generate(opt) do |csv|

      # Header
      ary = Address.csv_header_cols(book)

      csv << ary

      # Addresses
      addresses.each do |address|
        ary = []
        ary << address.id
        ary << address.name
        ary << address.name_ruby
        ary << address.nickname
        ary << address.screenname
        ary << address.email1
        ary << address.email2
        ary << address.email3
        ary << address.postalcode
        ary << address.address
        ary << address.tel1_note
        ary << address.tel1
        ary << address.tel2_note
        ary << address.tel2
        ary << address.tel3_note
        ary << address.tel3
        ary << address.fax
        ary << address.url
        ary << address.organization
        ary << address.title
        ary << address.memo
        ary << address.xorder
        if book == Address::BOOK_COMMON or book == Address::BOOK_BOTH
          if address.for_all?
            ary << Address::EXP_IMP_FOR_ALL
          else
            ary << address.groups
          end
          ary << address.teams
        end

        csv << ary
      end
    end

    return csv_line
  end

  #=== self.check_csv_header
  #
  #Parses fields array of a CSV header.
  #
  #_row_:: Fields array of a CSV header.
  #_book_:: Book type.
  #return:: Array of error header names.
  #
  def self.check_csv_header(row, book)

    return (row - Address.csv_header_cols(book))
  end

  #=== self.parse_csv_row
  #
  #Parses fields array of a CSV row.
  #
  #_row_:: Fields array of a CSV row.
  #_book_:: Book type.
  #_idxs_:: Array of header column indexes.
  #_user_:: Subjective User.
  #return:: Address instance created from specified array.
  #
  def self.parse_csv_row(row, book, idxs, user)

    imp_id = (idxs[0].nil? or row[idxs[0]].nil?)?(nil):(row[idxs[0]].strip)
    unless imp_id.nil? or imp_id.empty?
      org_address = Address.find_by_id(imp_id)
    end

    if org_address.nil?
      address = Address.new
    else
      address = org_address
    end

    address.id = imp_id
    attr_names = [
      :name,
      :name_ruby,
      :nickname,
      :screenname,
      :email1,
      :email2,
      :email3,
      :postalcode,
      :address,
      :tel1_note,
      :tel1,
      :tel2_note,
      :tel2,
      :tel3_note,
      :tel3,
      :fax,
      :url,
      :organization,
      :title,
      :memo,
      :xorder,
      :groups,
      :teams
    ]
    attr_names.each_with_index do |attr_name, idx|
      row_idx = idxs[idx+1]
      break if row_idx.nil?

      val = (row[row_idx].nil?)?(nil):(row[row_idx].strip)
      address.send(attr_name.to_s + '=', val)
    end
    if (address.groups == Address::EXP_IMP_FOR_ALL) \
        or (book == Address::BOOK_COMMON and address.groups.blank? and address.teams.blank?)
      address.groups = nil
      address.teams = nil
      address.owner_id = 0
    elsif !address.groups.blank? or !address.teams.blank?
      address.owner_id = 0
    else
      address.owner_id = user.id
    end

    return address
  end

  #=== check_import
  #
  #Checks data to import.
  #
  #_mode_:: Mode ('add' or 'update').
  #_address_names_:: Array of Address names to check duplicated data.
  #return:: Array of error messages. If no error, returns [].
  #
  def check_import(mode, address_names)    #, address_emails

    err_msgs = []

    # Existing Addresss
    unless self.id.nil? or self.id == 0 or self.id == ''
      if mode == 'add'
        err_msgs << I18n.t('address.import.dont_specify_id')
      else
        begin
          org_address = Address.find(self.id)
        rescue
        end
        if org_address.nil?
          err_msgs << I18n.t('address.import.not_found')
        end
      end
    end

    # Requierd
    if self.name.nil? or self.name.empty?
      err_msgs <<  Address.human_attribute_name('name') + I18n.t('msg.is_required')
    end

    # Groups
    unless self.groups.nil? or self.groups.empty?

      if (/^|([0-9]+|)+$/ =~ self.groups) == 0

        self.get_groups_a.each do |group_id|
          group = Group.find_by_id(group_id)
          if group.nil?
            err_msgs << I18n.t('address.import.not_valid_groups') + ': '+group_id.to_s
            break
          end
        end
      else
        err_msgs << I18n.t('address.import.invalid_groups_format')
      end
    end

    # Teams
    unless self.teams.nil? or self.teams.empty?

      if (/^|([0-9]+|)+$/ =~ self.teams) == 0

        self.get_teams_a.each do |team_id|
          team = Team.find_by_id(team_id)
          if team.nil?
            err_msgs << I18n.t('address.import.not_valid_teams') + ': '+team_id.to_s
            break
          end
        end

      else
        err_msgs << I18n.t('address.import.invalid_teams_format')
      end
    end

    return err_msgs
  end

  #=== get_emails
  #
  #Gets array of E-mail Addresses.
  #
  #return:: Array of E-mail Addresses.
  #
  def get_emails
    emails = [self.email1, self.email2, self.email3]
    emails.compact!
    emails.delete('')
    return emails
  end

  #=== private?
  #
  #Gets if this Address is private.
  #
  #return:: true if this Address is private, false otherwise.
  #
  def private?
    return (self.owner_id != 0)
  end

  #=== for_all?
  #
  #Gets if this Address is for all Users.
  #
  #return:: true if this Address is for all Users, false otherwise.
  #
  def for_all?
    return (self.owner_id == 0 and self.get_groups_a.empty? and self.get_teams_a.empty?)
  end

  #=== get_groups_a
  #
  #Gets Groups array which this Address belongs to.
  #
  #return:: Groups array without empty element. If no Groups, returns empty array.
  #
  def get_groups_a

    return [] if self.groups.nil? or self.groups.empty?

    array = self.groups.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== get_teams_a
  #
  #Gets Teams array which this Address belongs to.
  #
  #return:: Teams array without empty element. If no Teams, returns empty array.
  #
  def get_teams_a

    return [] if self.teams.nil? or self.teams.empty?

    array = self.teams.split('|')
    array.compact!
    array.delete('')

    return array
  end

  #=== self.get_for
  #
  #Gets Addresses available for specified User.
  #
  #_user_:: Target User.
  #_book_:: Target book.
  #return:: Array of Addresses.
  #
  def self.get_for(user, book=Address::BOOK_BOTH)

    return [] if (user.nil? and book == Address::BOOK_PRIVATE)

    con = AddressbookHelper.get_scope_condition_for(user, book)

    return Address.where(con).to_a
  end

  #=== visible?
  #
  #Gets if the specified Address is visible for the specified User.
  #
  #_user_:: Target User.
  #return:: true if the specified Address is visible, false otherwise.
  #
  def visible?(user)

    return true if self.for_all?

    return false if user.nil?

    return true if (user.admin?(User::AUTH_ADDRESSBOOK) or self.owner_id == user.id)

    groups = self.get_groups_a
    teams = self.get_teams_a

    user.get_groups_a(true).each do |group_id|
      return true if groups.include?(group_id)
    end

    user.get_teams_a.each do |team_id|
      return true if teams.include?(team_id)
    end

    return false
  end

  #=== editable?
  #
  #Gets if the specified Address is editable by the specified User.
  #
  #_user_:: Target User.
  #return:: true if the specified Address is editable, false otherwise.
  #
  def editable?(user)

    return false if user.nil?

    return (user.admin?(User::AUTH_ADDRESSBOOK) or self.owner_id == user.id)
  end
end
