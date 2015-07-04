class ChangesForVer094 < ActiveRecord::Migration
  def self.up
    change_column :users, :birthday, :date

    users = User.find_all
    unless users.nil?
      users.each do |user|
        # Shin 2009-01-15 Comment out
        # user.update_htpasswd
      end
    end
  end

  def self.down
    change_column :users, :birthday, :datetime

    begin
      File.unlink("#{RAILS_ROOT}/config/.htpasswd")
    rescue
    end
  end
end
