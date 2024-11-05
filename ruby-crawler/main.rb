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
    'Cookie' => '_cmuid=752bb959-360f-4f77-bbdc-a6bc5b9d17ab; gdpr_permission_given=1; __gfp_64b=-TURNEDOFF; OptOutOnRequest=groups=googleAnalytics:1,googleAdvertisingProducts:1,tikTok:1,allegroAdsNetwork:1,facebook:1; _fbp=fb.1.1723994617476.1546036329; _meta_facebookTag_sync=1723994617476; QXLSESSID=5f108ef5dc0562df2b28577a19d78ada64a1efab155a17//01; wdctx=v5.lVWbQYQ0JG2xwARgNzVl0Loz-C4Be8ndtNpFJKErujTrUuvT0iD2Zn0NV0xQWhMOGVwX5bwCkF9tL1H_6XqJXlDfSfj4Xb7CyP2bYib6jT4_bnMvdkFQBwEtBZhl__sR374uRlf3APu6YY0NnGdqME8fzLmaHvAsd3Y_mQ3jnx0GXMWHeEXM2pYEOPamsaOzsdhin3hsIRsDRncMEUrGlAyrmHHdulaI4hWiRSThmMW1.yILOSauzQFWAuHbsmW0rXg.02Y8czyztUo; _meta_googleGtag_session_id=1730738823; parcelsChecksum=9124616b2a171ea71abf78155a26b94de2d7d68887b83b30a0d3c93e0ad529cf; _meta_googleGtag_ga_session_count=1; _meta_googleGtag_ga=GA1.2.1829968911.1730738823; _meta_googleGtag_ga_library_loaded=1730739201387; datadome=BdQ1w5z_SzhvNZ~w5X13xheAkayMoS0MSfxfXC0p0HymiU0KYM8AEjrZoU5UWFMjbkMxmOqS_0EjGsHdEYvgF77elrkBXNvVcX25CEDHmIuoMLB9FqmCv1RtNVrSuYBZ',
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
    puts "Title: #{title}" unless title.empty?
    puts "Price: #{price}" unless price.empty?
    puts "Details: #{details}" unless details.empty?

  end
end

db = setup_database

search_phrase = 'miod'
url = "https://allegro.pl/listing?string=#{search_phrase}"
fetch_html(url, db)
