#
#= Paintmail
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class Paintmail < ApplicationRecord
  public::PERMIT_BASE = [:smtpSenderAddress, :smtpServerAddress, :smtpServerPort, :popServerAddress, :popServerPort, :popUser, :popPassword, :popInterval, :toAddresses, :confDir, :checkNew, :smtpAuth, :smtpUser, :smtpPassword]

  belongs_to(:user)

end
