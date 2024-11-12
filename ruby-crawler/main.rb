require 'nokogiri'
require 'net/https'
require 'uri'
require 'sqlite3'
require 'zlib'
require 'stringio'
require 'sequel'
require 'json'

# Setup SQLite3 database using Sequel
def setup_database
  db = Sequel.sqlite('products.db') # Create or open the SQLite database

  # Create a products table if it doesn't exist
  unless db.table_exists?(:products)
    db.create_table :products do
      primary_key :id
      String :title
      String :price
      String :link
      Json :details
    end
  end

  db
end

def insert_product(db, title, price, link, json)
  db[:products].insert(title: title, price: price, link: link, details: json)
end

def setup_request_headers
  {
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Encoding' => 'gzip, deflate, br, zstd',
    'Accept-Language' => 'pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7',
    'Cache-Control' => 'no-cache',
    'Cookie' => '_cmuid=eea113d4-7fac-4514-a715-57610daabad9; wdctx=v5.M5jQ0j7yW8Ej5ZsfTib3XtonZH3BVtRTN2kBUyoG-T1RiQ_QJ9ZP9DI8wqSE4H202dFQnpzNKWJh9DM57WW_kM9DTme3xBdeaGLI6X_T6mDD1wlDqNqGcUMPSqaA68exKGesMxm8oHIG9Xr1at8NcKwYdLgeoGYf_ojTMd3cDxnJozJcRSwyGehMrJOVZKR0OE2l770XfxsC9I0L9p73ARuuWqqHql7cWYpnoAPQm-29.RJ1bPrgXQrCqYSuvRsjd8Q.HsFwJK4AYFI; OptOutOnRequest=groups=googleAnalytics:0,googleAdvertisingProducts:0,tikTok:0,allegroAdsNetwork:0,facebook:0; _gcl_au=1.1.2014488935.1731429839; gdpr_permission_given=1; _ga=GA1.1.1552461072.1731429839; _ga_G64531DSC4=GS1.1.1731429838.1.0.1731429838.60.0.0; __gfp_64b=E36A_vWcdCzs2oN0Wjnq7zm9OZCKakxa5FHHeafRPW..E7|1731429832|2; datadome=RxxMkuM6tBsmQmBX3EzvTA_ko2A9N6lKAk25xG4EBBqOwGte3y8XlipbnJvcsoCouB1Gm6HsVQmlAn0mReRUSNXzXQz8P0zSpEgjadZKqf~MnjDva_tzGKBdhHb0VHwX',
    'DPR' => '1',
    'Pragma' => 'no-cache',
    'Sec-CH-UA' => '"Chromium";v="130", "Google Chrome";v="130", "Not?A_Brand";v="99"',
    'Sec-CH-UA-Arch' => '"x86"',
    'Sec-CH-UA-Full-Version-List' => '"Chromium";v="130.0.6723.92", "Google Chrome";v="130.0.6723.92", "Not?A_Brand";v="99.0.0.0"',
    'Sec-CH-UA-Mobile' => '?0',
    'Sec-CH-UA-Model' => '""',
    'Sec-CH-UA-Platform' => '"Windows"',
    'Sec-CH-Viewport-Height' => '1057',
    'Sec-Fetch-Dest' => 'document',
    'Sec-Fetch-Mode' => 'navigate',
    'Sec-Fetch-Site' => 'none',
    'Sec-Fetch-User' => '?1',
    'Upgrade-Insecure-Requests' => '1',
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
    'Viewport-Width' => '768'
  }
end

def fetch_html_content(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")
  request = Net::HTTP::Get.new(uri.request_uri)
  setup_request_headers.each do |key, value|
    request[key] = value
  end
  response = http.request(request)
  case response['content-encoding']
  when 'gzip'
    Zlib::GzipReader.new(StringIO.new(response.body)).read
  else
    response.body
  end
end

def fetch_html(url, db)
  html_content = fetch_html_content(url)

  if html_content
    parse_html(html_content, db)
  else
    puts "Failed to retrieve the HTML content."
  end
end

def fetch_and_return_product_details(link)
  full_url = "#{link}"
  product_html = fetch_html_content(full_url)

  if product_html
    doc = Nokogiri::HTML(product_html)
    table = doc.at_css('table')

    if table
      product_details = {}

      rows = table.css('tr')
      rows.each do |row|
        tds = row.css('td')

        if tds.size == 2
          key = tds[0].text.strip
          value = tds[1].text.strip
          product_details[key] = value
        else
          puts "Row does not have exactly 2 columns."
        end
      end

      return JSON.generate(product_details)
    else
      puts "No table found for this product."
      return nil
    end
  else
    puts "Failed to retrieve the product detail page."
    nil
  end
end

def parse_html(html, db)
  doc = Nokogiri::HTML(html)
  items = doc.css('article')
  items.each do |item|
    title_element = item.at_css('.mgn2_14')
    title = title_element ? title_element.text.strip : nil
    price_element = item.at_css('.mli8_k4.mgmw_qw')
    price = price_element ? price_element.text.strip : nil
    link_element = item.at_css('a')
    link = link_element ? link_element['href'] : nil
    next if title.nil? || price.nil? || link.nil?
    next unless link.include?("/oferta/")

    details = fetch_and_return_product_details(link)

    insert_product(db, title, price, link, details)
    puts "Title: #{title}" unless title.to_s.empty?
    puts "Price: #{price}" unless price.to_s.empty?
    puts "Details: #{details}" unless details.to_s.empty?

    sleep 1
  end
end

db = setup_database

search_phrase = 'miod'
url = "https://allegro.pl/listing?string=#{search_phrase}"
fetch_html(url, db)
