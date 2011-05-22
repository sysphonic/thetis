#
#= PaintmailController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about PaintMail.
#
#== Note:
#
#* 
#
class PaintmailController < ApplicationController
  layout 'base'

  include LoginChecker

  before_filter :check_login, :except => [:save_conf]

  #=== index
  #
  #Shows PaintMail index page.
  #
  def index
    Log.add_info(request, params.inspect)
  end

  #=== save_conf
  #
  #Shows PaintMail index page.
  #
  def save_conf
    Log.add_info(request, params.inspect)

    user = User.authenticate(params[:user])

    unless user.nil?
      
      if user.paintmail.nil?
        paintmail = Paintmail.new(params[:paintmail])
        paintmail.user_id = user.id
        paintmail.save 
      else
        user.paintmail.update_attributes(params[:paintmail])
      end
    end 

    render(:text => '')
  end
end
