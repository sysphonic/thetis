#
#= NoticeMailer
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   MIT License (See LICENSE file)
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
    @user = user
    @password = password
    @root_url = root_url
    mail(
      :from => YamlHelper.get_value($thetis_config, 'smtp.from_address', nil),
      :to => user.email,
      :subject => '[' + YamlHelper.get_value($thetis_config, 'general.app_title', nil) + '] ' + I18n.t('notification.subject.user_regist')
    )
  end

  #=== password
  #
  #Sends notification of User Account.
  #
  #_user_passwords_h_:: Hash of {User => new password}.
  #_root_url_:: Root URL.
  #
  def password(user_passwords_h, root_url)

    return if (user_passwords_h.nil? or user_passwords_h.empty?)

    @user_passwords_h = user_passwords_h
    @root_url = root_url
    mail(
      :from => YamlHelper.get_value($thetis_config, 'smtp.from_address', nil),
      :to => user_passwords_h.keys.first.email,
      :subject => '[' + YamlHelper.get_value($thetis_config, 'general.app_title', nil) + '] ' + I18n.t('notification.subject.user_account')
    )
  end

  #=== comment
  #
  #Sends notification of Arrived Message.
  #
  #_user_:: Target User.
  #_root_url_:: Root URL.
  #
  def comment(user, root_url)
    @user = user
    @root_url = root_url
    mail(
      :from => YamlHelper.get_value($thetis_config, 'smtp.from_address', nil),
      :to => user.email,
      :subject => '[' + YamlHelper.get_value($thetis_config, 'general.app_title', nil) + '] ' + I18n.t('notification.subject.message_arrived')
    )
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
    if (subject.nil? or subject.empty?)
      subject = I18n.t('notification.name')
    end
    @user = user
    @message = body
    @root_url = root_url
    mail(
      :from => YamlHelper.get_value($thetis_config, 'smtp.from_address', nil),
      :to => user.email,
      :subject => '[' + YamlHelper.get_value($thetis_config, 'general.app_title', nil) + '] ' + subject
    )
  end
end
