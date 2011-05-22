# rake thetis:utc_time RAILS_ENV=production cur_offset='+0900'

namespace :thetis do
  task :utc_time, :needs => [:environment] do

    session = ActiveRecord::Base.connection
    cur_offset = ENV['cur_offset']

    _execute(session, 'items', 'created_at', cur_offset)
    _execute(session, 'items', 'updated_at', cur_offset)

    _execute(session, 'folders', 'created_at', cur_offset)

    _execute(session, 'users', 'created_at', cur_offset)
    _execute(session, 'users', 'login_at', cur_offset)

    _execute(session, 'comments', 'updated_at', cur_offset)

    _execute(session, 'logs', 'updated_at', cur_offset)

    _execute(session, 'schedules', 'created_at', cur_offset)
    _execute(session, 'schedules', 'updated_at', cur_offset)
    _execute(session, 'schedules', 'start', cur_offset, 'NOT(allday=1)')
    _execute(session, 'schedules', 'end', cur_offset, 'NOT(allday=1)')

    _execute(session, 'workflows', 'issued_at', cur_offset)
    _execute(session, 'workflows', 'decided_at', cur_offset)

    _execute(session, 'toys', 'created_at', cur_offset)
    _execute(session, 'toys', 'updated_at', cur_offset)
    _execute(session, 'toys', 'accessed_at', cur_offset)

    _execute(session, 'timecards', 'start', cur_offset)
    _execute(session, 'timecards', 'end', cur_offset)
    _execute(session, 'timecards', 'updated_at', cur_offset)

    _execute(session, 'settings', 'created_at', cur_offset)
    _execute(session, 'settings', 'updated_at', cur_offset)

    #### < ver.1.0.0 ####
  end

  def _execute(session, table, column, cur_offset, add_con=nil)
    puts("Processing #{table}.#{column} ..")

    params = cur_offset.scan(/([+-])(\d{2})[:]?(\d{2})/).first

    if params[0] == '-'
      func = 'ADDTIME'
    else
      func = 'SUBTIME'
    end
    diff = "#{params[1]}:#{params[2]}:00"
    where = "(#{column} IS NOT NULL) and NOT(#{column}='')"
    where << ' and (' + add_con + ')' unless add_con.nil? or add_con.empty?

    sql = "UPDATE #{table} SET #{column}=#{func}(#{column}, '#{diff}') WHERE #{where}"
    session.execute(sql)
  end
end
