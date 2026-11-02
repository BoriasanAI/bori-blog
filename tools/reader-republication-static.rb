# frozen_string_literal: true

require "jekyll"
require "json"
require "nokogiri"
require "pathname"
require_relative "../_plugins/reader-metadata"

root = Pathname.new(ARGV.fetch(0, "_site/bori-blog"))
checks = 0
assert = lambda do |condition, message|
  checks += 1
  raise message unless condition
end
pages = root.join("posts").glob("*/index.html")
assert.call(pages.any?, "built articles are required")
pages.each do |path|
  document = Nokogiri::HTML(path.read)
  content = document.at_css("article .content")
  assert.call(content, "#{path}: canonical article prose is missing")
  schemas = document.css('script[type="application/ld+json"]').map { |node| JSON.parse(node.text) }
    .select { |data| data.is_a?(Hash) && data["@type"] == "BlogPosting" }
  assert.call(schemas.size == 1 && schemas.first["wordCount"] == BoriReader.rendered_word_count(content), "#{path}: one canonical schema with rendered-prose word count")
  assert.call(document.css("article header img").none? { |image| image["src"].to_s.match?(%r{/assets/img/avatar/bori-(?:presence-avatar|avatar)\.}) }, "#{path}: generic avatar hero")
  assert.call(document.css(".rv-outline svg, .rv-preview-label, .rv-image img[src*='visual-reference-']").empty?, "#{path}: duplicate outline or fake title-cover image")
  assert.call(content.css(".reader-visuals").empty?, "#{path}: appendix must stay outside canonical prose")
  document.css(".reader-visuals").each do |panel|
    assert.call(panel.previous_element == content, "#{path}: appendix must follow prose")
  end
  document.css(".rv-image").each do |figure|
    image = figure.at_css("img")
    assert.call(image && figure.at_css("a.rv-original")&.[]("href") == image["src"] && image["width"].to_i.positive? &&
      image["height"].to_i.positive? && figure.css(".rv-credit").size == 1, "#{path}: original figure link, dimensions and single attribution")
  end
  content.css("table").each do |table|
    assert.call(table.at_css("caption") && table.css("thead th").all? { |cell| cell["scope"] == "col" } &&
      table.css("tbody tr").all? { |row| row.element_children.first&.matches?('th[scope="row"]') }, "#{path}: table caption and header scopes")
  end
  if document.at_css(".comments-unavailable")
    assert.call(document.css("script[src*='giscus.app'], iframe.giscus-frame").empty?, "#{path}: unavailable comments cannot load giscus")
  end
end
css = root.join("assets/css/jekyll-theme-chirpy.css").read
assert.call(css.include?("data-bs-theme") && css.include?("dark") &&
  css.scan(/--main-bg\s*:\s*([^;}]+)/).flatten.uniq.size >= 2, "compiled Chirpy CSS must contain both palettes")
puts "reader-republication-static: #{checks} checks passed across #{pages.size} articles"
