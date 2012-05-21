# rake thetis:pass_md5 RAILS_ENV=production

namespace :thetis do
  task :pass_md5, :needs => [:environment] do
    cnt = 0
    users = User.find_all
    unless users.nil?
      users.each do |user|
        break unless user.respond_to?(:password)
        next if user.password.nil?
        attrs = {
          :password => nil,
          :pass_md5 => UsersHelper.generate_digest_pass(user.name, user.password)
        }
        user.update_attributes(attrs)
        puts("#{user.name} = " + user.pass_md5)
        cnt += 1
#       sleep(3) if cnt % 10 == 0
      end
    end
    puts(cnt)
  end
end
