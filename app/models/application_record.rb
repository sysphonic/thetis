class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.count_by_sql_wrapping_select_query(sql)
    sql = sanitize_sql(sql)
    count_by_sql("select count(*) from (#{sql}) as my_table")
  end

  #=== self.permit_base
  #
  #Permits white listed attributes.
  #
  #_attrs_:: Request parameters or Hash of attributes.
  #return:: Permitted attributes.
  #
  def self.permit_base(attrs)
    if attrs.respond_to?('permit')
      if self.const_defined?(:PERMIT_BASE)
        attrs = attrs.permit(self::PERMIT_BASE)
      else
        Rails.logger.error("ApplicationRecord.permit_base(): PERMIT_BASE not defined for #{self.name}.")
      end
    end
    return attrs
  end

  #=== get_timestamp_exp
  #
  #Gets expression of timestamp.
  #
  #_req_full_:: Flag to require full expression.
  #_attr_:: Timestamp attribute.
  #return:: Expression of timestamp.
  #
  def get_timestamp_exp(req_full=true, attr=:updated_at)
    val = self.send(attr)
    if val.nil?
      return I18n.t('msg.hyphen')
    else
      if req_full
        format = THETIS_DATE_FORMAT_YMD+' %H:%M'
      else
        if UtilDate.create(val).get_date == Date.today
          format = '%H:%M'
        else
          format = THETIS_DATE_FORMAT_YMD
        end
      end
      return val.strftime(format)
    end
  end
end
