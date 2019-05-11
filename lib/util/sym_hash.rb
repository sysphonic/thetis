#
#= SymHash
#
#Copyright:: Copyright (c) 2007-2019 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   MIT License (See Release-Notes)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
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
