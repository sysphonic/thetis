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

  require 'csv'

  validates_presence_of :name

  #=== self.destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  #_id_:: Target User-ID.
  #
  def self.destroy(id)

    id.is_a?(Array) ? id.each { |id| destroy(id) } : find(id).destroy
  end

  #=== destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  def destroy()

    super()
  end

  #=== self.delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  #_id_:: Target Address-ID.
  #
  def self.delete(id)

    Address.destroy(id)
  end

  #=== delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  def delete()

    Address.destroy(self.id)
  end

  #=== self.destroy_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.destroy_all(conditions = nil)

    raise 'Use Address.destroy() instead of Address.destroy_all()!'
  end

  #=== self.delete_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.delete_all(conditions = nil)

    raise 'Use Address.destroy() instead of Address.delete_all()!'
  end

  #=== self.find_all
  #
  #Finds all Addresses in order to display with specified condition.
  #
  #_con_:: Condition (String without 'where '). If not required, specify nil.
  #return:: Array of Addresses.
  #
  def self.find_all(con = nil)

    where = ''

    unless con.nil? or con.empty?
      where = 'where ' + con
    end

    Address.find_by_sql('select * from addresses ' + where + ' order by xorder ASC, name ASC')
  end

  #=== self.export_csv
  #
  #Gets CSV description of all Users.
  #
  def self.export_csv(owner_id)

    addresses = Address.find(:all, :conditions => ['owner_id=?', owner_id], :order => 'id ASC')

    csv_line = ''

    opt = {
      :force_quotes => true,
      :encoding => 'UTF-8'
    }

    csv_line << CSV.generate(opt) do |csv|

      # Header
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

        csv << ary
      end
    end

    return csv_line
  end

  #=== self.parse_csv_row
  #
  #Parses fields array of a CSV row.
  #
  #_row_:: Fields array of a CSV row.
  #return:: Address instance created from specified array.
  #
  def self.parse_csv_row(row)

    imp_id = (row[0].nil?)?nil:(row[0].strip)
    unless imp_id.nil? or imp_id.empty?
      begin
        org_address = Address.find(imp_id)
      rescue
      end
    end

    if org_address.nil?
      address = Address.new
    else
      address = org_address
    end

    address.id =           imp_id
    address.name =         (row[1].nil?)?nil:(row[1].strip)
    address.name_ruby =    (row[2].nil?)?nil:(row[2].strip)
    address.nickname =     (row[3].nil?)?nil:(row[3].strip)
    address.screenname =   (row[4].nil?)?nil:(row[4].strip)
    address.email1 =       (row[5].nil?)?nil:(row[5].strip)
    address.email2 =       (row[6].nil?)?nil:(row[6].strip)
    address.email3 =       (row[7].nil?)?nil:(row[7].strip)
    address.postalcode =   (row[8].nil?)?nil:(row[8].strip)
    address.address =      (row[9].nil?)?nil:(row[9].strip)
    address.tel1_note =    (row[10].nil?)?nil:(row[10].strip)
    address.tel1 =         (row[11].nil?)?nil:(row[11].strip)
    address.tel2_note =    (row[12].nil?)?nil:(row[12].strip)
    address.tel2 =         (row[13].nil?)?nil:(row[13].strip)
    address.tel3_note =    (row[14].nil?)?nil:(row[14].strip)
    address.tel3 =         (row[15].nil?)?nil:(row[15].strip)
    address.fax =          (row[16].nil?)?nil:(row[16].strip)
    address.url =          (row[17].nil?)?nil:(row[17].strip)
    address.organization = (row[18].nil?)?nil:(row[18].strip)
    address.title =        (row[19].nil?)?nil:(row[19].strip)
    address.memo =         (row[20].nil?)?nil:(row[20].strip)
    address.xorder =       (row[21].nil?)?nil:(row[21].strip)

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

    return err_msgs
  end
end
