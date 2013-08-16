#
#= Desktop
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Desktop preferences and configurations related to each User.
#
#== Note:
#
#* 
#
class Desktop < ActiveRecord::Base
  public::PERMIT_BASE = [:theme, :background_color, :popup_news, :popup_timecard, :popup_schedule, :img_enabled, :file]

  validates_length_of(:img_content, :within => 1..THETIS_IMAGE_MAX_KB*1024, :allow_nil => true)
  validates_format_of(:img_content_type, :with => /\Aimage\/(p?jpeg|gif|(x-)?png)\z/i, :allow_nil => true)

  public::THEME_BOLT = 'bolt'
  public::THEME_GRAPE = 'grape'

  public::BGCOLOR_BLUE = 'blue'
  public::BGCOLOR_PINK = 'pink'
  public::BGCOLOR_ORANGE = 'orange'
  public::BGCOLOR_BROWN = 'brown'
  public::BGCOLOR_GREEN = 'green'


  #=== self.get_for
  #
  #Gets Desktop of the specified User.
  #If not exists, returns default settings.
  #
  #_user_:: Target User.
  #_incl_img_content_::Flag to include image content.
  #return:: Desktop of the specified User.
  #
  def self.get_for(user, incl_img_content=false)

    if user.nil?
      desktop = nil
    else
      if incl_img_content
        begin
          desktop = Desktop.find(:first, :conditions => ['user_id=?', user.id])
        rescue
        end
      else
        sql = 'select id, user_id, theme, background_color, popup_news, popup_timecard, popup_schedule, img_enabled, img_name, img_size, img_content_type, created_at, updated_at from desktops'
        sql << ' where user_id=' + user.id.to_s
        begin
          desktop = Desktop.find_by_sql(sql).first
        rescue
        end
      end
    end

    if desktop.nil?
      desktop = Desktop.new
      desktop.user_id = user.id unless user.nil?
      desktop.theme = Desktop::THEME_BOLT
      desktop.background_color = Desktop::BGCOLOR_BLUE
      desktop.popup_news = true
      desktop.popup_timecard = false
      desktop.popup_schedule = false
      desktop.img_enabled = false
    end

    return desktop
  end

  #=== get_corner_image_name
  #
  #Gets corner image name of Desktop.
  #
  #_top_bottom_:: Top or Bottom.
  #_left_right_:: Left or Right.
  #return:: Corner image name.
  #
  def get_corner_image_name(top_bottom, left_right)

    case self.theme
     when THEME_GRAPE
      return "#{self.theme}_#{top_bottom.to_s[0, 1]}_#{left_right.to_s[0, 1]}.png"
     else     # when THEME_BOLT
      return self.theme + '.png'
    end
  end

  #=== self.background_color
  #
  #Gets background-color value of CSS corresponding to the
  #specified color type.
  #
  #_bgcolor_::Color type.
  #_highlight_::Flag to require highlight color.
  #return:: background-color value of CSS.
  #
  def self.background_color(bgcolor, highlight=false)
    case bgcolor
     when BGCOLOR_PINK
      return (highlight)?'#F6D1F4':'#F1BEEE'
     when BGCOLOR_ORANGE
      return (highlight)?'#FFC6A0':'#F9BF9C'
     when BGCOLOR_BROWN
      return (highlight)?'#F9E1C1':'#F6CEAB'
     when BGCOLOR_GREEN
      return (highlight)?'#D7FFBF':'#BFF49F'
     else     # when BGCOLOR_BLUE
      return (highlight)?'#A4DFF8':'#A9CDF9'
    end
  end

  #=== get_background_color
  #
  #Gets selected background-color value of CSS
  #
  #_highlight_::Flag to require highlight color.
  #return:: Selected background-color value of CSS.
  #
  def get_background_color(highlight=false)
    return Desktop.background_color(self.background_color, highlight)
  end

  #=== file
  #
  #
  #
  def file
  end
 
  #=== file=
  #
  #
  #
  def file=(file)
    write_attribute(:img_name, file.original_filename)
    write_attribute(:img_size, file.size)
    write_attribute(:img_content_type, file.content_type.strip)
    write_attribute(:img_content, file.read)
  end
end
