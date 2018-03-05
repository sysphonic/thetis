#
#= Timecard
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#Timecard represents a timecard's record by day and User.
#
#== Note:
#
#* 
#
class Timecard < ApplicationRecord
  public::PERMIT_BASE = [:date, :user_id, :item_id, :workcode, :start, :end, :breaks, :comment, :status, :options]

  belongs_to(:user)

  require ::Rails.root.to_s+'/lib/util/util_datetime'

  public::BGCOLOR_HOLIDAY = '#ffcccb'
  public::BGCOLOR_SUN = '#ffcccb'
  public::BGCOLOR_SAT = '#cbecff'

  # Specify in hex digits to export *.xls by client applications.
  public::BGCOLOR_XLS_HOLIDAY = '#ff99cc'
  public::BGCOLOR_XLS_SUN = '#ff99cc'
  public::BGCOLOR_XLS_SAT = '#cbecff'

  public::MINUTES = [0, 15, 30, 45]

  public::OPT_BUSINESS_TRIP = 'business_trip'

  public::STATUS_LATENESS = 'lateness'
  public::STATUS_LEAVING_EARLY = 'leaving_early'

  public::WKCODE_WK_NORMAL = 'wk_normal'
  public::WKCODE_WK_ON_HOLIDAY = 'wk_on_holiday'
  public::WKCODE_HLD_PAID = 'hld_paid'
  public::WKCODE_HLD_AM = 'hld_am'
  public::WKCODE_HLD_PM = 'hld_pm'
  public::WKCODE_HLD_SPECIAL = 'hld_special'
  public::WKCODE_HLD_MAKEUP = 'hld_makeup'
  public::WKCODE_ABSENCE = 'absence'

  public::WKCODE_ICONS = {
    WKCODE_WK_NORMAL => 'attendance.png',
    WKCODE_WK_ON_HOLIDAY => 'work_on_holiday.png',
    WKCODE_HLD_PAID => 'paid_holiday.png',
    WKCODE_HLD_AM => 'off_am.png',
    WKCODE_HLD_PM => 'off_pm.png',
    WKCODE_HLD_SPECIAL => 'special_holiday.png',
    WKCODE_HLD_MAKEUP => 'makeup_holiday.png',
    WKCODE_ABSENCE => 'absence.png',
  }

  public::WKCODE_PARAM_LABORDAY = 0
  public::WKCODE_PARAM_PAIDHLD = 1

  before_save do |rec|
    status_arr = []
    status_arr << Timecard::STATUS_LATENESS if rec.calc_lateness?
    status_arr << Timecard::STATUS_LEAVING_EARLY if rec.calc_leaving_early?

    rec.status = ApplicationHelper.a_to_attr(status_arr)
  end

  def self.workcodes
    hash = {}
    hash[WKCODE_WK_NORMAL] =     [1.0, 0.0]
    hash[WKCODE_WK_ON_HOLIDAY] = [1.0, 0.0]
    hash[WKCODE_HLD_PAID] =      [0.0, 1.0]
    hash[WKCODE_HLD_AM] =        [0.5, 0.5]
    hash[WKCODE_HLD_PM] =        [0.5, 0.5]
    hash[WKCODE_HLD_SPECIAL] =   [0.0, 0.0]
    hash[WKCODE_HLD_MAKEUP] =    [0.0, 0.0]
    hash[WKCODE_ABSENCE] =       [0.0, 0.0]
    return hash
  end

  #=== workcode_icon
  #
  #Gets workcode icon.
  #
  #return:: Workcode icon.
  #
  def workcode_icon
    return WKCODE_ICONS[self.workcode]
  end

  #=== self.workcode_names
  #
  #Gets Hash of workcode names.
  #
  #return:: Hash of workcode names.
  #
  def self.workcode_names
    return {
      WKCODE_WK_NORMAL => I18n.t('timecard.attendance'),
      WKCODE_WK_ON_HOLIDAY => I18n.t('timecard.work_on_holiday'),
      WKCODE_HLD_PAID => I18n.t('timecard.paid_holiday'),
      WKCODE_HLD_AM => I18n.t('timecard.off_am'),
      WKCODE_HLD_PM => I18n.t('timecard.off_pm'),
      WKCODE_HLD_SPECIAL => I18n.t('timecard.special_holiday'),
      WKCODE_HLD_MAKEUP => I18n.t('timecard.makeup_holiday'),
      WKCODE_ABSENCE => I18n.t('timecard.absence'),
    }
  end

  #=== workcode_name
  #
  #Gets workcode name.
  #
  #return:: Workcode name.
  #
  def workcode_name
    return Timecard.workcode_names[self.workcode]
  end

  #=== self.get_by_key
  #
  #Gets Timecard identified by the specified keys.
  #
  #_user_id_:: Target User-ID.
  #_date_:: Target date.
  #return:: Timecard identified by the specified keys.
  #
  def self.get_by_key(user_id, date)

    return nil if user_id.nil? or date.nil?

    if date.kind_of?(Date)
      date_s = Schedule.sys_date_form(date)
    else
      date_s = date
    end

    con = []
    con << "(user_id=#{user_id})"
    con << "(date='#{date_s}')"

    return Timecard.where(con.join(' and ')).first
  end

  #=== self.off?
  #
  #Gets if it is off.
  #
  #_wkcode_:: Workcode.
  #return:: true if off, false otherwise.
  #
  def self.off?(wkcode)
    return (Timecard.workcodes[wkcode][WKCODE_PARAM_LABORDAY] <= 0.0)
  end

  #=== off?
  #
  #Gets if it is off.
  #
  #return:: true if off, false otherwise.
  #
  def off?
    return Timecard.off?(self.workcode)
  end

  #=== off_am?
  #
  #Gets if it is off AM.
  #
  #return:: true if off AM, false otherwise.
  #
  def off_am?
    return (self.workcode == WKCODE_HLD_AM)
  end

  #=== off_pm?
  #
  #Gets if it is off PM.
  #
  #return:: true if off PM, false otherwise.
  #
  def off_pm?
    return (self.workcode == WKCODE_HLD_PM)
  end

  #=== work_on_holiday?
  #
  #Gets if it is working on holiday.
  #
  #return:: true if working on holiday, false otherwise.
  #
  def work_on_holiday?
    return (self.workcode == WKCODE_WK_ON_HOLIDAY)
  end

  #=== lateness?
  #
  #Gets if it is a lateness.
  #
  #return:: true if lateness, false otherwise.
  #
  def lateness?

    if self.status.nil?
      return false
    else
      return self.status.include?(ApplicationHelper.a_to_attr([Timecard::STATUS_LATENESS]))
    end
  end

  #=== calc_lateness?
  #
  #Gets if it is a lateness.
  #
  #return:: true if lateness, false otherwise.
  #
  def calc_lateness?
    return false if self.start.nil? or self.work_on_holiday?

    if self.off_am?
      commence_at = Timecard.get_commence_at_when_off_am(self.date)
    else
      commence_at = Timecard.get_commence_at(self.date)
    end

    if commence_at.nil?
      return false
    else
      return (commence_at < self.start)
    end
  end

  #=== leaving_early?
  #
  #Gets if it is a leaving early.
  #
  #return:: true if leaving early, false otherwise.
  #
  def leaving_early?

    if self.status.nil?
      return false
    else
      return self.status.include?(ApplicationHelper.a_to_attr([Timecard::STATUS_LEAVING_EARLY]))
    end
  end

  #=== calc_leaving_early?
  #
  #Gets if it is a leaving early.
  #
  #return:: true if leaving early, false otherwise.
  #
  def calc_leaving_early?
    return false if self.end.nil? or self.work_on_holiday?

    if self.off_pm?
      close_at = Timecard.get_close_at_when_off_pm(self.date)
    else
      close_at = Timecard.get_close_at(self.date)
    end

    if close_at.nil?
      return false
    else
      return (self.end < close_at)
    end
  end

  #=== business_trip?
  #
  #Gets if it is marked as a business trip.
  #
  #return:: true if marked as a business trip, false otherwise.
  #
  def business_trip?
    if self.options.nil?
      return false
    else
      return self.options.include?(ApplicationHelper.a_to_attr([Timecard::OPT_BUSINESS_TRIP]))
    end
  end

  #=== get_breaks_a
  #
  #Gets breaks array.
  #
  #return:: Array of span array. ex.[[start1, end1],[start2, end2]...]. If no breaks, returns empty array.
  #
  def get_breaks_a

    return [] if self.breaks.nil? or self.breaks.empty?

    arr = ApplicationHelper.attr_to_a(self.breaks)

    ret = []
    arr.each do |span|
      params = span.split('~')
      ret << [UtilDateTime.parse(params.first).to_time, UtilDateTime.parse(params.last).to_time]
    end

    return ret
  end

  #=== get_break
  #
  #Gets break span of this timecard.
  #
  #return:: break span (min).
  #
  def get_break
    breaks_a = self.get_breaks_a

    sec = 0
    breaks_a.each do |span|
      sec += span.last - span.first
    end

    return (sec / 60)
  end

  #=== update_break
  #
  #Updates break.
  #
  #_org_start_:: Original start time. If nil, solely added.
  #_start_t_:: New start time.
  #_end_t_:: New end time.
  #return:: true if succeeded, false otherwise.
  #
  def update_break(org_start, start_t, end_t)
    spans = self.get_breaks_a

    spans.each do |span|
      if span.first == org_start
        span[0] = start_t
        span[1] = end_t
        return self.update_breaks(spans)
      end
    end

    spans << [start_t, end_t]
    return self.update_breaks(spans)
  end

  #=== update_breaks
  #
  #Updates breaks with sorting and checking overlapped spans.
  #
  #_spans_:: Array of span array. ex.[[start1, end1],[start2, end2]...]
  #return:: true if succeeded, false otherwise.
  #
  def update_breaks(spans)

    if spans.nil? or spans.empty?
      self.update_attribute(:breaks, nil)
    else
      begin
        spans = Timecard.sort_breaks(spans)

        arr = []
        spans.each do |span|
          arr << span.first.strftime(Schedule::SYS_DATETIME_FORM) + '~' + span.last.strftime(Schedule::SYS_DATETIME_FORM)
        end

        self.update_attribute(:breaks, ApplicationHelper.a_to_attr(arr))

      rescue
        return false
      end
    end

    return true
  end

  #=== self.sort_breaks
  #
  #Sorts breaks with checking overlapped spans.
  #
  #_spans_:: Array of span array. ex.[[start1, end1],[start2, end2]...]
  #return:: Sorted array. If overlapped breaks are found, an exception will be raised.
  #
  def self.sort_breaks(spans)
    overlapped_span = nil
    spans.sort! { |span_a, span_b|
      if overlapped_span.nil?
        overlapped_span = ApplicationHelper.get_overlapped_span(span_a.first, span_a.last, span_b.first, span_b.last)
      end
      if span_a.first.nil?
        if span_b.first.nil?
          -1
        else
          1
        end
      elsif span_b.first.nil?
        -1
      else
        UtilDateTime.create(span_a.first).to_time - UtilDateTime.create(span_b.first).to_time
      end
    }
    if overlapped_span.nil?
      return spans
    else
      raise 'Breaks overlap!'
    end
  end

  #=== delete_break
  #
  #Deletes break.
  #
  #_org_start_:: Original start time.
  #
  def delete_break(org_start)
    spans = self.get_breaks_a

    spans.each do |span|
      if span.first == org_start
        spans.delete(span)
        self.update_breaks(spans)
        return
      end
    end
  end

  #=== set_default_breaks
  #
  #Sets default breaks.
  #
  def set_default_breaks
    return if self.start.nil? or self.end.nil?

    yaml = ApplicationHelper.get_config_yaml
    default_breaks = YamlHelper.get_value(yaml, 'timecard.default_breaks', nil)

    unless default_breaks.nil?
      cur_breaks = self.get_breaks_a
      def_brks = []

      default_breaks.each do |span|
        def_brk = _get_break_span(span.first, span.last)

        unless def_brk.nil?
          next if !cur_breaks.empty? and def_brk.first <= cur_breaks.last.last

          def_brks << def_brk
        end
      end

      self.update_breaks(def_brks + cur_breaks)
    end
  end

 private
  #=== _get_break_span
  #
  #Gets break span.
  #
  #_break_start_:: Start time of the break.
  #_break_end_:: End time of the break.
  #return:: Array of start and end time.
  #
  def _get_break_span(break_start, break_end)
    return nil if self.start.nil? or self.end.nil?

    start_dt = UtilDateTime.new(self.start.year, self.start.month, self.start.day, break_start.hour, break_start.min)
    end_dt = UtilDateTime.new(self.start.year, self.start.month, self.start.day, break_end.hour, break_end.min)

    if end_dt.to_time <= start_dt.to_time
      end_dt += 1
    else
      if end_dt.to_time <= self.start
        start_dt += 1
        end_dt += 1
      end
    end

    return ApplicationHelper.get_overlapped_span(start_dt.to_time, end_dt.to_time, self.start, self.end)
  end

 public
  #=== self.get_by
  #
  #Gets Timecard of the specified User and Date.
  #
  #_user_id_:: Target User-ID.
  #_date_s_:: Target Date string.
  #return:: Timecard for the specified User and Date.
  #
  def self.get_by(user_id, date_s)

    SqlHelper.validate_token([user_id, date_s])
    begin
      con = "(user_id=#{user_id.to_i}) and (date='#{date_s}')"
      return Timecard.where(con).first
    rescue
    end
    return nil
  end

  #=== self.find_term
  #
  #Gets Timecards of the specified User and span.
  #
  #_user_id_:: Target User-ID.
  #_start_date_:: Start Date of the span.
  #_end_date_:: End Date of the span.
  #return:: Timecard for the specified User and span.
  #
  def self.find_term(user_id, start_date, end_date)

    SqlHelper.validate_token([user_id])

    start_s = start_date.strftime(Schedule::SYS_DATE_FORM)
    end_s = end_date.strftime(Schedule::SYS_DATE_FORM)

    con = "(user_id=#{user_id.to_i}) and (date >= '#{start_s}') and (date <= '#{end_s}')"
    arr = Timecard.where(con).order('date ASC').to_a
    timecards_h = Hash.new
    unless arr.nil?
      arr.each do |timecard|
        timecards_h[timecard.date.strftime(Schedule::SYS_DATE_FORM)] = timecard
      end
    end
    return timecards_h
  end

  #=== self.applied_paid_hlds
  #
  #Gets the number of applied paid holidays of the specified User and span.
  #
  #_user_id_:: Target User-ID.
  #_start_date_:: Start Date of the span.
  #_end_date_:: End Date of the span.
  #return:: Number of applied paid holidays.
  #
  def self.applied_paid_hlds(user_id, start_date, end_date)

    SqlHelper.validate_token([user_id])

    start_s = start_date.strftime(Schedule::SYS_DATE_FORM)
    end_s = end_date.strftime(Schedule::SYS_DATE_FORM)

    sql = "SELECT COUNT(*) FROM timecards WHERE user_id = #{user_id} AND date >= '#{start_s}' AND date <= '#{end_s}'"

    sum = 0.0
    self.workcodes.each do |key, params|
      paidhld_rate = params[WKCODE_PARAM_PAIDHLD]
      if paidhld_rate > 0.0
        num = Timecard.count_by_sql(sql + " AND workcode='#{key}'")
        sum += num * paidhld_rate
      end
    end

    return sum
  end

  #=== get_overtime
  #
  #Gets overtime.
  #
  #return:: Overtime (min).
  #
  def get_overtime
    return 0 if self.start.nil? or self.end.nil?

    if self.off_am?
      standard_wktime = Timecard.get_standard_wktime_when_off_am
    elsif self.off_pm?
      standard_wktime = Timecard.get_standard_wktime_when_off_pm
    else
      standard_wktime = Timecard.get_standard_wktime
    end

    return 0 if standard_wktime <= 0

    return self.get_actual_wktime - standard_wktime

#    overtime = self.get_actual_wktime - standard_wktime
#
#    if overtime >= 0
#      return overtime
#    else
#      return 0
#    end
  end

  #=== get_usual_overtime
  #
  #Gets normal overtime.
  #
  #return:: Normal overtime (min).
  #
  def get_usual_overtime

    overtime = self.get_overtime
    midnight_overtime = self.get_midnight_overtime

    if overtime <= 0
      return overtime
    elsif overtime <= midnight_overtime
      return 0
    else
      return (overtime - midnight_overtime)
    end

#    usual_overtime = self.get_overtime - self.get_midnight_overtime
#
#    if usual_overtime >= 0
#      return usual_overtime
#    else
#      return 0
#    end
  end

  #=== get_midnight_overtime
  #
  #Gets midnight overtime.
  #
  #return:: Midnight overtime (min).
  #
  def get_midnight_overtime
    return 0 if self.start.nil? or self.end.nil?

    midnight_spans = self.get_midnight_spans

    return 0 if midnight_spans.nil?

    midnight_overtime = 0

    midnight_spans.each do |span|
      midnight_overtime += self.get_actual_wktime(span.first, span.last)
    end

    return midnight_overtime
  end

  #=== get_overtime_start
  #
  #Gets start time of the overtime.
  #
  #return:: Start time of the overtime.
  #
  def get_overtime_start
    return nil if self.start.nil? or self.end.nil? or self.get_overtime <= 0

    standard_wktime = Timecard.get_standard_wktime

    return nil if standard_wktime <= 0

    overtime_start = self.start + standard_wktime * 60

    self.get_breaks_a.each do |span|
      span_start = span.first
      span_end = span.last

      next if span_start > span_end or span_start > self.end

      if overtime_start > span_end
        overtime_start += (span_end - span_start)
      end
    end

    return overtime_start
  end

  #=== self.get_standard_wktime
  #
  #Gets standard worktime.
  #
  #return:: Standard worktime (min).
  #
  def self.get_standard_wktime

    yaml = ApplicationHelper.get_config_yaml
    standard_wktime = YamlHelper.get_value(yaml, 'timecard.standard_hours', nil)

    unless standard_wktime.nil?
      hour_min = standard_wktime.split(':')
      return (hour_min.first.to_i*60 + hour_min.last.to_i)
    end

    return 0
  end

  #=== self.get_standard_wktime_when_off_am
  #
  #Gets standard worktime when off AM.
  #
  #return:: Standard worktime when off AM (min).
  #
  def self.get_standard_wktime_when_off_am

    yaml = ApplicationHelper.get_config_yaml
    standard_wktime_when_off_am = YamlHelper.get_value(yaml, 'timecard.standard_hours_when_off_am', nil)

    unless standard_wktime_when_off_am.nil?
      hour_min = standard_wktime_when_off_am.split(':')
      return (hour_min.first.to_i*60 + hour_min.last.to_i)
    end

    return 0
  end

  #=== self.get_standard_wktime_when_off_pm
  #
  #Gets standard worktime when off PM.
  #
  #return:: Standard worktime when off PM (min).
  #
  def self.get_standard_wktime_when_off_pm

    yaml = ApplicationHelper.get_config_yaml
    standard_wktime_when_off_pm = YamlHelper.get_value(yaml, 'timecard.standard_hours_when_off_pm', nil)

    unless standard_wktime_when_off_pm.nil?
      hour_min = standard_wktime_when_off_pm.split(':')
      return (hour_min.first.to_i*60 + hour_min.last.to_i)
    end

    return 0
  end

  #=== self.get_commence_at
  #
  #Gets the commencement time.
  #
  #_date_:: Target date. If not required, specify nil.
  #return:: Commencement time.
  #
  def self.get_commence_at(date)

    date = Date.today if date.nil?

    yaml = ApplicationHelper.get_config_yaml
    commence_at = YamlHelper.get_value(yaml, 'timecard.commence_at', nil)

    unless commence_at.nil? or commence_at.empty?
      hour_min = commence_at.split(':')
      return Time.local(date.year, date.month, date.day, hour_min.first.to_i, hour_min.last.to_i)
    end

    return nil
  end

  #=== self.get_commence_at_when_off_am
  #
  #Gets the commencement time when off AM.
  #
  #_date_:: Target date. If not required, specify nil.
  #return:: Commencement time when off AM.
  #
  def self.get_commence_at_when_off_am(date)

    date = Date.today if date.nil?

    yaml = ApplicationHelper.get_config_yaml
    commence_at_when_off_am = YamlHelper.get_value(yaml, 'timecard.commence_at_when_off_am', nil)

    unless commence_at_when_off_am.nil? or commence_at_when_off_am.empty?
      hour_min = commence_at_when_off_am.split(':')
      return Time.local(date.year, date.month, date.day, hour_min.first.to_i, hour_min.last.to_i)
    end

    return nil
  end

  #=== self.get_close_at
  #
  #Gets the closing time.
  #
  #_date_:: Target date. If not required, specify nil.
  #return:: Closing time.
  #
  def self.get_close_at(date)

    date = Date.today if date.nil?

    yaml = ApplicationHelper.get_config_yaml
    close_at = YamlHelper.get_value(yaml, 'timecard.close_at', nil)

    unless close_at.nil? or close_at.empty?
      hour_min = close_at.split(':')
      return Time.local(date.year, date.month, date.day, hour_min.first.to_i, hour_min.last.to_i)
    end

    return nil
  end

  #=== self.get_close_at_when_off_pm
  #
  #Gets the closing time when off PM.
  #
  #_date_:: Target date. If not required, specify nil.
  #return:: Closing time when off PM.
  #
  def self.get_close_at_when_off_pm(date)

    date = Date.today if date.nil?

    yaml = ApplicationHelper.get_config_yaml
    close_at_when_off_pm = YamlHelper.get_value(yaml, 'timecard.close_at_when_off_pm', nil)

    unless close_at_when_off_pm.nil? or close_at_when_off_pm.empty?
      hour_min = close_at_when_off_pm.split(':')
      return Time.local(date.year, date.month, date.day, hour_min.first.to_i, hour_min.last.to_i)
    end

    return nil
  end

  #=== self.get_midnight_spans
  #
  #Gets the spans taken as midnight.
  #
  #return:: Array of the start and end time of the midnight span.
  #
  def get_midnight_spans
    return nil if self.start.nil? or self.end.nil?

    yaml = ApplicationHelper.get_config_yaml

    conf_span = YamlHelper.get_value(yaml, 'timecard.midnight_span', nil)
    return nil if conf_span.nil? or conf_span.empty?

    conf_span = conf_span.split('~')
    from = conf_span.first.split(':')
    from = UtilDateTime.new(self.date.year, self.date.month, self.date.day, from.first.to_i, from.last.to_i)
    to = conf_span.last.split(':')
    to = UtilDateTime.new(self.date.year, self.date.month, self.date.day, to.first.to_i, to.last.to_i)

    from -= 1 if from.to_time > to.to_time

    spans = []

    2.times do
      span = ApplicationHelper.get_overlapped_span(from.to_time, to.to_time, self.start, self.end)
      spans << span unless span.nil?

      if from.day != to.day or self.start.day != self.end.day
        from += 1
        to += 1
      else
        break
      end
    end

    return spans
  end

  #=== get_actual_wktime
  #
  #Gets actual worktime.
  #
  #_start_t_:: Start time of the target span.
  #_end_t_:: End time of the target span.
  #return:: Actual worktime (min).
  #
  def get_actual_wktime(start_t=self.start, end_t=self.end)

    return 0 if start_t.nil? or end_t.nil? or start_t > end_t

    wksec = end_t - start_t

    self.get_breaks_a.each do |span|
      overlapped_span = ApplicationHelper.get_overlapped_span(start_t, end_t, span.first, span.last)

      unless overlapped_span.nil?
        wksec -= (overlapped_span.last - overlapped_span.first)
      end
    end

    return (wksec / 60)
  end

  #=== self.get_exist_span
  #
  #Gets span of the existing Timecards.
  #
  #_user_id_:: Target User-ID.
  #return:: Array of the dates. [start_date, end_date]
  #
  def self.get_exist_span(user_id)
    arr = connection.select_one("SELECT MIN(date),MAX(date) FROM (SELECT * FROM timecards WHERE user_id=#{user_id}) AS my_table").to_a
    if arr.nil?
      return [nil, nil]
    else
      ret = []
      arr.each do |key, value|

        return [nil, nil] if value.nil?

        if key == 'MIN(date)'
          ret[0] = Date.parse(value.to_s)
        elsif key == 'MAX(date)'
          ret[1] = Date.parse(value.to_s)
        end
      end
    end
    return ret
  end

  #=== present_now?
  #
  #Gets if the specified time is within worktime.
  #
  #_time_:: Target Time.
  #return:: true if the within worktime, otherwise false.
  #
  def present_now?(time=nil)

    time ||= Time.now
    date = Date.new(time.year, time.month, time.day)
    date_s = Schedule.sys_date_form(date)

    return false if self.start.nil?

    s = self.start
    start_time = Time.mktime(date.year, date.month, date.day, s.hour, s.min, s.sec)

    if (Schedule.sys_date_form(self.date) == date_s) and (start_time <= time)
      if self.end.nil?
        return true
      else
        e = self.end
        end_time = Time.mktime(date.year, date.month, date.day, e.hour, e.min, e.sec)

        if (time <= end_time)
          return true
        end
      end
    end
    return false
  end
end
