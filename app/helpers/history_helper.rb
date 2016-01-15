#
#= HistoryHelper
#
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
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
  private::LAST_REQ_NUM = 2

 public
  #=== self.get_last_in_session
  #
  #Gets last history parameters in the session.
  #
  #_session_:: Request session.
  #return:: Last history parameters in the session.
  #
  def self.get_last_in_session(session)

    if session[:history].nil? or session[:history].empty?
      return nil
    else
      return session[:history].last
    end
  end

  #=== self.keep_last
  #
  #Keep the last request to move backward.
  #
  #_request_:: Request.
  #
  def self.keep_last(request)

    if HistoryHelper.reset?(request.parameters)
      request.session[:last_req_params] = nil
      request.session[:history] = nil
    end

    if HistoryHelper.acceptable?(request.parameters)
      prms = ApplicationHelper.dup_hash(request.parameters)
      prms.delete('authenticity_token')

      last_reqs = request.session[:last_req_params] unless request.session.nil?
      if last_reqs.nil? or last_reqs.empty?
        last_reqs = [prms]
      else
        if HistoryHelper.get_path_token(last_reqs.last) == HistoryHelper.get_path_token(prms)
          last_reqs[-1] = prms
        else
          last_reqs << prms
          last_reqs.delete_at(0) if last_reqs.length > LAST_REQ_NUM
        end
      end

      request.session[:last_req_params] = last_reqs
    end
  end

  #=== self.set_back
  #
  #Adds the last request to the history to move backward.
  #
  #_request_:: Request to get session data.
  #
  def self.set_back(request)

    return if request.parameters[:history] == 'back'

    last_reqs = request.session[:last_req_params]

    return if last_reqs.nil? or last_reqs.empty?

#Debug
#Log.add_error(nil, nil, '@@@ ' + last_reqs.collect {|prms| get_path_token(prms)}.join("\n"))

    if HistoryHelper.acceptable?(request.parameters)
      last_req_idx = -1
      cur_path = HistoryHelper.get_path_token(request.parameters)
      last_reqs.each_with_index.reverse_each do |last_params, idx|
        if !cur_path.blank? and (cur_path == HistoryHelper.get_path_token(last_params))
          next
        else
          last_req_idx = idx
          break
        end
      end
    else
      last_req_idx = last_reqs.length - 1
    end

    return if last_req_idx < 0

    entry = last_reqs[last_req_idx]

    history = request.session[:history]
    if history.nil?
      history = []
    elsif !history.last.nil?
      if get_path_token(history.last) == get_path_token(entry)
        history.delete_at(-1)
      end
    end

    # Avoid duplex patterns.
    if history.length > 2
      cur_order = ''
      idx = -1
      history.each do |prms|
        path = get_path_token(prms)
        idx = HISTORY_ACCEPTS.index(path)
        cur_order << sprintf('%02d', idx)
      end
      path = get_path_token(entry)
      new_tail = sprintf('%02d%02d', idx, HISTORY_ACCEPTS.index(path))

      replace_idx = cur_order.index(new_tail)
      if replace_idx.nil?
        if history.length >= HISTORY_MAX
          history.delete_at(-1)
        end
      else
        # A - B - C - B  ( - C )
        # => A - B ( - C )
        replace_idx /= 2    # <== '%02d'
        history.slice!(replace_idx, history.length - replace_idx - 1)
      end
    end

    history << entry

#Debug
#Log.add_error(nil, nil, '### ' + history.collect {|prms| get_path_token(prms)}.join("\n"))

    request.session[:history] = history
    request.session[:last_req_params].delete_at(last_req_idx)
  end

  #=== self.acceptable?
  #
  #Checks if the specified request parameters is acceptable to the history.
  #
  #_prms_:: Parameters to check.
  #
  def self.acceptable?(prms)

    return HISTORY_ACCEPTS.include?(get_path_token(prms))
  end

  #=== self.reset?
  #
  #Checks if the specified request parameters demand to reset history.
  #
  #_prms_:: Parameters to check.
  #
  def self.reset?(prms)

    return HISTORY_RESETS.include?(get_path_token(prms))
  end

  #=== self.get_path_token
  #
  #Gets path token to identify the page.
  #
  #_prms_:: Parameters.
  #
  def self.get_path_token(prms)

    return prms['controller'] + '/' + prms['action']
  end
end

