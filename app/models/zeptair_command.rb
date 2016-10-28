#
#= ZeptairCommand
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Command related to Zeptair Distribution Item.
#
#== Note:
#
#* 
#
class ZeptairCommand < ApplicationRecord
  belongs_to :item

end
