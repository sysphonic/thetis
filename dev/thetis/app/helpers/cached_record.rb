#
#= CachedRecord
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants for classes which can be cached.
#
#== Note:
#
#* 
#
module CachedRecord

  #=== find_with_cache
  #
  #Finds with cache.
  #
  #_obj_cache_:: Hash to accelerate response. {obj_id, obj}
  #return:: ActiveRecord Object.
  #
  def find_with_cache(obj_id, obj_cache)

    if !obj_cache.nil? and obj_cache.keys.include?(obj_id.to_i)
      obj = obj_cache[obj_id.to_i]
    else
      begin
        obj = self.find(obj_id)
      rescue
        obj = nil
      end

      unless obj_cache.nil?
        obj_cache[obj_id.to_i] = obj
      end
    end

    return obj
  end

  #=== build_cache
  #
  #Builds cache from the instances array.
  #
  #_objs_:: Array of Model instances.
  #return:: Object cache.
  #
  def build_cache(objs)
    return nil if objs.nil?

    obj_cache = {}
    objs.each do |obj|
      obj_cache[obj.id] = obj
    end
    return obj_cache
  end

end
