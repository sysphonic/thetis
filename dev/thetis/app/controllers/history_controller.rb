#
#= HistoryController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
# 
#
#== Note:
#
#* 
#
class HistoryController < ApplicationController

  #=== back
  #
  #Moves backward.
  #
  def back

    if session[:history].nil? or session[:history].empty?
      Log.add_error(request, nil, 'session[:history] is nil or empty.')
      redirect_to(:controller => 'desktop', :action => 'show')
      return
    end

    last_params = nil

    while !session[:history].nil? and !session[:history].empty?
      last_params = session[:history].last
      session[:history].delete_at(-1)

      avoid = params[:avoid]
      if avoid.nil? or avoid.empty?
        break
      else
        avoid = avoid.to_a

        if avoid.include?(HistoryHelper.get_path_token(last_params))
          last_params = nil
        else
          break
        end
      end
    end

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
