#
#= TreeElement
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants for classes which have tree composition.
#
#== Note:
#
#* 
#
module TreeElement

  #=== get_parents
  #
  #Gets parents array of this object.
  #
  #_ret_obj_:: Flag to require node instances by return.
  #_cache_:: Hash to accelerate response. {node_id.to_s, obj}
  #return:: Array of parent nodes or node-IDs.
  #
  def get_parents(ret_obj, cache=nil)

    array = []
    node = nil
    node_id = nil

    while true

      if node.nil?
        node = self
      else
        if ret_obj
          array.insert(0, node)
        else
          array.insert(0, node_id)
        end
      end

      node_id = node.parent_id.to_s

      break if node_id == '0'  # '0' for ROOT

      node = nil
      unless cache.nil?
        node = cache[node_id]
      end
      if node.nil?
        begin
          node = self.class.find(node_id)
          cache[node_id] = node unless cache.nil?
        rescue StandardError => err
          Log.add_error(nil, err)
        end
      end
      break if node.nil?
    end

    return array
  end

  #=== self.get_childs
  #
  #Gets childs array of the specified node.
  #
  #_cls_:: Class of tree element.
  #_node_id_:: Target node-ID.
  #_recursive_:: Specify true if recursive search is required.
  #_ret_obj_:: Flag to require node instances by return.
  #return:: Array of child node-IDs, or Groups if ret_obj is true.
  #
  def self.get_childs(cls, node_id, recursive, ret_obj)

    array = []

    if recursive

      tree = cls.get_tree(PseudoHash.new, nil, node_id)
      return array if tree.nil?

      tree.each do |parent_id, childs|
        if ret_obj
          array = array | childs
        else
          childs.each do |node|
            node_id = node.id.to_s
            array << node_id unless array.include?(node_id)
          end
        end
      end

    else

      nodes = cls.find(:all, :conditions => ['parent_id=?', node_id])
      if ret_obj
        array = nodes
      else
        nodes.each do |node|
          array << node.id.to_s
        end
      end
    end

    return array
  end

  #=== get_childs
  #
  #Gets childs array of this node.
  #
  #_recursive_:: Specify true if recursive search is required.
  #_ret_obj_:: Flag to require node instances by return.
  #return:: Array of child node-IDs, or nodes if ret_obj is true.
  #
  def get_childs(recursive, ret_obj)

    return self.class.get_childs(self.id, recursive, ret_obj)
  end

  #=== self.get_tree
  #
  #Gets tree of Groups.
  #Called recursive.
  #
  def self.get_tree(cls, tree, conditions, node_id, order_by)

    con = Marshal.load(Marshal.dump(conditions)) unless conditions.nil?

    if con.nil?
      con = ['']
    else
      con[0] << ' and '
    end
    con[0] << 'parent_id=?'
    con << node_id

    tree[node_id, true] = cls.find(:all, :conditions => con, :order => order_by)

    tree[node_id].each do |node|
      tree = cls.get_tree(tree, conditions, node.id.to_s)
    end

    return tree
  end
end
