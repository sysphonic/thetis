#
#= Paintmail
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Keeps PaintMail's configurations of each user.
#
class Paintmail < ApplicationRecord
  public::PERMIT_BASE = [:smtpSenderAddress, :smtpServerAddress, :smtpServerPort, :popServerAddress, :popServerPort, :popUser, :popPassword, :popInterval, :toAddresses, :confDir, :checkNew, :smtpAuth, :smtpUser, :smtpPassword]

  belongs_to(:user)

end
