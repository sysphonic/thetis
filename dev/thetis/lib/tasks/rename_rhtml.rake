# rake thetis:rename_rhtml

require "fileutils"

namespace :thetis do
  desc 'Renames all .rhtml views to .html.erb'
  task :rename_rhtml do
    Dir.glob('app/views/**/*.rhtml').each do |file|
      new_file = file.gsub(/\.rhtml$/, '.html.erb')
      FileUtils.mv(file, new_file)
    end
  end
end
