
require File.join(File.dirname(__FILE__), '../../lib/util/feed_entry')
require File.join(File.dirname(__FILE__), '../../lib/util/request_post_only_exception')

THETIS_RELATIVE_URL_ROOT = '/thetis'

$thetis_config = YAML.load_file(File.join(File.dirname(__FILE__), '../../config/_config.yml'))

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
THETIS_ATTACHMENT_LOCATION_DIR = File.join(File.dirname(__FILE__), '../../data/files')

THETIS_ATTACHMENT_DB_MAX_KB = 5*1024    # Max 5MB each.
THETIS_IMAGE_MAX_KB = 5*1024            # Max 5MB each.
# Note that you should also specify proper limit-setting to DB corresponding to these 2 lines.
# (See Thetis Users' Manual at http://sysphonic.com/)

THETIS_MAIL_LOCATION_DIR = File.join(File.dirname(__FILE__), '../../data/mails')
THETIS_MAIL_LIMIT_NUM_PER_ACCOUNT = 100
THETIS_MAIL_CAPACITY_MB_PER_ACCOUNT = 300
THETIS_MAIL_SEND_ATTACHMENT_MAX_KB = 3*1024  # Max 3MB per Mail.

THETIS_RESEARCH_PAGE_DIR = File.join(File.dirname(__FILE__), '../../data/research')

THETIS_USER_TIMEZONE_DEFAULT = 'Tokyo'
THETIS_USER_TIMEZONE_SELECTABLE = false

THETIS_SESSION_EXPIRE_AFTER_MIN = 8 * 60

THETIS_REALM = 'thetis'

Rails.application.config.time_zone = 'UTC'

