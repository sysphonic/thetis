class ChangesForVer094x3 < ActiveRecord::Migration
  def self.up
    users = User.find_all
    unless users.nil?
      users.each do |user|
        # Shin 2008-12-15 Comment out
        # user.update_htpasswd
      end
    end
    begin
      File.unlink("#{RAILS_ROOT}/config/.htpasswd")
    rescue
    end
  end

  def self.down
  end
end
