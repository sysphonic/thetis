#
#= HistoryController
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
class HistoryController < ApplicationController

  #=== back
  #
  #Moves backward.
  #
  def back

    last_params = HistoryHelper.pop(session, params[:avoid])

    if last_params.nil?
      url_h = {
        :controller => 'desktop',
        :action => 'show',
        :history => 'back'
      }
      Log.add_error(request, nil, 'ERROR(No History): Redirect to ' + ApplicationHelper.url_for(url_h))

    else
      url_h = ApplicationHelper.dup_hash(last_params)
      url_h[:history] = 'back'

      Log.add_info(request, 'Redirect to ' + ApplicationHelper.url_for(url_h))
    end

    redirect_to(url_h)
  end
end
