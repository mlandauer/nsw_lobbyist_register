#!/usr/bin/env ruby
#

require 'rubygems'
require 'mechanize'

agent = WWW::Mechanize.new
page = agent.get("http://www.dpc.nsw.gov.au/prem/lobbyist_register/static_register")
urls = page.at('table.lobbyist').search('a').map {|a| a.attributes['href']}

lobbyists = urls.map do |url|
  temp_pdf = "#{File.dirname(__FILE__)}/temp.pdf"
  temp_txt = "#{File.dirname(__FILE__)}/temp.txt"

  File.open(temp_pdf, "w") do |f|
    f.write agent.get(url).body
  end

  system("pdftotext -layout #{temp_pdf} #{temp_txt}")

  # Preprocess lines to concatenate fields across multple lines
  lines = []
  File.readlines(temp_txt).each do |line|
    line = line.strip
    puts "Processing line: #{line}"
    case line
    when "", "View Lobbyist Details", "Lobbyist Details"
    when /:/, "Client Details", "Owner Details", "Details of all persons or employees who conduct lobbying activities"
      lines << line
    else
      lines[-1] += " " + line
    end
  end

  lobbyist = {:employees => [], :clients => [], :owners => []}

  in_employees = false
  in_clients = false
  in_owners = false
  
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
      in_clients = false
      in_owners = false
    when "Client Details"
      in_employees = false
      in_clients = true
      in_owners = false
    when "Owner Details"
      in_employees = false
      in_clients = false
      in_owners = true
    when /^Name: (.*)/
      name = {:name => $~[1].strip}
      if in_employees
        lobbyist[:employees] << name
      elsif in_clients
        lobbyist[:clients] << name
      elsif in_owners
        lobbyist[:owners] << name
      else
        raise "Name in an unexpected place"
      end
    when /^Position: (.*)/
      if in_employees
        lobbyist[:employees].last[:position] = $~[1].strip
      else
        raise "Position in an unexexpected place"
      end
    when /^Details last updated: (.*)/
      lobbyist[:last_updated] = $~[1].strip
    else
      raise "Don't know what to do with: #{line}"    
    end
  end 
  lobbyist
end

File.open("#{File.dirname(__FILE__)}/lobbyists.yml", "w") do |f|
  f.write lobbyists.to_yaml
end
