#
#= ConfigController
#
#Copyright::(c)2007-2016 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#The Action-Controller about Configuration of Thetis.
#
#== Note:
#
#*
#
class ConfigController < ApplicationController
  layout 'base'

  before_action :check_login
  before_action :except => [:update_by_ajax] do |controller|
    controller.check_auth(User::AUTH_ALL)
  end


  #=== edit
  #
  #Shows form to edit configuration.
  #
  def edit
    Log.add_info(request, params.inspect)

    @yaml = ApplicationHelper.get_config_yaml
  end

  #=== update_by_ajax
  #
  #Updates configuration by Ajax.
  #
  def update_by_ajax
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    cat_h = {'desktop' => User::AUTH_DESKTOP, 'user' => User::AUTH_USER, 'log' => User::AUTH_LOG}

    yaml = ApplicationHelper.get_config_yaml

    cat_h.keys.each do |cat|

      next if params[cat].blank?

      unless @login_user.admin?(cat_h[cat])
        render(:plain => t('msg.need_to_be_admin'))
        return
      end

      params[cat].each do |key, val|
        YamlHelper.set_value(yaml, [cat, key].join('.'), val)
      end
    end

    ApplicationHelper.save_config_yaml(yaml)

    render(:plain => '')
  end

  #=== update
  #
  #Updates configuration.
  #
  def update
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    categories = ['general', 'menu', 'topic', 'note', 'smtp', 'feed', 'user', 'log']

    yaml = ApplicationHelper.get_config_yaml

    categories.each do |cat|
      next if params[cat].nil? or params[cat].empty?

      params[cat].each do |key, val|
        if cat == 'general'
          case key
            when 'symbol_image'
              ConfigHelper.save_img('symbol.png', val) if val.size > 0
            else
              YamlHelper.set_value(yaml, [cat, key].join('.'), val)
          end
        elsif cat == 'topic'
          case key
            when 'src'
              ConfigHelper.save_html('topics.html', val) if val.size > 0
            else
              YamlHelper.set_value(yaml, [cat, key].join('.'), val)
          end
        elsif cat == 'note'
          case key
            when 'src'
              ConfigHelper.save_html('note.html', val) if val.size > 0
            else
              YamlHelper.set_value(yaml, [cat, key].join('.'), val)
          end
        else
          if params[:smtp]['auth_enabled'] == '0'
            val = nil if ['auth', 'user_name', 'password'].include?(key)
          end
          YamlHelper.set_value(yaml, [cat, key].join('.'), val)
        end
      end
    end

    ApplicationHelper.save_config_yaml(yaml)

    flash[:notice] = t('msg.update_success')
    redirect_to(:controller => 'config', :action => 'edit')
  end

  #=== edit_header_menu
  #
  #<Ajax>
  #Shows form to edit the specified header menu.
  #
  def edit_header_menu
    Log.add_info(request, params.inspect)

    unless params[:org_name].nil?
      yaml = ApplicationHelper.get_config_yaml

      unless YamlHelper.get_value(yaml, 'general.header_menus', nil).nil?
        YamlHelper.get_value(yaml, 'general.header_menus', nil).each do |header_menu|
          if header_menu[0] == params[:org_name]
            @header_menu_param = header_menu
            break
          end
        end
      end
    end

    render(:partial => 'ajax_header_menu_info', :layout => false)
  end

  #=== destroy_header_menu
  #
  #<Ajax>
  #Destroys the specified header menu.
  #
  def destroy_header_menu
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @yaml = ApplicationHelper.get_config_yaml

    unless params[:org_name].nil?
      header_menus = YamlHelper.get_value(@yaml, 'general.header_menus', [])
      header_menus.each do |header_menu|
        if header_menu[0] == params[:org_name]
          header_menus.delete(header_menu)
          ApplicationHelper.save_config_yaml(@yaml)
          break
        end
      end
    end

    render(:partial => 'ajax_header_menu', :layout => false)
  end

  #=== updates_header_menu
  #
  #<Ajax>
  #Updates the specified header menu.
  #
  def update_header_menu
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    @yaml = ApplicationHelper.get_config_yaml
    header_menus = YamlHelper.get_value(@yaml, 'general.header_menus', [])

    entry = [params[:header_menu]['name'], params[:header_menu]['target'], params[:header_menu]['url']]

    if params[:org_name].nil? or (params[:org_name] != entry[0])
      header_menus.each do |header_menu|
        if header_menu[0] == entry[0]
          flash[:notice] = 'ERROR:' + t('msg.menu_duplicated')
          render(:partial => 'ajax_header_menu', :layout => false)
          return
        end
      end
    end

    idx = nil
    unless params[:org_name].nil?
      i = 0
      header_menus.each do |header_menu|
        if header_menu[0] == params[:org_name]
          idx = i
          break
        end
        i += 1
      end
    end

    if idx.nil?
      header_menus << entry
    else
      header_menus[idx] = entry
    end

    YamlHelper.set_value(@yaml, 'general.header_menus', header_menus)
    ApplicationHelper.save_config_yaml(@yaml)

    render(:partial => 'ajax_header_menu', :layout => false)
  end

  #=== update_header_menus_order
  #
  #<Ajax>
  #Updates header menus' order.
  #
  def update_header_menus_order
    Log.add_info(request, params.inspect)

    raise(RequestPostOnlyException) unless request.post?

    header_menus = params[:header_menus_order]

    yaml = ApplicationHelper.get_config_yaml

    unless YamlHelper.get_value(yaml, 'general.header_menus', nil).nil?
      YamlHelper.get_value(yaml, 'general.header_menus', nil).sort! { |h_menu_a, h_menu_b|
        idx_a = header_menus.index h_menu_a[0]
        idx_a = 100 if idx_a.nil?
        idx_b = header_menus.index h_menu_b[0]
        idx_b = 101 if idx_b.nil?

        idx_a - idx_b
      }

      ApplicationHelper.save_config_yaml(yaml)
    end

    render(:plain => '')
  end
end
