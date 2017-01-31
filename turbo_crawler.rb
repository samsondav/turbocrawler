# frozen_string_literal: true
require "kafka"
require 'redis'
require 'pry'
require 'yaml'

module TurboCrawler
  class << self
    attr_accessor :partition_count
  end

  def self.kafka
    Kafka.new(config['kafka'])
  end

  def self.redis
    Redis.new(config['redis'])
  end

  def self.log(msg)
    puts msg
  end

  def self.kafka_topic
    config['kafka_topic']
  end

  def self.kafka_partition
    rand(partition_count)
  end

  def self.redis_namespace
    config['redis_namespace']
  end

  def self.namespace_redis_key(key)
    "#{redis_namespace}:#{key}"
  end

  def self.clear_redis
    keys = redis.scan_each(match: "#{redis_namespace}:*").to_a
    redis.del(*keys) if keys.any?
  end

  def self.kafka_start_from_beginning?
    !ENV['DEBUG']
  end

  def self.config
    @config ||= YAML.load(File.open(File.expand_path("../config.yml", __FILE__)))
  end
end
