# rake thetis:email_ver110 RAILS_ENV=production

namespace :thetis do
  task :email_ver110 do
    Email.find(:all).each do |email|
      attrs = {}

      [:to_addresses, :cc_addresses, :bcc_addresses, :reply_to].each do |attr|
        addrs = email.send(attr)
        if !addrs.nil? \
            and !addrs.include?(Email::ADDRESS_SEPARATOR) \
            and addrs.match(/(["](\"|[^"])*["])*,/)
          addrs = EmailsHelper.split_preserving_quot(addrs, '"', ',')
          attrs[attr] = addrs.join(Email::ADDRESS_SEPARATOR)
        end
      end
      if email.size.nil?
        # Force to recalcurate size
        attrs[:updated_at] = email.updated_at
      end
      email.update_attributes(attrs) unless attrs.empty?

      path = email.get_dir
      filepaths = Dir.glob([File.join(path, '*')].join("\0"))
      unless filepaths.nil?
        filepaths.each do |filepath|
          next if filepath.match(/[.]eml/)

          m = filepath.scan(/[\\\/]([0-9]+)([.][^\\\/]*)*$/)
          unless m.nil?
            m.each do |entry|
              mail_attach_id = entry[0]
              mail_attach = MailAttachment.find_by_id(mail_attach_id)
              if mail_attach.nil?
                FileUtils.rm(filepath, {:force => true})
                puts('REMOVED: ' + filepath)
              end
            end
          end
        end
      end
    end
  end
end
