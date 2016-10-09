#
#= HistoryHelper
#
#Copyright:: Copyright (c) 2007-2016 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Methods added to this helper will be available to all templates in the application.
#
#== Note:
#
#*
#
module HistoryHelper

  # Pages to move backward to.
  private::HISTORY_ACCEPTS = [
      'desktop/show',
      'items/bbs', 'items/list', 'items/search', 'items/show', 'items/edit',
      'folders/show_tree',
      'schedules/day', 'schedules/week', 'schedules/group', 'schedules/team', 'schedules/month',
      'equipment/schedule_all',
      'workflows/list',
      'researches/users', 'researches/settings',
      'users/list', 'users/edit', 'users/show',
      'groups/show_tree',
      'teams/list',
      'templates/list',
      'timecards/month', 'timecards/users', 'timecards/group', 'timecards/edit',
      'logs/list',
      'zeptair_xlogs/list',
      'zeptair_dist/users',
      'addressbook/list',
      'mail_folders/show_tree',
      'frames/admin'
    ]

  # Pages without Back button.
  private::HISTORY_RESETS = [
      'desktop/show',
      'items/bbs', 'items/list',
      'folders/show_tree',
      'schedules/index', 'schedules/day', 'schedules/week', 'schedules/month', 'schedules/group', 'schedules/team',
      'equipment/schedule_all',
      'workflows/list',
      'researches/users',
      'users/list',
      'groups/show_tree',
      'teams/list',
      'paintmail/index',
      'mail_folders/show_tree',
      'mail_accounts/list',
      'addresses/list',
      'timecards/month', 'timecards/users', 'timecards/group',
      'logs/list',
      'zeptair_xlogs/list',
      'zeptair_dist/users',
      'addressbook/list',
      'mail_folders/show_tree',
      'frames/admin'
    ]

  private::HISTORY_MAX = 5

 public
  #=== self.pop
  #
  #Pops last history parameters in the session.
  #
  #_session_:: Request session.
  #_avoid_paths_:: Path tokens to avoid.
  #return:: Last history parameters in the session.
  #
  def self.pop(session, avoid_paths=nil)

    if session[:history].nil? or (session[:history].length < 2)
      return nil
    else
      if avoid_paths.nil? or avoid_paths.empty?
        last_req = session[:history][-2]
        session[:history].slice!(-2..-1)
      else
        histories = session[:history]
        histories.reject! {|prms|
          path = HistoryHelper.get_path_token(prms)
          avoid_paths.include?(path)
        }
        last_req = histories[-1]
      end
      return last_req
    end
  end

  #=== self.keep_last
  #
  #Keep the last request to move backward.
  #
  #_request_:: Request.
  #
  def self.keep_last(request, params)

    if HistoryHelper.reset?(request)
      request.session[:history] = nil
    end

    cur_path = HistoryHelper.get_path_token(request)

    if HistoryHelper.acceptable?(cur_path)
      prms = ApplicationHelper.dup_hash(params)
      prms.delete('authenticity_token')

      histories = request.session[:history] unless request.session.nil?
      if histories.nil? or histories.empty?
        histories = [prms]
      else
        if HistoryHelper.get_path_token(histories.last) == HistoryHelper.get_path_token(request)
          histories[-1] = prms
        else
          histories = HistoryHelper.avoid_duplex_patterns(histories, prms)

          histories.delete_at(0) if histories.length > HISTORY_MAX
        end
      end

      request.session[:history] = histories
    end

    details = []
    details << 'keep_last # '+cur_path
    details << 'session[:history]='+(request.session[:history] || {}).inspect
    HistoryHelper.log(request, details.join('<br/>'))
  end

  #=== self.get_path_token
  #
  #Gets path token to identify the page.
  #
  #_request_:: Request.
  #
  def self.get_path_token(request)

    if request.respond_to?(:path_parameters)
      prms = request.path_parameters
    else
      prms = request
    end
    return (prms['controller'] || prms[:controller] || '') + '/' + (prms['action'] || prms[:action] || '')
  end

 private
  #=== self.acceptable?
  #
  #Checks if the specified request parameters is acceptable to the history.
  #
  #_path_token_:: Path token.
  #
  def self.acceptable?(path_token)

    return HISTORY_ACCEPTS.include?(path_token)
  end

  #=== self.reset?
  #
  #Checks if the specified request parameters demand to reset history.
  #
  #_request_:: Request.
  #
  def self.reset?(request)

    return HISTORY_RESETS.include?(HistoryHelper.get_path_token(request))
  end

  #=== self.avoid_duplex_patterns
  #
  #Avoids duplex request patterns.
  #
  #_entries_:: Array of Request parameters.
  #_entries_:: Array of Request parameters.
  #return:: Array of Request parameters.
  #
  def self.avoid_duplex_patterns(entries, last_req)

    if entries.length > 2
      cur_order = ''
      idx = -1
      entries.each do |prms|
        path = HistoryHelper.get_path_token(prms)
        idx = HISTORY_ACCEPTS.index(path)
        cur_order << sprintf('%02d', idx)
      end
      path = HistoryHelper.get_path_token(last_req)
      new_tail = sprintf('%02d%02d', idx, HISTORY_ACCEPTS.index(path))

      replace_idx = cur_order.index(new_tail)
      unless replace_idx.nil?
        # A - B - C - B  ( - C )
        # => A - B ( - C )
        replace_idx /= 2    # <== '%02d'
        entries.slice!(replace_idx, entries.length - replace_idx - 1)
      end
    end
    entries << last_req
    return entries
  end

  #=== self.log
  #
  #Adds log of history.
  #
  #_request_:: Request.
  #_detail_:: Detail description.
  #
  def self.log(request, detail)

    #Log.add(:HISTORY, request, detail)
  end
end

