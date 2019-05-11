#
#= PaintmailController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class PaintmailController < ApplicationController
  layout('base')

  before_action(:check_login)

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
        paintmail = Paintmail.new(Paintmail.permit_base(params.require(:paintmail)))
        paintmail.user_id = @login_user.id
        paintmail.save
      else
        @login_user.paintmail.update_attributes(Paintmail.permit_base(params.require(:paintmail)))
      end
    end

    render(:plain => '')
  end
end
