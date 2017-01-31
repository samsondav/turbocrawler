# frozen_string_literal: true
require_relative '../turbo_crawler'
require 'json'

module TurboCrawler
  class Renderer
    def initialize
      @redis = TurboCrawler.redis
    end

    def render
      keys = @redis.scan_each(match: "#{TurboCrawler.redis_namespace}:*").to_a
      pages = @redis.mget(*keys)

      pages.map do |page|
        JSON.parse(page)
      end
    end
  end
end
