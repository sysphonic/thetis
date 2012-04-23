#
#= EmailsHelper
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#Provides utility methods and constants about Email.
#
#== Note:
#
#* 
#
module EmailsHelper

  #=== self.split_preserving_quot
  #
  #Splits string preserving quotations.
  #
  #_quot_:: Quotation character.
  #_delim_:: Delimiter.
  #return:: Array of the parts.
  #
  def self.split_preserving_quot(str, quot, delim)

    return nil if str.nil?
    return str if quot.nil? or delim.nil?

    regexp = Regexp.new("([#{quot}](\\#{quot}|[^#{quot}])*[#{quot}])*#{delim}")
    ary = str.split(regexp)
    ary.collect!{|entry|
      entry.strip
    }
    return ary
  end

  #=== self.format_address_exp
  #
  #Gets E-mail address expression.
  #
  #_disp_name_:: Display name.
  #_mail_addr_:: Mail address.
  #_quoted_:: Flag to quote name.
  #return:: Mail address expression.
  #
  def self.format_address_exp(disp_name, mail_addr, quoted=true)

    if disp_name.nil? or disp_name.empty?
      return "<#{mail_addr}>"
    elsif quoted
      return "\"#{disp_name}\" <#{mail_addr}>"
    else
      return "#{disp_name} <#{mail_addr}>"
    end
  end

  #=== self.quote_message
  #
  #Gets given message in quoted format.
  #
  #_msg_:: Source message.
  #return:: Message in quoted format.
  #
  def self.quote_message(email)
    sender = EmailsHelper.get_sender_exp(email.from_address)
    return "\n\n(#{email.get_sent_at_exp}), #{sender} wrote:\n" \
           + email.message.split("\n").map!{|line| '> ' + line}.join("\n")
  end

  #=== self.extract_addr
  #
  #Gets E-mail address from E-mail address expression.
  #
  #_exp_:: E-mail address expression.
  #return:: E-mail address.
  #
  def self.extract_addr(exp)

    return nil if exp.nil?

    addr = exp.slice(/<(.+)>/, 1)
    return addr.strip unless addr.nil?

    return exp
  end

  #=== self.get_sender_exp
  #
  #Gets Sender expression of From address.
  #
  #_from_:: From address.
  #return:: Sender expression.
  #
  def self.get_sender_exp(from)

    return nil if from.nil?

    sender = from.slice(/"(.+)"\s*</, 1)
    return sender.strip unless sender.nil?

    sender = from.slice(/(.+)</, 1)
    return sender.strip unless sender.nil?

    sender = from.slice(/<(.+)>/, 1)
    return sender.strip unless sender.nil?

    return from
  end

  #=== self.encode_disp_name
  #
  #Gets encoded expression of E-mail address.
  #
  #_addr_exp_:: Target address expression.
  #return:: Encoded expression.
  #
  def self.encode_disp_name(addr_exp)

    mail_addr = addr_exp.slice(/<([^>]+)>/, 1)
    return addr_exp if mail_addr.nil?

    disp_name = addr_exp.slice(/"(.+)"\s*</, 1) \
                || addr_exp.slice(/(.+)</, 1)
    disp_name.strip! unless disp_name.nil?
    return addr_exp if disp_name.nil? or disp_name.empty?

    disp_name = Mail::Encodings.decode_encode(disp_name, :encode)

    return EmailsHelper.format_address_exp(disp_name, mail_addr)
  end
end
