# frozen_string_literal: true
require_relative 'turbo_crawler/ignition'
require_relative 'turbo_crawler/worker'
require "highline/import"

# Exceptions are not normal, we want to fail fast and loud
Thread.abort_on_exception = true

url = ask("Which URL to crawl?") do |q|
  q.default = 'http://example.com'
end

uri = URI.parse(url)
unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  abort("That's not a valid URL.")
end

worker_count = ask("How many workers?", Integer) {|q| q.default = '10' }

if agree('Erase the Redis database so we can start fresh?') {|q| q.default = 'yes' }
  TurboCrawler.clear_redis
end

TurboCrawler.partition_count = TurboCrawler.kafka.partitions_for(TurboCrawler.kafka_topic)

if worker_count > TurboCrawler.partition_count
  exit("You specified #{worker_count} workers but only #{TurboCrawler.partition_count} partitions are available for the topic. Please add more partitions.")
end

puts "Starting workers... (Ctrl-C to quit)\n\n"

workers = []

threads = Array.new(worker_count) do |n|
  Thread.new do
    worker = TurboCrawler::Worker.new(n)
    workers << worker
    worker.start
  end
end

at_exit do
  workers.each(&:stop) if defined?(workers)
  threads.each(&:join) if defined?(threads)
end

sleep 1 # Allow a little time for all threads to spin up and establish their connection to Kafka

TurboCrawler::Ignition.new(url).turn_key

sleep # Just let the threads run. There is no way to know definitely if we have finished since workers may take an arbitrarily long time to fetch a page and requeue links.
