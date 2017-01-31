# frozen_string_literal: true
require_relative '../turbo_crawler/page'

class MockResponse
  attr_reader :headers, :code

  def initialize(headers = { 'Content-Type' => 'text/html' }, code = 200)
    @headers = headers
    @code = code
  end

  def body
    <<~HTML
      <a href="http://example.com/foo/bar.html" />
      <a href="https://google.com" />
      <a href="https://example.com/baz.png" />
      <a href="/qux/oggly.png" />
      <script src="javascript:void(0);" />
      <img src='/hello.png' />
      <script>void(0);</script>
      <script src="/example.js"></script>
      <link href="http://example.com/linktag.htm" />
    HTML
  end
end

RSpec.describe TurboCrawler::Page do
  let(:url) { 'http://example.com' }
  let(:page) do
    described_class.new(url, MockResponse.new)
  end

  describe 'internal_links' do
    let(:internal_links_strings) { page.internal_links.map(&:to_s) }

    it 'returns an array of URI' do
      expect(page.internal_links).to all be_a URI
    end

    it 'extracts <a> tags' do
      expect(internal_links_strings).to include("http://example.com/foo/bar.html")
    end

    it 'extracts urls on same site even for different scheme' do
      expect(internal_links_strings).to include("https://example.com/baz.png")
    end

    it 'extracts relative paths' do
      expect(internal_links_strings).to include("http://example.com/qux/oggly.png")
    end

    it 'ignores foreign urls' do
      expect(internal_links_strings).not_to include("https://google.com")
    end
  end

  describe 'static_asset_links' do
    let(:static_asset_links_strings) { page.static_asset_links.map(&:to_s) }

    it 'extracts <img> tags' do
      expect(static_asset_links_strings).to include("http://example.com/hello.png")
    end

    it 'extracts url from <script> tags' do
      expect(static_asset_links_strings).to include("http://example.com/example.js")
    end

    it 'extracts url from <link> tags' do
      expect(static_asset_links_strings).to include("http://example.com/linktag.htm")
    end
  end
end
