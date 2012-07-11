# rake thetis:sort_users RAILS_ENV=production

namespace :thetis do
  task :sort_users do
    groups ={}
    ('A'..'Z').to_a.each do |group_name|
      groups[group_name] = Group.find(:first, :conditions => "name='#{group_name}'")
    end
    extra_group = Group.find(:first, :conditions => "name='0-9'")

    groups_cache = {}

    cnt = 0
    users = User.find(:all, :conditions => 'groups is null')
    unless users.nil?
      users.each do |user|
        group = groups[user.name[0, 1].upcase]
        if group.nil?
          group = extra_group
        end
        next if group.nil?

        puts(user.name + ' ==> ' + group.get_path(groups_cache))
        user.update_attributes({:groups => "|#{group.id}|"})

        cnt += 1
        sleep(1) if cnt % 10 == 0
      end
    end
    puts cnt
  end
end
