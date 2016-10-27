#
#= FramesController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#The Action-Controller about frames.
#
#== Note:
#
#* 
#
class FramesController < ApplicationController
  layout 'title', :only => [:admin]

  before_action :check_login, :only => [:admin]
  before_action :only => [:admin] do |controller|
    controller.check_auth(nil)
  end


  #=== index
  #
  #Shows Thetis including all subframes such as left-, header-, footer- and main-frame.
  #
  def index
  end

  #=== header
  #
  #Shows header-frame.
  #
  def header
  end

  #=== footer
  #
  #Shows footer-frame.
  #
  def footer
  end

  #=== left
  #
  #Shows left( or 'menu')-frame.
  #
  def left
  end

  #=== admin
  #
  #Shows menu page for administrators.
  #
  def admin
    Log.add_info(request, params.inspect)
  end

  #=== about
  #
  #Shows about-window when clicked on symbol-image in left-frame.
  #
  def about
    Log.add_info(request, params.inspect)
  end

  #=== http_error
  #
  #Shows HTTP error.
  #
  def http_error
    Log.add_info(request, params.inspect)
  end

  #=== show_url
  #
  #Shows URL to show current page.
  #
  def show_url
    Log.add_info(request, params.inspect)

    @root_url = request.protocol+request.host_with_port

    url_h = ApplicationHelper.dup_hash(params[:disp])

    url_h = url_h.update({:controller => url_h['ctrl'], :action => url_h['act']})
    url_h.delete('ctrl')
    url_h.delete('act')

    @def_page = ApplicationHelper.url_for(url_h)
    @def_page = @def_page.gsub(@root_url, '')
  end
end
