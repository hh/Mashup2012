require 'mechanize'
require 'yaml'
agent = Mechanize.new

# page = agent.get('http://monitoring.boprc.govt.nz/MonitoredSites/cgi-bin/hydwebserver.cgi/catchments/details?catchment=25')
# map= page.search(".//map[@name='CatchmentMap']")

# links = map.children.map do |c|
#   [c.attributes['title'].value,c.attributes['href'].value]
# end

course_list_page = agent.get('http://www.boppoly.ac.nz/go/programmes-courses')
course_links = course_list_page.links.find_all { |l| l.href.start_with? '/go/programmes-and-courses/' }.map {|l| l.href }

output={}
course_links.each do |l|
  shortname = l.split('/')[-1]
  c_page = agent.get("http://www.boppoly.ac.nz#{l}")
  name = c_page.search('.//div[@id="content"]').first.children[0].text
  text = c_page.search('.//div[@class="article article2"]').first.children[4].text
  output[shortname] = {
    :name => name,
    :url => "http://www.boppoly.ac.nz#{l}",
    :desc => text
  }
end

open('classes.yml','w').write(output.to_yaml)

# <map name="CatchmentMap"><AREA

