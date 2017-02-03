# frozen_string_literal: true
require 'nokogiri'

module TurboCrawler
  class Page
    TAGS = %w(link script img a).freeze

    attr_accessor :original_uri, :internal_links, :static_asset_links

    def initialize(url, response)
      @original_uri = URI(url)
      @internal_links = Set.new
      @static_asset_links = Set.new
      @response = response
      if html? && ok?
        @html = Nokogiri::HTML(@response.body)
        extract_internal_links_and_static_assets
      end
    end

    def url
      @original_uri.to_s
    end

    def status_code
      @response.code
    end

    def to_h
      {
        url: url,
        status_code: status_code,
        internal_links: internal_links.to_a,
        static_asset_links: static_asset_links.to_a
      }
    end

    def to_json
      to_h.to_json
    end

    private

    def extract_internal_links_and_static_assets
      TAGS.each do |tag|
        @html.css(tag).each do |el|
          attr_name =
            case el.name
            when 'a', 'link'
              'href'
            else
              'src'
            end

          path = el.attributes[attr_name]&.value

          next unless path # probably a script tag with no url

          begin
            uri = normalize(URI(path))
          rescue URI::InvalidURIError
            next # it claimed to be a URL, but in actual fact was not
          end

          if tag == 'a'
            @internal_links << uri if uri.host == @original_uri.host
          else
            @static_asset_links << uri
          end
        end
      end
    end

    def normalize(uri)
      uri.host = @original_uri.host if uri.host.nil? # it's a relative path, normalize to full URL
      uri.scheme = @original_uri.scheme if uri.scheme.nil?
      uri
    end

    def html?
      @response.headers['Content-Type'].match?(%r{text/html})
    end

    def ok?
      @response.code == 200
    end
  end
end
