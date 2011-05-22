# def index
#   respond_to do |type|
#     type.html
#     type.rss
#     type.atom
#   end
# end

atom_feed(:root_url => @site_url,
          :url      => @atom_url,
          :id       => @site_url) do |feed|
  feed.title    @site_title
  feed.subtitle @site_description
  feed.updated  Time.now
  feed.author{|author| author.name(@author) }

  @entries.each do |entry|
    feed.entry(entry,
               :url       => entry.link,
               :id        => entry.link,
               :published => entry.created_at,
               :updated   => entry.updated_at) do |item|
      item.title(entry.title)
      item.content(entry.content, :type => 'html')
      item.author{|author| author.name(entry.author) }
      if entry.has_enclosure?
        entry.enclosures.to_a.each do |feed_enclosure|
          attrs = {
              :rel => 'enclosure',
              :href => feed_enclosure.url,
              :length => feed_enclosure.length,
              :type => feed_enclosure.type,
              :title => feed_enclosure.title
            }
          if @enable_custom_spec == true
            attrs[:updated] = feed_enclosure.updated_at
            attrs[:digest_md5] = feed_enclosure.digest_md5
          end
          item.link(attrs)
        end
      end
    end
  end
end
