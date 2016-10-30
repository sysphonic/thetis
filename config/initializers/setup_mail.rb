ActionMailer::Base.smtp_settings = {
=begin
  :address              => 'localhost',
  :port                 => 587,
  :domain               => 'localhost.localdomain',
  :user_name            => 'thetis@example.com',
  :password             => 'xxxxxxxx',
  :authentication       => :cram_md5,

  :enable_starttls_auto => true,
  :openssl_verify_mode => 'none'
=end

  :address => YamlHelper.get_value($thetis_config, 'smtp.server', nil),
  :port => YamlHelper.get_value($thetis_config, 'smtp.port', nil).to_i,
  :domain => YamlHelper.get_value($thetis_config, 'smtp.domain', nil)
}

if YamlHelper.get_value($thetis_config, 'smtp.auth_enabled', nil) == '1'
  ActionMailer::Base.smtp_settings[:authentication] = YamlHelper.get_value($thetis_config, 'smtp.auth', nil).to_sym
  ActionMailer::Base.smtp_settings[:user_name] = YamlHelper.get_value($thetis_config, 'smtp.user_name', nil)
  ActionMailer::Base.smtp_settings[:password] = YamlHelper.get_value($thetis_config, 'smtp.password', nil)
end
if YamlHelper.get_value($thetis_config, 'smtp.starttls', nil) == '1'
  ActionMailer::Base.smtp_settings[:enable_starttls_auto] = true
  ActionMailer::Base.smtp_settings[:openssl_verify_mode] = 'none'
end

ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.default(:charset => 'utf-8')

