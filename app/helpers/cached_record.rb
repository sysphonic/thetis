#
#= CachedRecord
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
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

    if (!obj_cache.nil? and obj_cache.keys.include?(obj_id.to_i))
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
