#!/usr/bin/env ruby
#

require 'rubygems'
require 'mechanize'

agent = WWW::Mechanize.new
page = agent.get("http://www.dpc.nsw.gov.au/prem/lobbyist_register/static_register")
urls = page.at('table.lobbyist').search('a').map {|a| a.attributes['href']}

# Just get the first one for the time being
url = urls.first

temp_pdf = "#{File.dirname(__FILE__)}/temp.pdf"
temp_txt = "#{File.dirname(__FILE__)}/temp.txt"

File.open(temp_pdf, "w") do |f|
  f.write agent.get(url).body
end

system("pdftotext -layout #{temp_pdf} #{temp_txt}")

lobbyist = {:employees => [], :clients => []}

in_employees = false
in_clients = false

# Preprocess lines to concatenate fields across multple lines
lines = []
File.readlines(temp_txt).each do |line|
  line = line.strip
  puts "Processing line: #{line}"
  case line
  when "", "View Lobbyist Details", "Lobbyist Details"
  when /:/, "Client Details", "Details of all persons or employees who conduct lobbying activities"
    lines << line
  else
    lines[-1] += " " + line
  end
end

lines.each do |line|
  line = line.strip
  puts "Processing line: #{line}"
  case line
  when /^Business Entity Name: (.*)/
    lobbyist[:business_name] = $~[1].strip
  when /^ABN: (.*)/
    lobbyist[:abn] = $~[1].strip
  when /^Trading Name: (.*)/
    lobbyist[:trading_name] = $~[1].strip
  when "Details of all persons or employees who conduct lobbying activities"
    in_employees = true
  when /^Name: (.*)/
    if in_employees
      lobbyist[:employees] << {:name => $~[1].strip}
    elsif in_clients
      lobbyist[:clients] << {:name => $~[1].strip}
    else
      raise "Name in an unexpected place"
    end
  when /^Position: (.*)/
    if in_employees
      lobbyist[:employees].last[:position] = $~[1].strip
    else
      raise "Position in an unexexpected place"
    end
  when "Client Details"
    in_clients = true
    in_employees = false
  when /^Details last updated: (.*)/
    lobbyist[:last_updated] = $~[1].strip
  else
    raise "Don't know what to do with: #{line}"    
  end
end 

puts lobbyist.to_yaml