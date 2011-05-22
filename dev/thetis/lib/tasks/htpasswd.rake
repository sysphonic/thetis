# rake thetis:htpasswd RAILS_ENV=production

namespace :thetis do
  task :htpasswd, :needs => [:environment] do
    begin
      File.unlink("#{RAILS_ROOT}/config/_htpasswd.conf")
    rescue
    end

    users = User.find_all
    unless users.nil?
      users.each do |user|
        user.update_htpasswd
      end
    end
  end
end
