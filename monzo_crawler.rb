require "kafka"

module MonzoCrawler
  TOPIC = 'frontier-queue'

  def self.kafka
    @kafka ||= Kafka.new(seed_brokers: ["localhost:9092"])
  end
end
