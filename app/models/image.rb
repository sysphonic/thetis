#
#= Image
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class Image < ApplicationRecord
  public::PERMIT_BASE = [:title, :memo, :item_id, :xorder, :file]

  validates_length_of(:content, :within => 1..THETIS_IMAGE_MAX_KB*1024)
  validates_format_of(:content_type, :with => /\Aimage\/(p?jpeg|gif|(x-)?png)\z/i)
  validates_presence_of(:name, :size, :content_type, :content)

  belongs_to(:item)

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
  end

  #=== copy
  #
  #Copies the Image.
  #
  #_item_id_:: New Item-ID.
  #return:: Instance of the copied Image.
  #
  def copy(item_id)

    image = Image.new
    image.title = self.title
    image.memo = self.memo
    image.name = self.name
    image.size = self.size
    image.content_type = self.content_type
    image.content = self.content
    image.xorder = self.xorder
    image.item_id = item_id.to_i

    image.save!

    return image
  end
end
