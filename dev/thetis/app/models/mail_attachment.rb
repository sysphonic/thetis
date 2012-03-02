#
#= MailAttachment
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
class MailAttachment < ActiveRecord::Base
  belongs_to :email

  require 'tempfile'
  require 'fileutils'

  validates_presence_of :name

#See SendMailsController#add_attachment
# validates_length_of :content, :maximum => THETIS_MAIL_SEND_ATTACHMENT_MAX_KB*1024, :allow_nil => true

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
  end

  #=== self.create
  #
  #Creates an MailAttachment.
  #
  #_attrs_::Request-parameters for the new MailAttachment.
  #return:: Instance of the MailAttachment.
  #
  def self.create(attrs)

    mail_attach = MailAttachment.new
    mail_attach.email_id = attrs[:email_id].to_i
    mail_attach.xorder = attrs[:xorder]
    mail_attach.file = attrs[:file]

    begin
      email = Email.find(mail_attach.email_id)
      path = email.get_dir
      FileUtils.mkdir_p(path)

      temp = Tempfile.new('thetis_mail_attach', path)
      temp.binmode
      temp.write(attrs[:file].read)
      temp.close(false)

      mail_attach.save!

      FileUtils.mv(temp.path, File.join(path, mail_attach.id.to_s + File.extname(mail_attach.name)))

      return mail_attach

    rescue StandardError => err
      Log.add_error(nil, err)
      return nil
    end
  end

  #=== get_path
  #
  #Gets path of the file which contains content of MailAttachment.
  #
  #return:: Path of the content file.
  #
  def get_path

    return nil if self.email.nil?

    path = self.email.get_dir

    filepaths = Dir.glob([File.join(path, self.id.to_s), File.join(path, self.id.to_s + '.*')].join("\0"))

    return nil if filepaths.nil? or filepaths.empty?

    return filepaths.first
  end

  #=== copy_file_from
  #
  #Copies file from given MailAttachment.
  #
  #_src_attach_::Source MailAttachment.
  #
  def copy_file_from(src_attach)

    begin
      src_path = src_attach.get_path

      dest_dir = self.email.get_dir
      FileUtils.mkdir_p(dest_dir)

      dest_path = File.join(dest_dir, self.id.to_s + File.extname(src_path))

      FileUtils.cp(src_path, dest_path)

    rescue StandardError => err
      Log.add_error(nil, err)
    end
  end
end
