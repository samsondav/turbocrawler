#!/usr/bin/env ruby

require_relative 'monzo_crawler/start'
require "highline/import"

url = ask "Which URL to crawl?"
worker_count = ask "How many workers?", Integer

MonzoCrawler::Ignition.new(url).turn_key

worker_count.times do
  Process.fork do
    MonzoCrawler::Consumer.start
  end
end
