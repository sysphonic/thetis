# rake thetis:trim_users RAILS_ENV=production

namespace :thetis do
  task :trim_users, :needs => [:environment] do
    cnt = 0
    users = User.find_all
    unless users.nil?
      users.each do |user|
        if user.login_at.nil? and user.created_at < DateTime.now - 3
          puts("#{user.name} = " + user.created_at.strftime('%Y-%m-%d %H:%M:%S'))
          user.delete
          cnt += 1
#         sleep(3) if cnt % 10 == 0
        end
      end
    end
    p cnt
  end
end
