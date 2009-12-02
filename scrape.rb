#!/usr/bin/env ruby
#

require 'rubygems'
require 'mechanize'

agent = WWW::Mechanize.new
page = agent.get("http://www.dpc.nsw.gov.au/prem/lobbyist_register/static_register")
urls = page.at('table.lobbyist').search('a').map {|a| a.attributes['href']}

# Just get the first one for the time being
url = urls.first

File.open("temp.pdf", "w") do |f|
  f.write agent.get(url).body
end
