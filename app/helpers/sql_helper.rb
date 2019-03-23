#
#= SqlHelper
#
#Copyright::(c)2007-2018 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
module SqlHelper

  #=== self.to_bool
  #
  #Gets SQL expression as boolean.
  #
  #_val_:: Target value
  #return:: SQL expression as boolean.
  #
  def self.to_bool(val)

    bool = false
    unless val.blank?
      bool = ['true', '1'].include?(val.to_s.downcase)
    end

    return (bool)?(1):(0)
  end

  #=== self.validate_token
  #
  #Validates specified tokens.
  #
  #_tokens_:: Target tokens.
  #_extra_chars_:: Extra characters.
  #
  def self.validate_token(tokens, extra_chars=nil)

    if extra_chars.nil?
      extra_chars = ''
    else
      extra_chars = Regexp.escape(extra_chars.join())
    end
    regexp = Regexp.new("\\A[ ]*[a-zA-Z0-9_#{extra_chars}]+[ ]*\\z")

    [tokens].flatten.each do |token|
      next if token.blank?

      token = token.to_s

      if token.match(regexp).nil? \
          and token.match(/\A[ ]*\d+-\d+-\d+[ ]*\z/).nil?
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
  #_as_:: One of :both, :prefix and :suffix.
  #return:: Query condition.
  #
  def self.get_sql_like(attr_names, keyword, as=:both)

    key = SqlHelper.quote("%#{SqlHelper.escape_for_like(keyword)}%")

    escaped = SqlHelper.escape_for_like(keyword)
    key = nil
    case as.to_sym
      when :both
        key = SqlHelper.quote("%#{escaped}%")
      when :prefix
        key = SqlHelper.quote("#{escaped}%")
      when :suffix
        key = SqlHelper.quote("%#{escaped}")
    end

    con = []
    attr_names.each do |attr_name|
      con << "(#{attr_name} like #{key})"
    end
    sql = con.join(' or ')
    sql = '(' + sql + ')' if (con.length > 1)
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
