require File.expand_path('../boot', __FILE__)

require File.join(File.dirname(__FILE__), '../lib/util/feed_entry')
require File.join(File.dirname(__FILE__), '../lib/ya2yaml/lib/ya2yaml')

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

THETIS_RELATIVE_URL_ROOT = '/thetis'

$thetis_config = YAML.load_file(File.join(File.dirname(__FILE__), '../config/_config.yml'))

THETIS_SYMBOL_IMAGE = 'images/custom/symbol.png'

THETIS_TOPICS_URL = THETIS_RELATIVE_URL_ROOT + '/custom/topics.html'
THETIS_NOTE_URL = THETIS_RELATIVE_URL_ROOT + '/custom/note.html'

THETIS_EMAIL_TYPES = ['', 'official', 'private', 'mobile']
THETIS_TEL_TYPES = ['', 'External', 'Internal', 'Home', 'Mobile']

THETIS_DATE_FORMAT_YMD = '%Y-%m-%d'
THETIS_DATE_FORMAT_MD = '%m/%d'
THETIS_CALENDAR_COLOR = ['lightpink', '#FFE241', '#FFE241', '#FFE241', '#FFE241', '#FFE241', '#AAF2F1']
THETIS_WDAY_COLOR = ['lightpink', '#FFF2AD', '#FFF2AD', '#FFF2AD', '#FFF2AD', '#FFF2AD', '#AAF2F1']
THETIS_WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
THETIS_HOURS = 0..23
THETIS_MINUTES = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
THETIS_DIV_IN_HOUR = 2
THETIS_SCHEDULE_TIMECOLORS = [
  {:range =>  0.. 3, :color => 'lightsteelblue'},
  {:range =>  4.. 7, :color => 'lavender'},
  {:range =>  8..11, :color => 'blanchedalmond'},
  {:range => 12..15, :color => 'peachpuff'},
  {:range => 16..17, :color => 'blanchedalmond'},
  {:range => 18..20, :color => 'lavender'},
  {:range => 21..23, :color => 'lightsteelblue'},
]

THETIS_ATTACHMENT_LOCATION_DEFAULT = 'DIR'   # or 'DB'
THETIS_ATTACHMENT_LOCATION_SELECTABLE = false
THETIS_ATTACHMENT_LOCATION_DIR = File.join(File.dirname(__FILE__), '../data/files')

THETIS_ATTACHMENT_DB_MAX_KB = 5*1024    # Max 5MB each.
THETIS_IMAGE_MAX_KB = 5*1024            # Max 5MB each.
# Note that you should also specify proper limit-setting to DB corresponding to these 2 lines.
# (See Thetis Users' Manual at http://sysphonic.com/)

THETIS_MAIL_LOCATION_DIR = File.join(File.dirname(__FILE__), '../data/mails')
THETIS_MAIL_LIMIT_NUM_PER_ACCOUNT = 100
THETIS_MAIL_CAPACITY_MB_PER_ACCOUNT = 300
THETIS_MAIL_SEND_ATTACHMENT_MAX_KB = 3*1024  # Max 3MB per Mail.

THETIS_RESEARCH_PAGE_DIR = File.join(File.dirname(__FILE__), '../data/research')

THETIS_USER_TIMEZONE_DEFAULT = 'Tokyo'
THETIS_USER_TIMEZONE_SELECTABLE = false

THETIS_SESSION_EXPIRE_AFTER_MIN = 8 * 60

THETIS_REALM = 'thetis'

module Thetis
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.filter_parameters += [:password]

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
  end
end
