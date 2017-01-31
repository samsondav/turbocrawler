# frozen_string_literal: true
require_relative '../turbo_crawler'
require_relative './page'
require 'httparty'

module TurboCrawler
  class Worker
    LOCK_TIMEOUT_MS = 4_000 # Must be slightly less than HTTP_TIMEOUT_MS with safety margin. This way the failure mode is to issue a duplicate request, which is better than the alternative of losing the URL.
    HTTP_TIMEOUT_MS = 5_000

    def initialize(thread_number = nil)
      @kafka = TurboCrawler.kafka
      @redis = TurboCrawler.redis
      @consumer = @kafka.consumer(group_id: kafka_group_id)
      @consumer.subscribe(kafka_topic, start_from_beginning: TurboCrawler.kafka_start_from_beginning?)
      @producer = @kafka.producer
      @thread_number = thread_number
    end

    def start
      log("INFO: Waiting for kafka message...")
      @consumer.each_message do |message|
        handle_message(message)
      end
    end

    def stop
      log "INFO: Stopping..."
      @consumer.stop
    end

    private

    # Client exceptions/crashes/failures are handled by Kafka such that every
    # URL is guaranteed to be crawled successfully at least once
    def handle_message(message)
      url = message.value
      crawl(url)
    end

    # Crawl URL, populate sitemap and add all uncrawled links to the queue
    # Return false if page was already crawled
    def crawl(url)
      redis_key = TurboCrawler.namespace_redis_key(url)

      # Lock the URL before issuing HTTP request so that other workers do not
      # issue identical (and unnecessary) HTTP requests.
      unless @redis.set(redis_key, { locked: true }.to_json, nx: true, px: LOCK_TIMEOUT_MS)
        # URLs are chucked into the frontier queue as soon as they are found.
        #
        # AFAICT Kafka does not offer any utility to check if an identical
        # message already exists in the queue.
        #
        # This means that the frontier queue may contain many duplicate URLs
        # found on different pages.
        #
        # Here the URL has already been crawled (or locked) by another worker
        # since the message was inserted. It's harmless to simply do nothing and
        # move to the next message in the queue in this case.
        log("DUP: Already crawled #{url}")
        return false
      end

      log("FETCH: Crawling #{url} ...")

      response = HTTParty.get(url, timeout: HTTP_TIMEOUT_MS / 1000)

      page = TurboCrawler::Page.new(url, response)

      log("PARSE: Got #{page.internal_links.count} links from #{url}")

      add_to_sitemap(page)
      add_to_crawl_queue(page.internal_links)
    end

    def add_to_sitemap(page)
      @redis.set(TurboCrawler.namespace_redis_key(page.url), page.to_json)
    end

    def add_to_crawl_queue(uris)
      requiring_crawl(uris).each do |uri|
        @producer.produce(uri.to_s, topic: kafka_topic, partition: TurboCrawler.kafka_partition)
      end
      @producer.deliver_messages
    end

    # Check Redis and filter out links that have already been crawled or are
    # currently being crawled (have a lock)
    def requiring_crawl(uris)
      return uris if uris.empty?
      keys = uris.map do |uri|
        TurboCrawler.namespace_redis_key(uri.to_s)
      end

      filter = @redis.multi do
        keys.each do |key|
          @redis.exists(key)
        end
      end

      apply_inverted_filter(uris, filter)
    end

    # Returns the original array with the inverted filter applied:
    #
    # apply_inverted_filter(
    #   [:a,   :b,    :c],
    #   [true, false, true]
    # ) => [:b]
    def apply_inverted_filter(keys, filter)
      keys.reject.with_index do |_k, idx|
        filter[idx]
      end
    end

    def kafka_topic
      TurboCrawler.kafka_topic
    end

    def log(msg)
      msg = "[Thread #{@thread_number}] #{msg}" if @thread_number
      TurboCrawler.log(msg)
    end

    def kafka_group_id
      TurboCrawler.config['kafka_consumers_group_id']
    end
  end
end
