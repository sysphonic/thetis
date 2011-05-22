# def index
#   respond_to do |type|
#     type.html
#     type.rss
#     type.atom
#   end
# end

xml.instruct!

xml.rss('version'    => '2.0',
        'xmlns:dc'   => 'http://purl.org/dc/elements/1.1/',
        'xmlns:atom' => 'http://www.w3.org/2005/Atom') do
  xml.channel do
    xml.title       @site_title
    xml.link        @site_url
    xml.pubDate     Time.now.rfc822
    xml.description @site_description
    xml.atom :link, 'href' => @rss_url, 'rel' => 'self', 'type' => 'application/rss+xml'

    unless @entries.nil?
      @entries.each do |entry|
        xml.item do
          xml.title        entry.title
          xml.link         entry.link
          xml.guid         entry.link
          xml.description  entry.content
          xml.pubDate      entry.updated_at.to_formatted_s(:rfc822)
          xml.dc :creator, entry.author
          if entry.has_enclosure?
            entry.enclosures.to_a.each do |feed_enclosure|
              attrs = {
                  :url => feed_enclosure.url,
                  :length => feed_enclosure.length,
                  :type => feed_enclosure.type
                }
              if @enable_custom_spec == true
                attrs[:title] = feed_enclosure.title
                attrs[:updated] = feed_enclosure.updated_at
                attrs[:digest_md5] = feed_enclosure.digest_md5
              end
              xml.enclosure(attrs)
            end
          end
        end
      end
    end
  end
end
