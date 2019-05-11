#
#= UtilDateTime
#
#Copyright:: Copyright (c) 2007-2019 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   MIT License (See Release-Notes)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
class UtilDateTime < DateTime

  #=== self.create
  #
  #Creates an instance from DateTime / Time object.
  #
  #_src_:: Source object.
  #return:: New instance.
  #
  def self.create(src)

    return UtilDateTime.new(src.year, src.month, src.day, src.hour, src.min, src.sec)
  end

  #=== to_time
  #
  #Gets Time instance.
  #
  #return:: Time instance.
  #
  def to_time

    Time.local(self.year, self.month, self.day, self.hour, self.min, self.sec)
  end
end
