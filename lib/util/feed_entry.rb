#
#= FeedEntry
#
#Copyright:: Copyright (c) 2007-2019 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   MIT License (See Release-Notes)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
class FeedEntry

  @title = nil
  @link = nil
  @guid = nil
  @content = nil
  @content_encoded = nil
  @created_at = nil
  @updated_at = nil
  @author = nil
  @enclosures = nil

  attr_accessor :title
  attr_accessor :link
  attr_accessor :guid
  attr_accessor :content
  attr_accessor :content_encoded
  attr_accessor :created_at
  attr_accessor :updated_at
  attr_accessor :author
  attr_accessor :enclosures

  def has_enclosure?
    return (!@enclosures.nil? and !@enclosures.to_a.empty?)
  end

  def self.create_guid(obj, timestamp=nil)
    guid = obj.class.to_s + '#' + obj.id.to_s
    unless timestamp.nil?
      guid << '@' + timestamp
    end
    return guid
  end
end

class FeedEntry::FeedEnclosure
  @url = nil
  @type = nil
  @length = nil
  @id = nil
  @name = nil
  @title = nil
  @updated_at = nil
  @digest_md5 = nil

  attr_accessor :url
  attr_accessor :type
  attr_accessor :length
  attr_accessor :id
  attr_accessor :name
  attr_accessor :title
  attr_accessor :updated_at
  attr_accessor :digest_md5
end
