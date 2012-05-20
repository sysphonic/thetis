#
#= NoticeMailer
#
#Original by::   Sysphonic
#Authors::   MORITA Shintaro
#Copyright:: Copyright (c) 2007-2011 MORITA Shintaro, Sysphonic. All rights reserved.
#License::   New BSD License (See LICENSE file)
#URL::   {http&#58;//sysphonic.com/}[http://sysphonic.com/]
#
#NoticeMailer sends E-mails to Users.
#
#== Note:
#
#* 
#
class NoticeMailer < ActionMailer::Base

  #=== welcome
  #
  #Sends notification of User Registration.
  #
  #_user_:: Target User.
  #_password_:: Password.
  #_root_url_:: Root URL.
  #
  def welcome(user, password, root_url)
    @subject    = '[' + $thetis_config[:general]['app_title'] + '] ' + I18n.t('notification.subject.user_regist')
    @body['user']  = user
    @body['password']  = password
    @body['root_url']  = root_url
    @recipients = user.email
    @from        = $thetis_config[:smtp]['from_address']
  end

  #=== password
  #
  #Sends notification of User Account.
  #
  #_user_passwords_h_:: Hash of {User => new password}.
  #_root_url_:: Root URL.
  #
  def password(user_passwords_h, root_url)

    return if user_passwords_h.nil? or user_passwords_h.empty?

    @subject    = '[' + $thetis_config[:general]['app_title'] + '] ' + I18n.t('notification.subject.user_account')
    @body['user_passwords_h']  = user_passwords_h
    @body['root_url']  = root_url
    @recipients = user_passwords_h.keys.first.email
    @from       = $thetis_config[:smtp]['from_address']
  end

  #=== comment
  #
  #Sends notification of Arrived Message.
  #
  #_user_:: Target User.
  #_root_url_:: Root URL.
  #
  def comment(user, root_url)
    @subject    = '[' + $thetis_config[:general]['app_title'] + '] ' + I18n.t('notification.subject.message_arrived')
    @body['user']  = user
    @body['root_url']  = root_url
    @recipients = user.email
    @from       = $thetis_config[:smtp]['from_address']
  end

  #=== notice
  #
  #Sends notification of various situations.
  #
  #_user_:: Target User.
  #_subject_:: Subject of the E-mail.
  #_body_:: Message body of the E-mail.
  #_root_url_:: Root URL.
  #
  def notice(user, subject, body, root_url)
    if subject.nil? or subject.empty?
      subject = I18n.t('notification.name')
    end
    @subject    = '[' + $thetis_config[:general]['app_title'] + '] ' + subject
    @body['user']  = user
    @body['message']  = body
    @body['root_url']  = root_url
    @recipients = user.email
    @from       = $thetis_config[:smtp]['from_address']
  end
end
