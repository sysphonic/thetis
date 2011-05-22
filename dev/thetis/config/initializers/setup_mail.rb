ActionMailer::Base.smtp_settings = {
=begin
  :address              => 'localhost',
  :port                 => 587,
  :domain               => 'localhost.localdomain',
  :user_name            => 'thetis@example.com',
  :password             => 'xxxxxxxx',
  :authentication       => :cram_md5,
  :enable_starttls_auto => false
=end

  :address => $thetis_config[:smtp]['server'],
  :port => $thetis_config[:smtp]['port'].to_i,
  :domain => $thetis_config[:smtp]['domain'],
}

if $thetis_config[:smtp]['auth_enabled'] == '1'
  ActionMailer::Base.smtp_settings[:authentication] = $thetis_config[:smtp]['auth'].to_sym
  ActionMailer::Base.smtp_settings[:user_name] = $thetis_config[:smtp]['user_name']
  ActionMailer::Base.smtp_settings[:password] = $thetis_config[:smtp]['password']
end

ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.default_charset = "utf-8"

