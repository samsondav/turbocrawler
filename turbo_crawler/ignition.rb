# frozen_string_literal: true
require_relative '../turbo_crawler'

module TurboCrawler
  class Ignition
    def initialize(url)
      @url = url
      @kafka = TurboCrawler.kafka
    end

    def turn_key
      @kafka.deliver_message(@url, topic: TurboCrawler.kafka_topic)
    end
  end
end
