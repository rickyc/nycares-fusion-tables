require 'rubygems'
require 'mechanize'
require 'geokit'


# login
mech = Mechanize.new
page = mech.get('http://www.newyorkcares.org/')
form = page.form_with(id: 'user-login-form')
form['name'] = ENV['NYCARES_USERNAME']
form['pass'] = ENV['NYCARES_PASSWORD']
form.submit

# geokit
Geokit::Geocoders::google = ENV['GOOGLE_API_KEY']

# parser
BASE_URL = 'http://www.newyorkcares.org/search/project/results?page='
@continue_parse = true
@page = 0

while @continue_parse do
  doc = mech.get("#{BASE_URL}#{@page}").parser
  data = []

  @continue_parse = false

  container = doc.xpath('//*[@id="project-search-results"]/div[2]/div[2]/div/div/div')
  container.each do |node|
    @continue_parse = true
    project_title = node.xpath(".//div[@class='field-title']/a")
    url = project_title[0].attributes['href'].value
    project_url = "http://newyorkcares.org#{url}"
    hsh = { url: project_url }

    project_page = mech.get(project_url)
    parser = project_page.parser

    hsh[:title] = parser.xpath('//*[@id="page-title"]').inner_html
    hsh[:description] = parser.xpath('.//div[@class="field-description"]').inner_html

    signup_time_node = parser.xpath('.//div[@class="signup-time-item"]')
    project_date = signup_time_node.xpath('.//div[@class="date"]').text.split(' - ')
    project_time = signup_time_node.xpath('.//div[@class="time"]').text.split(' - ')

    hsh[:start_date] = DateTime.parse("#{project_date.first} #{project_time.first}")
    hsh[:end_date] = DateTime.parse("#{project_date.last} #{project_time.last}")
    hsh[:spots_remaining] = parser.xpath('.//div[@class="spots"]/span[@class="spot-number"]').first.text || 0
    hsh[:team_leader] = parser.xpath('.//div[@class="field-team-leader"]//div[@class="group-right"]').text.strip.gsub(/\n/, '').split(' ').join(' ')

    hsh[:partner] = parser.xpath('.//div[@class="field-partner"]//div[@class="field-title"]').text
    hsh[:partner_description] = parser.xpath('.//div[@class="field-partner"]//div[@class="field-body"]').inner_html
    hsh[:location] = parser.xpath('.//div[@class="simple-gmap-address"]').text

    geo = Geokit::Geocoders::Google3Geocoder.geocode hsh[:location]
    lat_long = geo.ll.split(',')
    hsh[:latitude] = lat_long[0]
    hsh[:longitude] = lat_long[1]
    hsh[:created_at] = Time.now

    data << hsh
  end

  @page += 1
end
