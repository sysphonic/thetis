#
#= OfficialTitle
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
#
class OfficialTitle < ApplicationRecord
  public::PERMIT_BASE = [:name]

  extend(CachedRecord)

  public::XORDER_MAX = 9999

  #=== self.get_name
  #
  #Gets the name of the specified OfficialTitle.
  #
  #_official_title_obj_cache_:: Hash to accelerate response. {user_id, user}
  #return:: OfficialTitle name. If not found, prearranged string.
  #
  def self.get_name(official_title_id, official_title_obj_cache=nil)

    return '(root)' if (official_title_id.to_s == '0')

    official_title = OfficialTitle.find_with_cache(official_title_id, official_title_obj_cache)

    if official_title.nil?
      return official_title_id.to_s + ' '+ I18n.t('paren.deleted')
    else
      return official_title.name
    end
  end

  #=== self.get_for
  #
  #Gets OfficialTitles related to the specified conditions.
  #
  #_group_id_:: Target Group-ID.
  #_include_parents_:: Specify true if it is required to take parents authorities into consideration (AND).
  #_enabled_:: Flag to require only enabled or disabled. Specify nil when both necessary.
  #return:: OfficialTitles related to the specified conditions.
  #
  def self.get_for(group_id, include_parents=false, enabled=nil)

    SqlHelper.validate_token([group_id])

    con = []
    #con << "(disabled=#{!enabled})" unless enabled.nil?

    if group_id.nil? or (group_id.to_s == TreeElement::ROOT_ID.to_s)
      con << "((group_id is null) or (group_id=#{TreeElement::ROOT_ID}))"
    else
      if include_parents
        group_con = '(group_id is null)'

        group_obj_cache = {}
        group = Group.find_with_cache(group_id, group_obj_cache)
        group_ids = group.get_parents(false, group_obj_cache)
        group_ids << group_id
        group_ids << TreeElement::ROOT_ID
        group_con << " or (group_id in (#{group_ids.join(',')}))"

        con << '(' + group_con + ')'
      else
        con << "(group_id=#{group_id})"
      end
    end

    order_by = 'order by xorder ASC, id ASC'
    #order_by = 'order by disabled ASC, xorder ASC, id ASC'

    sql = 'select * from official_titles where ' + con.join(' and ') + ' ' + order_by

    return OfficialTitle.find_by_sql(sql)
  end
end
