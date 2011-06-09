
require File.expand_path('../boot', __FILE__)

require 'rails/all'

require File.join(File.dirname(__FILE__), '../lib/pseudohash/pseudohash')
require File.join(File.dirname(__FILE__), '../lib/util/feed_entry')

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

# Change RewriteBase in public/.htaccess if modified the following line.
THETIS_RELATIVE_URL_ROOT = '/thetis'

$thetis_config = YAML.load_file(File.join(File.dirname(__FILE__), '../config/_config.yml'))

THETIS_SYMBOL_IMAGE = 'images/custom/symbol.png'

THETIS_TOPICS_URL = THETIS_RELATIVE_URL_ROOT + '/custom/topics.html'
THETIS_NOTE_URL = THETIS_RELATIVE_URL_ROOT + '/custom/note.html'

THETIS_TEL_TYPES = ['', 'External', 'Internal', 'Home', 'Mobile']

THETIS_DATE_FORMAT_YMD = '%Y-%m-%d'
THETIS_DATE_FORMAT_MD = '%m/%d'
THETIS_CALENDAR_COLOR = ['lightcoral', 'gold', 'gold', 'gold', 'gold', 'gold', 'turquoise']
THETIS_WDAY_COLOR = ['lightpink', '#FFF2AD', '#FFF2AD', '#FFF2AD', '#FFF2AD', '#FFF2AD', '#AAF2F1']
THETIS_WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
THETIS_HOURS = 0..23
THETIS_MINUTES = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
THETIS_DIV_IN_HOUR = 2
THETIS_DAWN = { :color => 'lightsteelblue', :range => 0..3 }
THETIS_MORNING = { :color => 'lavender', :range => 4..7 }
THETIS_DAYTIME = { :color => 'blanchedalmond', :range => 8..12 }
THETIS_AFTERNOON = { :color => 'peachpuff', :range => 13..16 }
THETIS_EVENING= { :color => 'palegoldenrod', :range => 17..20 }
THETIS_NIGHT= { :color => 'lightsteelblue', :range => 21..23 }

THETIS_ATTACHMENT_LOCATION_DEFAULT = 'DIR'   # or 'DB'
THETIS_ATTACHMENT_LOCATION_SELECTABLE = false
THETIS_ATTACHMENT_LOCATION_DIR = File.join(File.dirname(__FILE__), '../data/files')

THETIS_ATTACHMENT_DB_MAX_KB = 5*1024    # Max 5MB each.
THETIS_IMAGE_MAX_KB = 5*1024            # Max 5MB each.
# Note that you should also specify proper limit-setting to DB corresponding to these 2 lines.
# (See Thetis Users' Manual at http://sysphonic.com/)

THETIS_MAIL_LOCATION_DIR = File.join(File.dirname(__FILE__), '../data/mails')
THETIS_MAIL_LIMIT_NUM_PER_USER = 100
THETIS_MAIL_SEND_ATTACHMENT_MAX_KB = 3*1024  # Max 3MB per Mail.

THETIS_RESEARCH_PAGE_DIR = File.join(File.dirname(__FILE__), '../data/research')

THETIS_USER_TIMEZONE_DEFAULT = 'Tokyo'
THETIS_USER_TIMEZONE_SELECTABLE = false

module Thetis
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.action_controller.asset_path = "#{THETIS_RELATIVE_URL_ROOT}%s"

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{Rails.root}/extras )

    # Specify gems that this application depends on and have them installed with rake gems:install
    # config.gem "bj"
    # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
    # config.gem "sqlite3-ruby", :lib => "sqlite3"
    # config.gem "aws-s3", :lib => "aws/s3"

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Skip frameworks you're not going to use. To use Rails without a database,
    # you must remove the Active Record framework.
    # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names.
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    # config.i18n.default_locale = "ja-JP"
    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8
  end
end

