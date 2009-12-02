#!/usr/bin/env ruby

require 'yaml'
require 'csv'

lobbyists = YAML.load_file("#{File.dirname(__FILE__)}/lobbyists.yml")

employees = []
clients = []
owners = []

lobbyists.each do |lobbyist|
  lobbyist[:employees].each do |employee|
    employees << {:name => employee[:name], :position => employee[:position], :trading_name => lobbyist[:trading_name]}
  end
  lobbyist[:clients].each do |client|
    clients << {:name => client[:name], :trading_name => lobbyist[:trading_name]}
  end
  lobbyist[:owners].each do |owner|
    owners << {:name => owner[:name], :trading_name => lobbyist[:trading_name]}
  end
end

CSV.open('employees.csv', 'w') do |writer|
  writer << ["Name", "Position", "Lobbyist Trading Name"]
  employees.sort{|a,b| a[:name].split[-1] <=> b[:name].split[-1]}.each do |e|
    writer << [e[:name], e[:position], e[:trading_name]]
  end
end

CSV.open('clients.csv', 'w') do |writer|
  writer << ["Client Name", "Lobbyist Trading Name"]
  clients.sort{|a,b| a[:name] <=> b[:name]}.each do |c|
    writer << [c[:name], c[:trading_name]]
  end
end

CSV.open('owners.csv', 'w') do |writer|
  writer << ["Owner Name", "Lobbyist Trading Name"]
  owners.sort{|a,b| a[:name].split[-1] <=> b[:name].split[-1]}.each do |o|
    writer << [o[:name], o[:trading_name]]
  end
end

