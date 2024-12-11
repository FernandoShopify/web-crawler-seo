require 'nokogiri'
require 'open-uri'
require 'set'
require 'uri'
require 'openssl'

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

  begin
    response = URI.open(url,
      {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
      }
    )
    status = response.status[0] # Get the status code
    visited_urls.add({url: url, status: status})
    puts "#{url} - Status: #{status}"

    document = Nokogiri::HTML(response)
    links = document.css('a').map { |link| link['href'] }.compact.uniq
    links.map! { |href| absolute_url(href, base_url) }.compact!

    links.each do |link|
      next if link.nil? || visited_urls.any? { |visited| visited[:url] == link }
      scrape_urls(link, visited_urls, base_url) if same_domain?(link, base_url)
    end
  rescue OpenURI::HTTPError => e
    status = e.io.status[0] # Get the error status code
    visited_urls.add({url: url, status: status})
    puts "Failed to retrieve #{url} - Status: #{status}: #{e.message}"
  rescue StandardError => e
    visited_urls.add({url: url, status: 'error'})
    puts "Error accessing #{url}: #{e.message}"
  end
end

# Starting point
#base_url = 'https://manmadebrand.com'
base_url = 'https://experts.shopify.com/location/spain'
visited_urls = Set.new
scrape_urls(base_url, visited_urls, base_url)

# Output visited URLs with status codes to a file
File.open("all_visited_urls.txt", "w") do |file|
  visited_urls.each do |visit|
    file.puts "#{visit[:url]} - Status: #{visit[:status]}"
  end
end

puts "Scraping complete. All visited URLs have been saved to all_visited_urls.txt"