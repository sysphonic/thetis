#
#= SymHash
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2015 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See Release-Notes)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Utility sub class of Date.
#
#== Note:
#
#*
#
class SymHash < Hash

  def delete(key)
    super(key.to_s)
  end

  def []=(key, val)
    super(key.to_s, val)
  end

  def [](key)
    super(key.to_s)
  end
end
