# frozen_string_literal: true

require "json"
require "nokogiri"
require "pathname"
require "time"
require "uri"
require "jekyll"
require_relative "../_plugins/reader-metadata"

root = Pathname.new(ARGV.first || "_site/bori-blog")
def html(path)
  Nokogiri::HTML(File.read(path))
end
def check(condition, message)
  raise message unless condition
end

def section_body?(heading)
  node = heading.next_element
  while node
    break if %w[h1 h2].include?(node.name)
    unless node.name.match?(/\Ah[3-6]\z/)
      return true unless node.text.strip.empty?
      return true if %w[img svg pre blockquote].include?(node.name) || node.at_css("img, svg, pre, blockquote")
    end
    node = node.next_element
  end
  false
end

home = html(root.join("index.html"))
dashboard = html(root.join("dashboard/index.html"))
tags = html(root.join("tags/index.html"))
check(dashboard.at_css("title").text.include?("Dashboard"), "Dashboard title must be named")
check(home.css(".start-grid article").size.positive?, "Start-here needs real posts")
check(home.css("#post-list article").size == 10, "Home pagination must preserve 10 cards")
check(home.at_css(".card-text").text.size > 30, "Summaries must not collapse to ellipses")
check(home.css(".skip-link").size == 1 && home.css("#main-content").size == 1, "Exactly one skip link and main target must render without JavaScript")
check(!home.to_html.include?("G-XXXXXXXXXX"), "Placeholder analytics must not load")
check(!home.at_css("html")["data-bs-theme"], "Initial theme must follow system preference")
check(!home.at_css('meta[name="viewport"]')["content"].include?("user-scalable=no"), "Zoom must remain available")
rows = dashboard.css("#dashboard-table tbody tr")
check(rows.size <= 30 && rows.size.positive?, "Dashboard must bound recent rows")
check(rows.any? { |row| row.css("td").drop(2).any? { |cell| cell.text.strip != "—" } }, "Dashboard must display actual values, not all missing fields")
check(dashboard.at_css('.table-scroll[tabindex="0"]'), "Wide table must have keyboard-accessible scrolling")
check(tags.css("#tags a").none? { |tag| tag.text.strip.match?(/\ADay\d+\s/i) }, "Discovery tags must omit day-number pollution")
search = JSON.parse(root.join("assets/js/data/search.json").read)
check(search.none? { |post| post["content"].include?("{% include") || post["tags"].match?(/\bDay\d+\b/i) }, "Search must have clean body text and topic tags")
local_by_path = search.to_h { |record| [URI.parse(record["url"]).path, record] }
posts = root.join("posts").glob("*/index.html")
words = []
posts.each do |path|
  page = html(path)
  schemas = page.css('script[type="application/ld+json"]').map { |node| JSON.parse(node.text) }
  entries = schemas.select { |entry| entry["@type"] == "BlogPosting" }
  check(entries.size == 1, "Duplicate/missing BlogPosting: #{path}")
  check(entries.first["wordCount"].to_i.positive?, "Invalid visible-prose word count: #{path}")
  check(page.css(".bori-related").size <= 1, "Duplicate related block: #{path}")
  check(page.css(".sv-chart h2").all? { |heading| heading["id"] == "bori-statevector-snapshot" } &&
        page.css("#bori-statevector-snapshot").size <= 1, "Snapshot TOC heading must have one stable target: #{path}")
  check(page.css(".bori-related h2").all? { |heading| heading["id"] == "bori-related-reading" } &&
        page.css("#bori-related-reading").size <= 1, "Related TOC heading must have one stable target: #{path}")
  check(page.at_css(".comments-unavailable"), "Comments must clearly report unavailable integration")
  check(page.css(".skip-link").size == 1 && page.css("#main-content").size == 1, "Hooks must not duplicate skip links or main IDs: #{path}")
  og = page.at_css('meta[property="og:image"]')
  check(!og || !og["content"].end_with?(".svg"), "Open Graph must not depend on an unsupported SVG: #{path}")
  if og && og["content"].end_with?("android-chrome-512x512.png")
    check(page.at_css('meta[property="og:image:alt"]')["content"].include?("shared brand fallback"), "Brand fallback must not masquerade as an article thumbnail: #{path}")
  end
  current = local_by_path[URI.parse(page.at_css('link[rel="canonical"]')["href"]).path]
  if current
    page.css(".series-nav a, .bori-related li a").each do |link|
      target = local_by_path[URI.parse(link["href"]).path]
      check(target && target["categories"] == current["categories"], "Reading navigation must stay in the same content subtype: #{path}")
      next unless link.ancestors.any? { |node| node["class"].to_s.split.include?("bori-related") }
      topics = current["tags"].split(",").map { |tag| tag.strip.downcase } - BoriReader::GENERIC_TAGS
      target_topics = target["tags"].split(",").map { |tag| tag.strip.downcase }
      check(!(topics & target_topics).empty?, "Related reading must share a substantive topic: #{path}")
    end
  end
  words << entries.first["wordCount"]
end
public_scope = {}
if ARGV[1]
  manifest = JSON.parse(File.read(ARGV[1]))
  day_tags = []
  base_path = URI.parse(home.at_css('link[rel="canonical"]')["href"]).path
  manifest.each do |record|
    path = URI.parse(record["url"]).path
    local = local_by_path[path]
    check(local, "Previously public post path was lost: #{path}")
    check(Time.parse(local["date"]) == Time.parse(record["date"]), "Publication instant changed: #{path}")
    check(root.join(path.delete_prefix(base_path), "index.html").file?, "Public HTML path is missing: #{path}")
    tags = record["tags"].is_a?(Array) ? record["tags"] : record["tags"].split(",").map(&:strip)
    day_tags.concat(tags.select { |tag| tag.match?(/\Aday[\s_-]?\d+\z/i) })
  end
  day_tags.uniq.each do |tag|
    check(root.join("tags", Jekyll::Utils.slugify(tag), "index.html").file?, "Legacy public day-tag URL was lost: #{tag}")
  end
  public_scope = {
    "public_manifest_posts" => manifest.size,
    "public_paths_and_publication_instants_preserved" => manifest.size,
    "local_only_preview_posts" => search.size - manifest.size,
    "legacy_public_day_tag_pages_preserved" => day_tags.uniq.size
  }
end
structural_scope = {}
if ARGV[2]
  changes = JSON.parse(File.read(ARGV[2]))
  changes.each do |change|
    page = html(change["html"])
    page.css("article .content h2").each do |heading|
      next if heading.ancestors.any? { |node| %w[blockquote pre code].include?(node.name) }
      check(section_body?(heading), "Empty H2 scaffolding remains in changed article: #{change['url']} / #{heading.text}")
    end
  end
  structural_scope = { "changed_public_bodies" => changes.size, "empty_h2_scaffolding_in_changed_bodies" => 0 }
end
puts "ui-check: 13 UI assertions + #{posts.size} post-schema/navigation/comment/accessibility/social-preview checks passed"
puts JSON.pretty_generate(
  "posts" => posts.size,
  "search_records" => search.size,
  "start_here_types" => home.css(".start-grid article").size,
  "home_cards" => home.css("#post-list article").size,
  "dashboard_title" => dashboard.at_css("title").text.strip,
  "dashboard_rows" => rows.size,
  "coordinate_headers" => dashboard.css("#dashboard-table thead th").drop(3).map(&:text),
  "subtype_stats" => dashboard.css(".dashboard-card").map { |card| card.text.strip.gsub(/\s+/, " ") },
  "blogposting_count" => posts.size,
  "word_count_range" => [words.min, words.max],
  "public_scope" => public_scope,
  "structural_scope" => structural_scope
)
