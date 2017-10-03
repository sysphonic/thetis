# rake thetis:email_trim_content_type RAILS_ENV=production THETIS_DATABASE_PASSWORD=

namespace :thetis do

  task(:email_trim_content_type => :environment) do

    MailAttachment.all.each do |mail_attachment|
      content_type = EmailsHelper.trim_content_type(mail_attachment.content_type)
      mail_attachment.update_attribute(:content_type, content_type)
    end
  end
end

