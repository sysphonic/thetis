#
#= UtilDate
#
#Copyright:: Copyright (c) 2007-2019 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   MIT License (See Release-Notes)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
class UtilDate < Date

  #=== before?
  #
  #Gets if the date represented by this instance is before specified date.
  #Compares only about Year, Month and Day.
  #
  #_date_:: Date / DateTime / Time object to compare with.
  #_eq_:: Flag to match when the both dates are equal.
  #return:: Result.
  #
  def before?(date, eq=false)

    d = Date.new(date.year, date.month, date.day)

    if eq
      return (d - self) >= 0
    else
      return (d - self) > 0
    end
  end

  #=== after?
  #
  #Gets if the date represented by this instance is after specified date.
  #Compares only about Year, Month and Day.
  #
  #_date_:: Date / DateTime / Time object to compare with.
  #_eq_:: Flag to match when the both dates are equal.
  #return:: Result.
  #
  def after?(date, eq=false)

    d = Date.new(date.year, date.month, date.day)

    if eq
      return (self - d) >= 0
    else
      return (self - d) > 0
    end
  end

  #=== self.create
  #
  #Creates an instance from Date / DateTime / Time object.
  #Uses only Year, Month and Day.
  #
  #_src_:: Source object.
  #return:: New instance.
  #
  def self.create(src)

    return UtilDate.new(src.year, src.month, src.day)
  end

  #=== get_date
  #
  #Gets Date instance.
  #
  #return:: Date instance.
  #
  def get_date

    Date.new(self.year, self.month, self.day)
  end

  #=== get_datetime
  #
  #Gets DateTime instance.
  #
  #return:: DateTime instance.
  #
  def get_datetime

    DateTime.new(self.year, self.month, self.day)
  end

  #=== get_time
  #
  #Gets Time instance.
  #
  #return:: Time instance.
  #
  def get_time

    Time.local(self.year, self.month, self.day)
  end
end
