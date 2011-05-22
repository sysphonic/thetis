#
#= Paintmail
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Keeps PaintMail's configurations of each user.
#
#== Note:
#
#* 
#
class Paintmail < ActiveRecord::Base
  belongs_to :user


end
