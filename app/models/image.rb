#
#= Image
#
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Each Image is related to an Item, and shown on displays of the Item.
#
#== Note:
#
#* 
#
class Image < ActiveRecord::Base
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
    write_attribute(:name, file.original_filename)
    write_attribute(:size, file.size)
    write_attribute(:content_type, file.content_type.strip)
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
