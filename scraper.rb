require 'nokogiri'
require 'open-uri'
require 'set'
require 'uri'

def absolute_url(url, base_url)
  begin
    URI.join(base_url, url).to_s
  rescue URI::InvalidURIError
    nil # Return nil if the URL cannot be processed.
  end
end

def same_domain?(url, base_url)
  base_host = URI.parse(base_url).host
  url_host = URI.parse(url).host
  url_host.end_with?(base_host)
rescue
  false # In case URI.parse raises an error for any malformed URI.
end

def scrape_urls(url, visited_urls, base_url)
  return if visited_urls.include?(url)
  return unless same_domain?(url, base_url)

  visited_urls.add(url)
  puts "Visiting: #{url}"

  begin
    document = Nokogiri::HTML(URI.open(url))
    links = document.css('a').map { |link| link['href'] }.compact.uniq
    links.map! { |href| absolute_url(href, base_url) }.compact!

    links.each do |link|
      next if link.nil? || visited_urls.include?(link)
      scrape_urls(link, visited_urls, base_url) if same_domain?(link, base_url)
    end
  rescue OpenURI::HTTPError => e
    puts "Failed to retrieve #{url}: #{e.message}"
  rescue StandardError => e
    puts "Error accessing #{url}: #{e.message}"
  end
end

# Starting point
base_url = 'https://manmadebrand.com'
visited_urls = Set.new
scrape_urls(base_url, visited_urls, base_url)

# Output visited URLs to a file
File.open("all_visited_urls.txt", "w") do |file|
  visited_urls.each do |url|
    file.puts url
  end
end

puts "Scraping complete. All visited URLs have been saved to all_visited_urls.txt"