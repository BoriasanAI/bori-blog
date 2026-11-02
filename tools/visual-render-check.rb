# frozen_string_literal: true

require "jekyll"
require "json"
require "nokogiri"
require "pathname"
require "uri"
require "fileutils"
require_relative "../_plugins/reader-metadata"

root = Pathname.new(ARGV[0] || "_site/bori-blog")
baseurl = "/bori-blog"
report_path = ARGV[1] || "logs/2026-11-03/reader-republication/coverage.json"
checks = 0
assert = lambda do |condition, message|
  checks += 1
  raise message unless condition
end
coverage = []
image_paths = []
pages = root.join("posts").glob("*/index.html")
pages.each do |path|
  document = Nokogiri::HTML(path.read)
  panels = document.css(".reader-visuals")
  next if panels.empty?
  assert.call(panels.size == 1, "duplicate panel: #{path}")
  assert.call(document.css(".content .reader-visuals").empty?, "visuals pollute prose: #{path}")
  schema = document.css('script[type="application/ld+json"]').map { |node| JSON.parse(node.text) }
    .find { |entry| entry["@type"] == "BlogPosting" }
  assert.call(schema && schema["wordCount"] == BoriReader.rendered_word_count(document.at_css("article .content")), "visuals alter canonical prose word count: #{path}")
  panel = panels.first
  assert.call(document.at_css("article .content").next_element == panel, "appendix must follow prose: #{path}")
  assert.call(panel.css(".rv-preview-label, .rv-outline svg").empty?, "fake previews or duplicate outline: #{path}")
  document.css(".rv-image img").each do |image|
    image_paths << image["src"]
    assert.call(image["alt"] && !image["alt"].strip.empty? && image["width"].to_i.positive? &&
      image["height"].to_i.positive? && image["loading"] == "lazy", "image accessibility or dimensions: #{path}")
    assert.call(root.join(image["src"].delete_prefix("#{baseurl}/")).file?, "missing compiled image: #{image['src']}")
    assert.call(image.ancestors("figure").first.at_css(".rv-credit"), "image attribution missing: #{path}")
  end
  panel.css(".rv-diagram h3").each do |heading|
    assert.call(!%w[outline evidence-map timeline comparison].include?(heading.text), "internal kind exposed as diagram heading: #{path}")
  end
  panel.css("a").each do |link|
    uri = URI.parse(link["href"])
    if uri.host
      assert.call(uri.scheme == "https" && link["aria-label"]&.include?("external source"), "external naming or scheme: #{path}")
      next
    end
    relative = uri.path.delete_prefix("#{baseurl}/")
    target = root.join(relative)
    target = target.join("index.html") if target.directory?
    assert.call(target.file?, "missing internal destination: #{link['href']}")
    if uri.fragment && target.file?
      target_document = target == path ? document : Nokogiri::HTML(target.read)
      assert.call(target_document.css("[id]").any? { |node| node["id"] == URI::DEFAULT_PARSER.unescape(uri.fragment) }, "missing heading target: #{link['href']}")
    end
  end
  coverage << {
    "path" => URI.parse(document.at_css('link[rel="canonical"]')["href"]).path,
    "style" => panel["class"].split.find { |css| %w[rv-paper rv-essay rv-journal].include?(css) }.delete_prefix("rv-"),
    "sources" => panel.css(".rv-source").size,
    "source_title_previews" => panel.css(".rv-preview-label").size,
    "licensed_images" => panel.css(".rv-image img").size,
    "gallery_images" => panel.css(".rv-gallery img").size,
    "outline_nodes" => panel.css(".rv-outline li").size,
    "evidence_nodes" => panel.css(".rv-evidence-map svg rect").size,
    "evidence_edges" => panel.css(".rv-evidence-map svg path").size,
    "timeline_events" => panel.css(".rv-timeline li").size,
    "comparison_rows" => panel.css(".rv-comparison tbody tr").size,
    "heading_links" => panel.css(".rv-outline a").size,
    "diagrams" => panel.css(".rv-diagram").map { |diagram| diagram["class"].split.last.delete_prefix("rv-") }
  }
end
search = JSON.parse(root.join("assets/js/data/search.json").read)
assert.call(search.none? { |record| record["content"].include?('class="reader-visuals') ||
  record["content"].include?("Sources &amp; maps / 출처와 지도") }, "supplemental rendering leaked into search")
report = {
  "rendered_posts" => pages.size, "enriched_posts" => coverage.size,
  "unenriched_posts" => pages.size - coverage.size, "styles" => coverage.group_by { |row| row["style"] }.transform_values(&:size),
  "totals" => %w[sources source_title_previews licensed_images gallery_images outline_nodes evidence_nodes evidence_edges timeline_events comparison_rows heading_links].to_h { |key| [key, coverage.sum { |row| row[key] }] },
  "unique_local_images" => image_paths.uniq.size,
  "diagram_totals" => coverage.flat_map { |row| row["diagrams"] }.tally,
  "composition_patterns" => coverage.map { |row| [row["style"], row["diagrams"].sort] }.uniq.size,
  "checks_passed" => checks, "posts" => coverage
}
FileUtils.mkdir_p(File.dirname(report_path))
File.write(report_path, JSON.pretty_generate(report) + "\n")
puts "visual-render: #{checks} checks passed"
puts JSON.generate(report.reject { |key, _| key == "posts" })
