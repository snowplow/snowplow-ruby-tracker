#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/snowplow-tracker/version.rb" 

travis_tag = ARGV[0]

if SnowplowTracker::VERSION != travis_tag then
    STDERR.puts "Tag \"#{travis_tag}\" does not match version.rb (#{SnowplowTracker::VERSION})"
    exit 1
else
    exit 0
end