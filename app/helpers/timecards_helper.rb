#
#= TimecardsHelper
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
module TimecardsHelper

  require(Rails.root.to_s+'/lib/util/util_date')
  require(Rails.root.to_s+'/lib/util/util_datetime')

  #=== self.get_month_span
  #
  #Gets start and end date of the specified month.
  #
  #_date_:: Target Date.
  #_month_begins_at_:: Setting at which day a month begins.
  #return:: Array of start and end date of the span. [start_date, end_date]
  #
  def self.get_month_span(date, month_begins_at) 
    start_date = Date.new(date.year, date.month, month_begins_at)

    if (month_begins_at <= 1)
      end_date = Date.new(date.year, date.month, -1)
    else
      end_date = Date.new(date.year, date.month, month_begins_at - 1)

      if (date.day < month_begins_at)
        start_date = start_date << 1
      else
        end_date = end_date >> 1
      end
    end

    return [start_date, end_date]
  end

  #=== self.get_year_span
  #
  #Gets start and end date of the specified year.
  #
  #_year_:: Target year.
  #_year_begins_from_:: Setting from which month a year begins.
  #_month_begins_at_:: Setting at which day a month begins.
  #return:: Array of start and end date of the span. [start_date, end_date]
  #
  def self.get_year_span(year, year_begins_from, month_begins_at) 
    start_date = Date.new(year, year_begins_from, month_begins_at)
    end_date = Date.new(year + 1, year_begins_from, month_begins_at) - 1

    return [start_date, end_date]
  end

  #=== self.get_fiscal_year
  #
  #Gets fiscal year to which the specified date belongs.
  #
  #_date_:: Target Date.
  #_year_begins_from_:: Setting from which month a year begins.
  #_month_begins_at_:: Setting at which day a month begins.
  #return:: Fiscal year.
  #
  def self.get_fiscal_year(date, year_begins_from, month_begins_at)
    if (year_begins_from <= 6)
      if UtilDate.new(2000, date.month, date.day).before? Date.new(2000, year_begins_from, month_begins_at)
        return date.year - 1
      else
        return date.year
      end
    else
      if UtilDate.new(2000, date.month, date.day).before? Date.new(2000, year_begins_from, month_begins_at)
        return date.year
      else
        return date.year + 1
      end
    end
  end

  #=== self.get_fiscal_month
  #
  #Gets fiscal month to which the specified date belongs.
  #
  #_date_:: Target Date.
  #_month_begins_at_:: Setting at which day a month begins.
  #return:: Fiscal month.
  #
  def self.get_fiscal_month(date, month_begins_at) 
    if (month_begins_at <= 15)
      if (date.day < month_begins_at)
        return (date.month > 1)?(date.month - 1):(12)
      else
        return date.month
      end
    else
      if (date.day < month_begins_at)
        return date.month
      else
        return (date.month < 12)?(date.month + 1):(1)
      end
    end
  end

  #=== self.get_first_day_in_fiscal_month
  #
  #Gets fiscal month to which the specified date belongs.
  #
  #_fiscal_year_:: Target fiscal year.
  #_fiscal_month_:: Target fiscal month.
  #_month_begins_at_:: Setting at which day a month begins.
  #return:: First day in the specified fiscal month.
  #
  def self.get_first_day_in_fiscal_month(fiscal_year, fiscal_month, month_begins_at) 
    test_date = Date.new(fiscal_year, fiscal_month, month_begins_at)
    test_fiscal_month = TimecardsHelper.get_fiscal_month(test_date, month_begins_at)

    if (test_fiscal_month == fiscal_month)
      year = fiscal_year
      month = fiscal_month
    else  # if (test_fiscal_month > fiscal_month)
      if (fiscal_month > 1)
        year = fiscal_year
        month = fiscal_month - 1
      else
        year = fiscal_year -1
        month = 12
      end
    end

    return Date.new(year, month, month_begins_at)
  end

  #=== self.get_fiscal_params
  #
  #Gets fiscal parameters from configuration.
  #
  #_yaml_:: Specify YAML data if already loaded.
  #return:: Array of fiscal parameters. [year_begins_from, month_begins_at]
  #
  def self.get_fiscal_params(yaml=nil) 

    yaml ||= ApplicationHelper.get_config_yaml

    month_begins_at = YamlHelper.get_value(yaml, 'timecard.month_begins_at', 1).to_i
    year_begins_from = YamlHelper.get_value(yaml, 'timecard.year_begins_from', 1).to_i

    return [year_begins_from, month_begins_at]
  end
end
