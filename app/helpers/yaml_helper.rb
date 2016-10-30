#
#= YamlHelper
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Provides utility methods and constants about YAML.
#
#== Note:
#
#* 
#
module YamlHelper

  #=== self.get_value
  #
  #Gets value in YAML.
  #
  #_yaml_:: Target YAML.
  #_key_path_:: Key path in YAML.
  #_def_val_:: Default value.
  #return:: Value in YAML.
  #
  def self.get_value(yaml, key_path, def_val=nil)

    unless yaml.nil?
      key_path.to_s.split(/[.]/).each do |key|
        if yaml[key].nil? and !yaml[key.to_sym].nil?
          # for Backward compatibility
          yaml[key] = yaml[key.to_sym]
          yaml.delete(key.to_sym)
        end
        yaml = yaml[key]

        break if yaml.nil?
      end
    end
    return (yaml.nil?)?(def_val):(yaml)
  end

  #=== self.set_value
  #
  #Sets value in YAML.
  #
  #_yaml_:: Target YAML.
  #_key_path_:: Key path in YAML.
  #_val_:: Value to set.
  #return:: Value in YAML.
  #
  def self.set_value(yaml, key_path, val)

    yaml ||= {}

    parent_node = nil
    keys = key_path.to_s.split(/[.]/)
    keys.each do |key|
      if yaml[key].nil?
        if yaml[key.to_sym].nil?
          yaml[key] = {}
        else
          # for Backward compatibility
          yaml[key] = yaml[key.to_sym]
          yaml.delete(key.to_sym)
        end
      end
      parent_node = yaml
      yaml = yaml[key]
    end
    parent_node[keys.last] = val unless parent_node.nil?
  end
end
