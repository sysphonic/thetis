#
#= FeedsController
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#The Action-Controller about Feeds.
#
#== Note:
#
#* 
#
class FeedsController < ApplicationController
  before_filter :basic_auth
  before_filter :check_enabled

  #=== index
  #
  #Gets Feeds about specified categories.
  #
  def index
#   Log.add_info(request, params.inspect)

    user = session[:login_user]
    root_url = ApplicationHelper.root_url(request)

    _build_site_info(root_url)

    @entries = []

    feed = params[:feed]
    feed = 'all' if params[:feed].nil?
    feed = feed.split('-')

    users_cache = {}

    if feed.include?('all')
      @entries += Schedule.get_alarm_feeds(user, root_url)
      @entries += Item.get_feeds(user, root_url, users_cache)
      @entries += Comment.get_feeds(user, root_url, users_cache)
      @entries += Workflow.get_feeds(user, root_url, users_cache)
      @entries += Schedule.get_feeds(user, root_url)
      @entries += Toy.get_feeds(user, root_url, users_cache)
    else
      feed.each do |category|
        case category
          when 'items'
            @entries += Item.get_feeds(user, root_url, users_cache)
          when 'comments'
            @entries += Comment.get_feeds(user, root_url, users_cache)
          when 'workflows'
            @entries += Workflow.get_feeds(user, root_url, users_cache)
          when 'schedules'
            @entries += Schedule.get_feeds(user, root_url)
          when 'alarm'
            @entries += Schedule.get_alarm_feeds(user, root_url)
          when 'postlabel'
            @entries += Toy.get_feeds(user, root_url, users_cache)
        end
      end
    end

    respond_to do |format|
      format.html { render :action => 'index.rss' }
      format.rss
      format.atom
    end
  end

  #=== zeptair_dist
  #
  #Gets Feeds about Zeptair Distributions.
  #
  def zeptair_dist
    Log.add_info(request, params.inspect)

    root_url = ApplicationHelper.root_url(request)
    user = session[:login_user]

    _build_site_info(root_url)
    @site_title = t('zeptair.dist.title')

    if params[:admins].nil? or params[:admins].empty?
      admins = nil
    else
      admins = params[:admins].split(',')
    end

    @entries = ZeptairDistHelper.get_feeds(user, root_url, admins)
    @enable_custom_spec = true

    respond_to do |format|
      format.html { render :action => 'index.rss' }
      format.rss
      format.atom
    end
  end

 private
  #=== _build_site_info
  #
  #Builds the site information of the feeds.
  #
  #_root_url_:: Root URL of this site.
  #
  def _build_site_info(root_url)
    app_root = root_url + THETIS_RELATIVE_URL_ROOT + '/'

    @site_title = '[%s] %s' % [$thetis_config[:general]['app_title'], app_root]
    @site_description = '%s %s' % [$thetis_config[:general]['symbol_title'], $thetis_config[:general]['app_title']] + (($thetis_config[:general]['symbol_title']=='Sysphonic' and $thetis_config[:general]['app_title']=='Thetis')?'':' based on Sysphonic Thetis')
    @site_url = app_root
    @atom_url = root_url + ApplicationHelper.url_for(:controller => 'feeds', :action => 'index')
    @rss_url = @atom_url
    @author = 'Sysphonic Co., Ltd.'
  end

  #=== basic_auth
  #
  #Filter method of Basic-Authentication.
  #
  def basic_auth
    authenticate_or_request_with_http_basic do |user_name, password|
      check = false

      user = User.get_from_name(user_name)

      unless user.nil?
        if user.password == password
          session[:login_user] = user
          check = true
        end
      end
      check == true
    end
  rescue StandardError => err
    Log.add_error(request, err)
  end

  #=== check_enabled
  #
  #Filter method to check if Feeds is enabled.
  #
  def check_enabled
    if $thetis_config[:feed].nil? or $thetis_config[:feed]['enabled'] != '1'
      render(:text => '(Feed is currently disabled.)', :layout => false)
    end
  end
end
