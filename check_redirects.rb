=begin
require 'csv'
require 'net/http'
require 'uri'

def check_redirect_status(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)

  # Handle redirections
  if response.is_a?(Net::HTTPRedirection) && response.code == "301"
    { status: '301', redirect_to: response['location'] }
  else
    { status: response.code, redirect_to: nil }
  end
rescue => e
  puts "Failed to retrieve #{url}: #{e.message}"
  { status: 'error', redirect_to: nil }
end

def process_csv(input_file, output_file)
  CSV.open(output_file, 'wb', headers: true) do |csv_out|
    CSV.foreach(input_file, headers: true) do |row|
      result = check_redirect_status(row['URL'])
      row['Status Code'] = result[:status]
      row['Redirect To'] = result[:redirect_to]
      csv_out << row
    end
  end
end

# Replace 'input.csv' and 'output.csv' with your actual file paths.
process_csv('Hack Days scraping - Sheet1 (1).csv', 'output.csv')
=end
require 'csv'
require 'net/http'
require 'uri'

# Function to check the HTTP status and handle redirection
def check_redirect_status(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)

  # Check if the response is a redirection and capture the new location if it is
  if response.is_a?(Net::HTTPRedirection)
    { status: response.code, redirect_to: response['location'] }
  else
    { status: response.code, redirect_to: nil }
  end
rescue => e
  puts "Failed to retrieve #{url}: #{e.message}"
  { status: 'error', redirect_to: nil }
end

# Function to process the input CSV and produce an output CSV with HTTP status and redirect URLs
def process_csv(input_file, output_file)
  CSV.open(output_file, 'wb', headers: true) do |csv_out|
    # Read the input CSV, adding headers on the fly if they are not present
    CSV.foreach(input_file, headers: true) do |row|
      result = check_redirect_status(row['URL'])
      row['Status Code'] = result[:status]
      row['Redirect To'] = result[:redirect_to]
      csv_out << row
    end
  end
end

# Replace 'input.csv' and 'output.csv' with your actual file paths
process_csv('Hack Days scraping - Sheet1 (1).csv', 'output.csv')