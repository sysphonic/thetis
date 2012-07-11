#
#= Attachment
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Each Attachment is related to an Item, and downloaded from displays of the Item.
#
#== Note:
#
#* 
#
class Attachment < ActiveRecord::Base
  attr_accessible(:title, :memo, :item_id, :xorder, :location, :comment_id, :file)

  belongs_to(:item)
  belongs_to(:comment)

  require 'tempfile'
  require 'fileutils'
  require 'digest/md5'  # for Digest::MD5

  validates_length_of(:content, :maximum => THETIS_ATTACHMENT_DB_MAX_KB*1024, :allow_nil => true)
  validates_presence_of(:name)

  public::LOCATION_DB = 'DB'
  public::LOCATION_DIR = 'DIR'

  #=== file
  #
  #
  #
  def file
  end

  #=== file=
  #
  #
  #
  def file=(file)
    write_attribute(:name, file.original_filename.force_encoding(Encoding::UTF_8))
    write_attribute(:size, file.size)
    write_attribute(:content_type, file.content_type.strip) unless file.content_type.nil?
    write_attribute(:content, file.read)
    write_attribute(:digest_md5, Digest::MD5.hexdigest(self.content))
  end

  #=== self.create
  #
  #Creates an Attachment.
  #
  #_attrs_::Request-parameters for the new Attachment.
  #_parent_:: Parent object to be related to.
  #_xorder_:: Order.
  #return:: Instance of the Attachment.
  #
  def self.create(attrs, parent, xorder)
    attachment = Attachment.new
    if parent.instance_of?(Item)
      attachment.item_id = parent.id
    elsif parent.instance_of?(Comment)
      attachment.comment_id = parent.id
    else
      return nil
    end
    attachment.title = attrs[:title]
    attachment.memo = attrs[:memo]
    attachment.location = attrs[:location] || THETIS_ATTACHMENT_LOCATION_DEFAULT
    attachment.xorder = xorder

    attachment.file = attrs[:file]

    if attachment.location == Attachment::LOCATION_DIR

      if parent.instance_of?(Item)
        attachment.item = parent
      elsif parent.instance_of?(Comment)
        attachment.comment = parent
      end
      path = AttachmentsHelper.get_parent_path(attachment)
      FileUtils.mkdir_p(path)

      temp = Tempfile.new('thetis_attachment', path)
      temp.binmode
      temp.write(attachment.content)
      temp.close(false)

      attachment.content = nil
    end

    attachment.save!

    if attachment.location == Attachment::LOCATION_DIR
      FileUtils.mv(temp.path, File.join(path, attachment.id.to_s + File.extname(attachment.name)))
    end

    return attachment
  end

  #=== copy
  #
  #Copies the Attachment.
  #
  #_item_id_:: Item-ID to be related to.
  #_user_id_:: User-ID.
  #return:: Instance of the copied Attachment.
  #
  def copy(item_id, user_id)

    if self.location == Attachment::LOCATION_DIR
      src_path = AttachmentsHelper.get_path(self)
      return nil if src_path.nil?
    end

    attachment = Attachment.new
    attachment.title = self.title
    attachment.memo = self.memo
    attachment.name = self.name
    attachment.size = self.size
    attachment.content_type = self.content_type
    attachment.content = self.content
    attachment.xorder = self.xorder
    attachment.location = self.location
    attachment.digest_md5 = self.digest_md5
    attachment.item_id = item_id.to_i

    attachment.save!

    if attachment.location == Attachment::LOCATION_DIR

      dst_path = AttachmentsHelper.get_parent_path(attachment)
      FileUtils.mkdir_p(dst_path)
      dst_path = File.join(dst_path, attachment.id.to_s + File.extname(src_path))

      FileUtils.cp(src_path, dst_path)
    end

    return attachment
  end

  #=== self.destroy
  #
  #Updates attributes of the Item.
  #
  #This method overrides ActionRecord::Base.destroy() to
  #handle the related attributes.
  #
  #_id_:: Target Item-ID.
  #
  def self.destroy(id)

    id.is_a?(Array) ? id.each { |id| destroy(id) } : find(id).destroy
  end

  #=== destroy
  #
  #Overrides ActionRecord::Base.destroy().
  #
  def destroy()

    if self.location == Attachment::LOCATION_DIR
      path = AttachmentsHelper.get_path(self)
      unless path.nil?
        FileUtils.rm(path, :force => true)
      end

      AttachmentsHelper.clean_dir(self)
    end

    super()
  end

  #=== self.delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  #_id_:: Target Item-ID.
  #
  def self.delete(id)

    Attachment.destroy(id)
  end

  #=== delete
  #
  #Overrides ActionRecord::Base.delete().
  #
  def delete()

    self.destroy
  end

  #=== self.destroy_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.destroy_all(conditions = nil)

    raise 'Use Attachment.destroy() instead of Attachment.destroy_all()!'
  end

  #=== self.delete_all
  #
  #Overrides ActionRecord::Base.delete_all().
  #
  #_conditions_:: Conditions.
  #
  def self.delete_all(conditions = nil)

    raise 'Use Attachment.destroy() instead of Attachment.delete_all()!'
  end

  #=== update_attributes
  #
  #Overrides ActionRecord::Base.update_attributes().
  #
  #_attrs_:: Hash of attributes and their values.
  #
  def update_attributes(attrs)

    if self.id.nil? or self.id <= 0
      raise 'Use Attachment.save() instead of Attachment.update_attributes() to create a record!'
    end

    unless attrs[:item_id].nil?
      raise 'Do not use Attachment.update_attributes() to change item_id!'
    end

    new_location = attrs[:location] || self.location
    old_location = self.location

    if attrs[:file].nil?

      if old_location == Attachment::LOCATION_DIR and new_location == Attachment::LOCATION_DB

        path = AttachmentsHelper.get_path(self)
        unless path.nil?
          if self.size > THETIS_ATTACHMENT_DB_MAX_KB
            raise 'Cannot move content of Attachment from DIR to DB because it is too large.'
          end

          update_attribute(:content, File.read(path))

          FileUtils.rm(path, :force => true)
          AttachmentsHelper.clean_dir(self)
        end

      elsif old_location == Attachment::LOCATION_DB and new_location == Attachment::LOCATION_DIR

        path = AttachmentsHelper.get_parent_path(self)
        FileUtils.mkdir_p(path)
        fpath = File.join(path, self.id.to_s + File.extname(self.name))

        open(fpath, 'wb') { |file|
          file.write(self.content)
        }

        update_attribute(:content, nil)
      end

    else

      if old_location == Attachment::LOCATION_DIR
        path = AttachmentsHelper.get_path(self)
        FileUtils.rm(path, :force => true) unless path.nil?

        if new_location != Attachment::LOCATION_DIR
          AttachmentsHelper.clean_dir(self)
        end
      end

      self.file = attrs[:file]
      attrs.delete(:file)

      if new_location == Attachment::LOCATION_DIR

        path = AttachmentsHelper.get_parent_path(self)
        FileUtils.mkdir_p(path)
        fpath = File.join(path, self.id.to_s + File.extname(self.name))

        open(fpath, 'wb') { |file|
          file.write(self.content)
        }
        self.content = nil
      end
    end

    super(attrs)
  end
end
