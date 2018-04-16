#
#= ZeptairCommand
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Command related to Zeptair Distribution Item.
#
class ZeptairCommand < ApplicationRecord
  belongs_to(:item)

end
