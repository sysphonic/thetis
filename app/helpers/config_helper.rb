#
#= ConfigHelper
#
#Copyright::(c)2007-2019 MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
#License::   New BSD License (See LICENSE file)
#
module ConfigHelper

  #=== self.save_img
  #
  #Saves image file.
  #
  #_file_name_:: File name.
  #_file_:: File data.
  #
  def self.save_img(file_name, file)

    path = Rails.root.to_s + '/public/images/custom/' + file_name

    mode = ApplicationHelper.f_chmod(0666, path)
    File.open(path, 'wb') { |f| f.write(file.read) }
    ApplicationHelper.f_chmod(mode, path)
  end

  #=== self.save_html
  #
  #Saves HTML file.
  #
  #_file_name_:: File name.
  #_file_:: File data.
  #
  def self.save_html(file_name, file)

    path = Rails.root.to_s + '/public/custom/' + file_name

    mode = ApplicationHelper.f_chmod(0666, path)
    File.open(path, 'wb') { |f| f.write(file.read) }
    ApplicationHelper.f_chmod(mode, path)
  end
end
