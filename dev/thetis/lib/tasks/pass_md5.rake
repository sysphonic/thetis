# rake thetis:pass_md5 RAILS_ENV=production

namespace :thetis do
  task :pass_md5, :needs => [:environment] do
    cnt = 0
    users = User.find_all
    unless users.nil?
      users.each do |user|
        user.update_attribute(:pass_md5, UsersHelper.generate_digest_pass(user.name, user.password))
        puts("#{user.name} = " + user.pass_md5)
        cnt += 1
#       sleep(3) if cnt % 10 == 0
      end
    end
    puts(cnt)
  end
end
