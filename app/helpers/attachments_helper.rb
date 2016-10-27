#
#= AttachmentsHelper
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Provides utility methods and constants about Attachment files.
#
#== Note:
#
#* 
#
module AttachmentsHelper

  #=== self.get_parent_path
  #
  #Gets path of the parent directory of the specified Attachment.
  #
  #_attachment_:: Target Attachment.
  #return:: Path of the parent directory.
  #
  def self.get_parent_path(attachment)

    item = attachment.item
    sub_folder = nil

    if item.nil?
      item = attachment.comment.item
      sub_folder = 'comment'
    end

    user_id = item.user_id

    top_name = (user_id / 100 * 100).to_s

    return File.join(THETIS_ATTACHMENT_LOCATION_DIR, top_name, user_id.to_s, item.id.to_s, sub_folder || '')
  end

  #=== self.get_path
  #
  #Gets path of the specified Attachment.
  #
  #_attachment_:: Target Attachment.
  #return:: Path of the specified Attachment.
  #
  def self.get_path(attachment)

    path = AttachmentsHelper.get_parent_path(attachment)

    filepaths = Dir.glob([File.join(path, attachment.id.to_s), File.join(path, attachment.id.to_s + '.*')].join("\0"))

    return nil if filepaths.nil? or filepaths.empty?

    return filepaths.first
  end

  #=== self.clean_dir
  #
  #Cleans directories where Attachment files are stored.
  #
  #_attachment_:: Target Attachment.
  #
  def self.clean_dir(attachment)

    path = AttachmentsHelper.get_parent_path(attachment)
    _clean_dir(path)
  end

 private
  #=== self._clean_dir
  #
  #Cleans directories where Attachment files are stored.
  #
  #_attachment_:: Target Attachment.
  #
  def self._clean_dir(path)

    if File.expand_path(path) == File.expand_path(THETIS_ATTACHMENT_LOCATION_DIR)
      return
    end

    files_dirs = Dir.glob(File.join(path, '**/*'))
    if files_dirs.nil? or files_dirs.empty?
      FileUtils.remove_entry_secure(path, true)
      _clean_dir(File.dirname(path))
    end
  end
end
