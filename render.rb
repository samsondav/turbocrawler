require_relative './turbo_crawler/renderer'
require 'json'

print JSON.pretty_generate(TurboCrawler::Renderer.new.render)
