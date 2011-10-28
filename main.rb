#!/bin/env ruby

require "rubygems"
require "./rate_converter.rb"
require "./transactions.rb"

rc = RateConverter.new(File.open(ARGV[0]))
puts rc.to_s
t = Transactions.new(File.open(ARGV[1]), rc)
puts t.total_sale_of1("DM1182")
