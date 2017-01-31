require_relative '../monzo_crawler'

module MonzoCrawler
  class Ignitiion
    def initialize(url)
      @url = url
      @kafka = MonzoCrawler.kafka
    end

    def turn_key
      @kafka.deliver_message(url, topic: MonzoCrawler::TOPIC)
    end
  end
end

