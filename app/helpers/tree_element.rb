#
#= TreeElement
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
module TreeElement

  public::ROOT_ID = 0

  #=== get_parents
  #
  #Gets parents array of this object.
  #
  #_ret_obj_:: Flag to require node instances by return.
  #_cache_:: Hash to accelerate response. {node.id, obj}
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
          array.insert(0, node_id.to_s)
        end
      end

      node_id = node.parent_id

      break if (node_id == TreeElement::ROOT_ID)

      node = nil
      unless cache.nil?
        node = cache[node_id]
      end
      if node.nil?
        begin
          node = self.class.find(node_id)
          cache[node_id] = node unless cache.nil?
        rescue => evar
          Log.add_error(nil, evar)
        end
      end
      break if node.nil?
    end

    return array
  end

  #=== self.get_childs
  #
  #Gets child nodes array of the specified node.
  #
  #_klass_:: Class of tree element.
  #_node_id_:: Target node-ID.
  #_recursive_:: Specify true if recursive search is required.
  #_ret_obj_:: Flag to require node instances by return.
  #return:: Array of child node-IDs, or instances if ret_obj is true.
  #
  def self.get_childs(klass, node_id, recursive, ret_obj)

    SqlHelper.validate_token([node_id])

    array = []

    if recursive

      tree = klass.get_tree(Hash.new, nil, node_id)
      return array if tree.nil?

      tree.each do |parent_id, childs|
        if ret_obj
          array |= childs
        else
          childs.each do |node|
            node_id = node.id.to_s
            array << node_id unless array.include?(node_id)
          end
        end
      end

    else

      nodes = klass.where("parent_id=#{node_id.to_i}").order('xorder ASC, id ASC').to_a
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
  #Gets child nodes array of this node.
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
  def self.get_tree(klass, tree, conditions, node_id, order_by)

    SqlHelper.validate_token([node_id])
    if conditions.nil?
      con = ''
    else
      con = Marshal.load(Marshal.dump(conditions)) + ' and '
    end
    con << "(parent_id=#{node_id.to_i})"

    tree[node_id] = klass.where(con).order(order_by).to_a

    tree[node_id].each do |node|
      tree = klass.get_tree(tree, conditions, node.id.to_s)
    end

    return tree
  end

  #=== self.get_flattened_nodes
  #
  #Gets sorted flattened Array of the tree nodes.
  #
  #_tree_:: Tree Array.
  #return:: Subnodes.
  #
  def self.get_flattened_nodes(tree)
    nodes = tree.values.flatten.uniq
    sorted_nodes = []
    self._get_sorted_nodes(sorted_nodes, nodes, nodes)
    return sorted_nodes
  end

  #=== self.get_end_node_ids
  #
  #Gets sorted flattened Array of the tree nodes.
  #
  #_tree_:: Tree Array.
  #return:: Node-IDs.
  #
  def self.get_end_node_ids(tree)

    node_ids = TreeElement.get_flattened_nodes(tree).collect {|rec| rec.id.to_s}
    del_ids = tree.keys.select {|parent_id| !(tree[parent_id].nil? or tree[parent_id].empty?)}
    return (node_ids - del_ids)
  end

private
  #=== self._get_sorted_nodes
  #
  #Gets sorted Array of the tree nodes.
  #Called recursive.
  #
  #_sorted_nodes_:: Output Array.
  #_nodes_:: Array of the whole nodes.
  #_subnodes_:: Subnodes.
  #
  def self._get_sorted_nodes(sorted_nodes, nodes, subnodes)
    subnodes.each do |node|
      next if sorted_nodes.include?(node)
      sorted_nodes << node
      subsubnodes = nodes.select{|rec| rec.parent_id == node.id}
      unless subsubnodes.empty?
        self._get_sorted_nodes(sorted_nodes, nodes, subsubnodes)
      end
    end
  end
end
