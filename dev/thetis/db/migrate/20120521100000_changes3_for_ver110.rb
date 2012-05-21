class Changes3ForVer110 < ActiveRecord::Migration
  def self.up
    Rake::Task['thetis:pass_md5'].invoke
  end

  def self.down
  end
end
