#!/usr/bin/ruby -Ku
# -*- encoding: utf-8 -*-
#

require 'yaml'
require_relative 'rakutenbank'

account = YAML.load_file('rakutenbank_account.yaml')
rakutenbank = RakutenBank.new

# login
unless rakutenbank.login(account)
  puts 'LOGIN ERROR'
  exit
end

begin
  puts 'total: ' + rakutenbank.total_balance.to_s
  rakutenbank.recent.each do |row|
    p row
  end

ensure
  # logout
  rakutenbank.logout
end
