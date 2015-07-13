#
#= SqlHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2015 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about SQL.
#
#== Note:
#
#* 
#
module SqlHelper

  #=== self.validate_token
  #
  #Gets query condition with like command of specified attributes.
  #
  #_tokens_:: Target tokens.
  #_extra_chars_:: Extra characters.
  #return:: Query condition.
  #
  def self.validate_token(tokens, extra_chars=nil)

    if extra_chars.nil?
      extra_chars = ''
    else
      extra_chars = Regexp.escape(extra_chars.join())
    end
    regexp = Regexp.new("^[ ]*[a-zA-Z0-9_#{extra_chars}]+[ ]*$")

    [tokens].flatten.each do |token|
      next if token.blank?

      if token.to_s.match(regexp).nil? \
          and token.to_s.match(/^[ ]*\d+-\d+-\d+[ ]*$/).nil?
        raise("[ERROR] SqlHelper.validate_token failed: #{token}")
      end
    end
  end

  #=== self.get_sql_like
  #
  #Gets query condition with like command of specified attributes.
  #
  #_attr_names_:: Attribute names.
  #_keyword_:: Target keyword.
  #return:: Query condition.
  #
  def self.get_sql_like(attr_names, keyword)

    key = SqlHelper.quote("%#{SqlHelper.escape_for_like(keyword)}%")

    con = []
    attr_names.each do |attr_name|
      con << "(#{attr_name} like #{key})"
    end
    sql = con.join(' or ')
    sql = '(' + sql + ')' if con.length > 1
    return sql
  end

  #=== self.escape_for_like
  #
  #Escapes string for like command in SQL.
  #
  #_str_:: Target string.
  #return:: Escaped string.
  #
  def self.escape_for_like(str)

    return nil if str.nil?
    return str.to_s.gsub(/([%_])/){"\\" + $1}
  end

  #=== self.quote
  #
  #Quotes string.
  #
  #_str_:: Target string.
  #return:: Quoted string.
  #
  def self.quote(str)

    return ActiveRecord::Base.connection.quote(str)
  end
end
