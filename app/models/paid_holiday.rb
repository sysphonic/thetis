#
#= PaidHoliday
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
#PaidHoliday represents settings about paid holiday by year.
#
class PaidHoliday < ApplicationRecord
  belongs_to(:user)

  public::CARRY_OVER_NONE = 'none'
  public::CARRY_OVER_1_YEAR = '1_year'
  public::CARRY_OVER_NO_EXPIRATION = 'no_expiration'

  #=== self.get_for
  #
  #Gets PaidHolidays of the specified User.
  #
  #_user_id_:: Target User-ID.
  #_fiscal_year_:: Target year. If not specified, returns all years'.
  #return:: PaidHoliday(s) for the specified User.
  #
  def self.get_for(user_id, fiscal_year=nil)

    SqlHelper.validate_token([user_id, fiscal_year])

    begin
      con = []
      con << "(user_id=#{user_id.to_i})"
      if fiscal_year.nil?
        return PaidHoliday.where(con).order('year ASC').to_a
      else
        con << "(year=#{fiscal_year.to_i})"
        return PaidHoliday.where(con.join(' and ')).first
      end
    rescue
    end
    return nil
  end

  #=== self.update_for
  #
  #Updates PaidHoliday of the specified User and year.
  #Specify 0 for num to remove the record.
  #
  #_user_id_:: Target User-ID.
  #_fiscal_year_:: Target year.
  #_num_:: New days. If specified 0, removes the record.
  #
  def self.update_for(user_id, fiscal_year, num)

    SqlHelper.validate_token([user_id, fiscal_year])

    if (num <= 0)
      con = []
      con << "(user_id=#{user_id.to_i})"
      con << "(year=#{fiscal_year.to_i})"
      PaidHoliday.where(con.join(' and ')).destroy_all
      return
    end

    paid_holiday = PaidHoliday.get_for(user_id, fiscal_year)

    if paid_holiday.nil?
      paid_holiday = PaidHoliday.new
      paid_holiday.user_id = user_id
      paid_holiday.year = fiscal_year
      paid_holiday.num = num
      paid_holiday.save!
    else
      paid_holiday.update_attribute(:num, num)
    end
  end

  #=== self.get_carried_over
  #
  #Gets number of carried-over PaidHolidays of the specified User.
  #
  #_user_id_:: Target User-ID.
  #_year_:: Target year.
  #return:: Number of carried-over PaidHolidays.
  #
  def self.get_carried_over(user_id, year)

    SqlHelper.validate_token([user_id, year])

    yaml = ApplicationHelper.get_config_yaml
    paidhld_carry_over = YamlHelper.get_value(yaml, 'timecard.paidhld_carry_over', nil)

    return 0 if paidhld_carry_over.nil? or paidhld_carry_over.empty? or paidhld_carry_over == PaidHoliday::CARRY_OVER_NONE

    begin
      con = "(user_id=#{user_id.to_i}) and (year < #{year.to_i})"
      paidhlds = PaidHoliday.where(con).order('year ASC').to_a
    rescue
    end
    return 0 if paidhlds.nil? or paidhlds.empty?

    sum = 0
    year_begins_from, month_begins_at = TimecardsHelper.get_fiscal_params

    if (paidhld_carry_over == PaidHoliday::CARRY_OVER_1_YEAR)

      last_carried_out = 0

      for y in paidhlds.first.year .. year - 1
        paidhld = paidhlds.find { |hld| hld.year == y }
        given_num = (paidhld.nil?)?0:paidhld.num

        start_date, end_date = TimecardsHelper.get_year_span(y, year_begins_from, month_begins_at)
        applied_paid_hlds = Timecard.applied_paid_hlds(user_id, start_date, end_date)

        if applied_paid_hlds >= last_carried_out
          last_carried_out = given_num - (applied_paid_hlds - last_carried_out)
        else
          last_carried_out = given_num
        end
      end

      return last_carried_out

    elsif (paidhld_carry_over == PaidHoliday::CARRY_OVER_NO_EXPIRATION)

      paidhlds.each do |paidhld|
        sum += paidhld.num
      end

      start_date, dummy = TimecardsHelper.get_year_span(paidhlds.first.year, year_begins_from, month_begins_at)
      dummy, end_date = TimecardsHelper.get_year_span(year - 1, year_begins_from, month_begins_at)
      applied_paid_hlds = Timecard.applied_paid_hlds(user_id, start_date, end_date)

      return (sum - applied_paid_hlds)
    else
      return 0
    end
  end
end
