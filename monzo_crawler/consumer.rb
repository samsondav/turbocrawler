require 'httparty'

module MonzoCrawler
  class Consumer
    def start
      MonzoCrawler.kafka.each_message(topic: MonzoCrawler::TOPIC) do |message|
        puts message.offset, message.key, message.value
      end
    end
  end
end
