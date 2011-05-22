# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

sec_file = File.join(File.dirname(__FILE__), '../_secret.conf')
sec_word = open(sec_file){ |f| f.read }.strip if File.exist?(sec_file)

if sec_word.nil? or sec_word.empty?
  chars = ("a".."z").to_a + ('A'..'Z').to_a + ("1".."9").to_a 
  sec_word = Array.new(32, '').collect{chars[rand(chars.size)]}.join
  begin
    open(sec_file, 'w') { |f| f.write(sec_word) }
  rescue StandardError => err
    puts 'ERROR: Cannot write file - ' + err.to_s
  end
end

Thetis::Application.config.secret_token = sec_word
