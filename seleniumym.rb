ENV["SSL_CERT_FILE"] = "./cacert.pem"

require 'selenium-webdriver' 
require 'open-uri'
require 'csv'
 


bom = %w(EF BB BF).map { |e| e.hex.chr }.join
csv_file = CSV.generate(bom) do |csv|
    csv << ["Title","Url","Hatebu","Image"]
end

opt = {}
opt['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/XXXXXXXXXXXXX Safari/XXXXXX Vivaldi/XXXXXXXXXX'


File.open("result.csv", "w") do |file|
    file.write(csv_file)
end

FileUtils.mkdir_p("./images") unless FileTest.exist?("./images")

d = Selenium::WebDriver.for :chrome
wait = Selenium::WebDriver::Wait.new(:timeout => 10)

d.get('https://uxmilk.jp/')

urls = []
loop do
    wait.until { d.find_elements(:class, 'u-mTop3').size > 0 }
    d.find_elements(:class, 'u-mTop3').each do |mTop3|
        urls << mTop3.find_element(:class, 'u-txtBold').attribute("href")
    end
    break
    if d.find_elements(:xpath, '//*[@class="pagination__item larger"]').size > 0
     d.find_element(:xpath, '//*[@class="pagination__item larger"]').click
    else
        break
    end
end

i = 1
urls.each do |url|
    begin
        d.get(url)
    rescue
        begin
            d.quit
        rescue
        end
        d = Selenium::WebDriver.for :chrome
        retry
    end            

    title = d.find_element(:id, 'js-articleTop').text
    url = d.current_url
    wait.until{ d.find_elements(:xpath, '//*[@class="share__btn share__btn--hatena"]').size > 0 }
    begin
        hatebu = d.find_elements(:class, 'share__item')[2].find_element(:class, 'share__count').text
    rescue
        hatebu = 0
    end

    wait.until { d.find_elements(:class, 'author__image').size > 0 }
    image_url = d.find_element(:class, 'author__image').find_element(:tag_name, 'img').attribute("src")
    open("./images/#{i}.jpg", 'wb') do |output|
        open(image_url,opt) do |data|
            output.write(data.read)
        end
    end
    i += 1
     
    CSV.open("result.csv", "a") do |file|
        file << [title, url, hatebu, "#{i}.jpg"]
    end
end 

