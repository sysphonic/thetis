# pseudohash.rb
=begin
= PseudoHash class
== SYNOPSIS

  -----
    require "pseudohash"

    record = PseudoHash.new.with_order ['Alice', 'Bob', 'Charlee']
    record['Charlee'] = 90
    record['Alice'] = 91
    record['Bob'] = 89
    record.each{|k,v|
      print "#{k}: #{v}; "
    }
    print "\n"
  -----
  produces:
    Alice: 91; Bob: 89; Charlee 90; 

== DESCRIPTION

PseudoHash is a subclass of Hash but can be specified the order of keys. 
The order of keys determines the order of the iterations of (({each})). 

== METHODS

: phash[((|key|)), ((|set|)) = false] = ((|val|))
  Stores ((|val|)) associating to ((|key|)). 
  If ((|set|)) is true and (({order})) does not include ((|key|)), 
  the ((|key|)) will be appended to order. 
  
: order
  Returns the order of keys.

: order= ((|array|))
  Sets the order of the keys to ((|array|)). 

: order_of ((|key|))
  Returns the position of ((|key|)) in `(({order})). 

: with_oder ((|array|))
  Similar to order= but returns self. 

: each{|k,v| ....}
: each_pair{|k,v| ....}
  Iterates over all pairs of key and value in the order of `(({order}))'. 
  The keys not included in `(({order}))' will be postponed. 

== AUTHORS

Gotoken

== HISTORY

  2000-12-25 Created.

=end

class PseudoHash < Hash

  VERSION = "2000-12-25"

  def order
    @order ||= []
  end

  def order=(ary)
    order.replace ary
  end

  def with_order(ary)
    self.order = ary
    self
  end

  def order_of(key)
    order.index(key)
  end

  alias __each__ each
  alias aset []=

  def []=(k, *rest)
    val, set = rest.reverse
    order.push k if set and not order.include? k
    aset(k,val)
  end

  def each
    rest = keys - order
    order.each {|k| yield(k, self[k]) if include?(k)}
    rest.each  {|k| yield(k, self[k]) }
  end

  alias each_pair each
end

if $0 == __FILE__
  text = (<<"-----")
Date: Sun, 24 Dec 2000 16:29:37 GMT
Server: Apache/1.3.9 (Unix) Debian/GNU mod_ruby/0.2.1 Ruby/1.6.2(2000-11-17)
Location: http://www.ruby-lang.org/en/index.html
Connection: close
Content-Type: text/html; charset=iso-8859-1
-----

  header = PseudoHash.new
  text.each{|line|
    _, = line.scan(/^(.*):\s+(.*)$/)
    name, val = _
    header[name, true] = val
  }
  puts "----- input -----"
  puts text
  puts "----- format -----"
  w = header.keys.map{|i| i.size}.max
  header.each{|k,v|
    puts "#{k.ljust(w)}: #{v}"
  }
end
