require 'mechanize'
require 'json'
agent = Mechanize.new

output = []

page = agent.get('http://monitoring.boprc.govt.nz/MonitoredSites/cgi-bin/hydwebserver.cgi/catchments/details?catchment=25')

air_links = page.search(".//map[@name='CatchmentMap']"
  ).children.map do |c|
  c.attributes['href'].value
end

air_links.each do |l|
  out = {}
  airpage = agent.get("http://monitoring.boprc.govt.nz/MonitoredSites/#{l}")
  content = airpage.search('.//div[@class="lmcontent"]').first

  title = content.search('.//h1').first.content
  out[:title] = title

  out[:info] = {}
  content.search('.//table[@cellpadding=3]//tr').each do |tr|
    th   = tr.search('./th/text()').to_s
    text = tr.search('./td//text()').to_s.strip
    if th!='Other Info:'
      out[:info][th]=text
    else
      # Other info has links, we could grab them here
    end
  end

  out[:summary] = {}
  content.search(
    './/h2[text()="Latest Summary"]/../table[@cellpadding=1]//tr/td/a/u/b/../../../..').each do |tr|
    name = tr.search('td[1]//text()').to_s
    value = tr.search('td[2]//text()').to_s
    out[:summary][name]=value
  end
  puts out
  output << out
end

open('airdata.json','w').write(output.to_json)


