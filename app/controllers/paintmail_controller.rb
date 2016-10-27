#
#= PaintmailController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#The Action-Controller about PaintMail.
#
#== Note:
#
#* 
#
class PaintmailController < ApplicationController
  layout 'base'

  before_action :check_login

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
    Log.add_info(request, '')   # Not to show passwords.

    raise(RequestPostOnlyException) unless request.post?

    unless @login_user.nil?

      if @login_user.paintmail.nil?
        paintmail = Paintmail.new(params.require(:paintmail).permit(Paintmail::PERMIT_BASE))
        paintmail.user_id = @login_user.id
        paintmail.save
      else
        @login_user.paintmail.update_attributes(params.require(:paintmail).permit(Paintmail::PERMIT_BASE))
      end
    end

    render(:plain => '')
  end
end
