require_relative '../monzo_crawler'

class UrlSet
  attr_accessor :path, :static_assets, :internal_links

  def initialize(path, static_assets, internal_links)
    @path = path
    @static_assets = static_assets
    @internal_links = internal_links
  end

  def to_json
    {
      path: path,
      static_assets: static_assets,
      internal_links: internal_links
    }.to_json
  end
end

class Crawler
  def initialize(url)
    @redis = Redis.new
  end

  def crawl
  end

  def add_to_sitemap(url_set)
    @redis.set(url_set.path, url_set.to_json)
  end

  private

  def crawl
end
