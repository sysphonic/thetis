#
#= ZeptairCommand
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Command related to Zeptair Distribution Item.
#
#== Note:
#
#* 
#
class ZeptairCommand < ActiveRecord::Base
  belongs_to :item

end
