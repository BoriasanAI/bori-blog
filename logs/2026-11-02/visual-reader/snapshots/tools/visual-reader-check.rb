# frozen_string_literal: true

require "jekyll"
require "yaml"
require "nokogiri"
require_relative "../_plugins/reader-visuals"

@checks = 0
def check(condition, message)
  @checks += 1
  raise message unless condition
end

def invalid(data, message)
  BoriVisuals.validate(data, root: File.expand_path("fixtures/site", __dir__))
  raise "accepted invalid #{message}"
rescue BoriVisuals::Invalid
  @checks += 1
end

fixture = YAML.safe_load_file(File.expand_path("fixtures/reader-visuals.yml", __dir__), permitted_classes: [Date])
root = File.expand_path("fixtures/site", __dir__)
html = BoriVisuals.render(fixture, root: root, baseurl: "/bori-blog")
doc = Nokogiri::HTML.fragment(html)
check(doc.css(".rv-source").size == 1, "one actual source card")
check(doc.at_css(".rv-host").text == "arxiv.org", "host badge derives from URL")
check(doc.at_css("h3 a")["href"] == fixture["sources"][0]["url"], "exact source link")
check(doc.at_css(".rv-authors").text == fixture["sources"][0]["authors"].join(", "), "exact supplied author list")
check(doc.at_css("time")["datetime"] == "2017-06-12", "original publication date, not blog date")
check(doc.at_css(".rv-kind").text.include?("arXiv"), "actual archive badge")
check(doc.css(".rv-outline svg rect").size == 2, "one SVG shape per actual supplied heading")
check(doc.css(".rv-outline li > span").map(&:text) == fixture["diagrams"][0]["nodes"].map { |node| node["label"] }, "exact accessible outline labels")
check(doc.at_css(".rv-outline svg")["aria-hidden"] == "true", "visible textual outline is the accessible alternative")
check(doc.at_css(".rv-outline svg")["viewbox"].start_with?("0 0 320 "), "responsive viewbox with computed height")
doi = Marshal.load(Marshal.dump(fixture))
doi["sources"][0]["url"] = "https://doi.org/10.48550/arXiv.1706.03762"
check(Nokogiri::HTML.fragment(BoriVisuals.render(doi, root: root)).at_css(".rv-kind").text.include?("DOI"), "DOI card retains actual URL")
doi["sources"][0]["published"] = "2017-02-31"
invalid(doi, "impossible publication date")
%w[http://example.org/a javascript:alert(1) https://127.0.0.1/a https://localhost/a //evil.example/a].each do |bad|
  copy = Marshal.load(Marshal.dump(fixture))
  copy["sources"][0]["url"] = bad
  invalid(copy, bad)
end
copy = Marshal.load(Marshal.dump(fixture))
copy["sources"][0]["title"] = '<script>alert("x")</script>'
safe = Nokogiri::HTML.fragment(BoriVisuals.render(copy, root: root))
check(safe.css("script").empty? && safe.at_css("h3").text.include?("<script>"), "plain text is escaped, not interpreted")
copy["version"] = 2
invalid(copy, "schema version")
check(doc.css("img").empty? && doc.at_css(".rv-no-image"), "missing metadata never fabricates a preview image")
image_data = Marshal.load(Marshal.dump(fixture))
image_data["sources"][0]["image"] = {
  "path" => "/assets/reader-visuals/geometry.svg", "alt" => "Original geometric test shapes",
  "credit" => "Copilot test fixture", "license" => "CC0-1.0"
}
image_doc = Nokogiri::HTML.fragment(BoriVisuals.render(image_data, root: root, baseurl: "/bori-blog"))
image = image_doc.at_css("img")
check(image["width"] == "640" && image["height"] == "360" && image["loading"] == "lazy", "intrinsic local dimensions and lazy loading")
check(image["src"] == "/bori-blog/assets/reader-visuals/geometry.svg", "image baseurl")
check(image_doc.at_css("figcaption").text.include?("CC0-1.0"), "license and credit visible")
image_data["sources"][0]["image"].delete("license")
invalid(image_data, "unlicensed image")
graph = Marshal.load(Marshal.dump(fixture))
graph["diagrams"] = [{
  "kind" => "evidence-map", "title" => "Supplied citation relationship",
  "nodes" => [{ "id" => "article", "label" => "Example article" }, { "id" => "attention", "label" => fixture["sources"][0]["title"], "url" => fixture["sources"][0]["url"] }],
  "edges" => [{ "from" => "article", "to" => "attention", "label" => "citation" }]
}]
graph_doc = Nokogiri::HTML.fragment(BoriVisuals.render(graph, root: root))
check(graph_doc.css(".rv-evidence-map svg path").size == 1, "only supplied graph edges are drawn")
check(graph_doc.at_css(".rv-edge-list").text.include?("Example article → Attention Is All You Need — citation"), "exact edge label and endpoints in accessible text")
graph["diagrams"][0]["edges"][0]["to"] = "invented"
invalid(graph, "dangling edge")
chronology = Marshal.load(Marshal.dump(fixture))
chronology["diagrams"] = [{
  "kind" => "timeline", "title" => "Actual publication records", "nodes" => [],
  "events" => [{ "date" => "2026-11-02", "label" => "Fixture article date" },
               { "date" => "2017-06-12", "label" => fixture["sources"][0]["title"], "url" => fixture["sources"][0]["url"] }]
}]
timeline_doc = Nokogiri::HTML.fragment(BoriVisuals.render(chronology, root: root))
check(timeline_doc.css(".rv-timeline time").map { |time| time["datetime"] } == %w[2017-06-12 2026-11-02], "timeline sorts only actual provided dates")
check(timeline_doc.at_css(".rv-timeline figcaption").text.include?("2017-06-12 — 2026-11-02"), "timeline bounds derive from actual dates")
check(timeline_doc.at_css(".rv-timeline a").text == fixture["sources"][0]["title"], "event label and source link exact")
chronology["diagrams"][0]["events"][0]["date"] = "yesterday"
invalid(chronology, "undated chronology")
comparison = Marshal.load(Marshal.dump(fixture))
comparison["diagrams"] = [{
  "kind" => "comparison", "title" => "Two supplied excerpt rows",
  "nodes" => [
    { "id" => "row-a", "label" => "First source label", "detail" => "Exact supplied excerpt A." },
    { "id" => "row-b", "label" => "Second source label", "detail" => "Exact supplied excerpt B." }
  ]
}]
table = Nokogiri::HTML.fragment(BoriVisuals.render(comparison, root: root))
check(table.css("tbody tr").size == 2, "one row per actual comparison node")
check(table.css("tbody td").map(&:text) == ["Exact supplied excerpt A.", "Exact supplied excerpt B."], "comparison adds no rankings or invented metrics")
check(table.css('th[scope="row"]').size == 2 && table.at_css('[role="region"]')["tabindex"] == "0", "accessible table headers and keyboard scrolling")
check(table.at_css(".rv-scroll-hint").text.include?("가로"), "mobile comparison has an explicit visible horizontal-scroll instruction")
comparison["diagrams"][0]["nodes"].pop
invalid(comparison, "one-row comparison")
gallery = Marshal.load(Marshal.dump(fixture))
gallery["gallery"] = [{
  "path" => "/assets/reader-visuals/geometry.svg", "alt" => "Two original test shapes",
  "caption" => "Original geometric fixture; not a paper figure.",
  "credit" => "Copilot", "license" => "CC0-1.0"
}]
gallery_doc = Nokogiri::HTML.fragment(BoriVisuals.render(gallery, root: root))
check(gallery_doc.css(".rv-gallery figure").size == 1, "gallery renders only supplied local images")
check(gallery_doc.at_css(".rv-gallery .rv-caption").text == gallery["gallery"][0]["caption"], "exact caption and ownership")
check(gallery_doc.at_css(".rv-gallery img")["alt"] == gallery["gallery"][0]["alt"], "gallery alternative text")
gallery["gallery"] *= 4
invalid(gallery, "unbounded gallery")
%w[paper essay journal].each do |style|
  styled = Marshal.load(Marshal.dump(fixture))
  styled["style"] = style
  styled_doc = Nokogiri::HTML.fragment(BoriVisuals.render(styled, root: root))
  section = styled_doc.at_css(".reader-visuals")
  check(section["class"].split.include?("rv-#{style}"), "genre style derives from explicit #{style} metadata")
  first = section.element_children[1]
  check(first["class"].include?(style == "paper" ? "rv-sources" : "rv-diagram"), "#{style} arranges sources and reading maps by genre")
end
check(doc.at_css(".rv-source h3 a")["aria-label"].include?("external source at arxiv.org"), "external source names are explicit without forced new windows")
check(doc.css('a[target="_blank"]').empty?, "reading links do not unexpectedly open a window")
targeted = BoriVisuals.outline_targets(fixture, '<article><div class="content"><h2 id="real-intro">Introduction / 도입</h2></div></article>', "/posts/example/")
check(targeted["diagrams"][0]["nodes"][0]["url"] == "/posts/example/#real-intro", "outline links only to exactly matched real headings")
check(!fixture["diagrams"][0]["nodes"][0].key?("url"), "outline target enhancement never mutates supplied metadata")
check(!targeted["diagrams"][0]["nodes"][1].key?("url"), "unmatched headings never fabricate a target")
check(BoriVisuals.svg_lines("Why This Paper Caught My Eye") == ["Why This Paper Caught My Eye"], "short English headings do not split words")
wide_label = "반응형 글 지도의 실제 제목과 정확한 출처 연결을 표시합니다"
wide_lines = BoriVisuals.svg_lines(wide_label)
check(wide_lines.join.delete(" ") == wide_label.delete(" "), "CJK SVG wrapping retains every input character")
check(wide_lines.all? { |line| line.each_char.sum { |char| char.ord >= 0x2e80 ? 2 : 1 } <= BoriVisuals::SVG_LINE_UNITS }, "CJK labels respect the explicit monospace glyph-width contract")
long_data = Marshal.load(Marshal.dump(fixture))
long_data["diagrams"][0]["nodes"][0]["label"] = wide_label * 3
long_doc = Nokogiri::HTML.fragment(BoriVisuals.render(long_data, root: root))
rect_height = long_doc.at_css(".rv-outline rect")["height"].to_i
last_y = long_doc.css(".rv-outline g").first.css("tspan").last["y"].to_i
check(last_y <= 12 + rect_height, "computed node height contains all wrapped text lines")
%w[https://127.1/a https://0x7f.0.0.1/a https://foo.localhost./a https://example.org:8080/a https://user:pass@example.org/a /a/../secret].each do |bad|
  copy = Marshal.load(Marshal.dump(fixture))
  copy["sources"][0]["url"] = bad
  invalid(copy, bad)
end
invalid({ "version" => 1, "sources" => [] }, "empty visual panel")
check(BoriVisuals.href("/bori-blog/posts/example/", "/bori-blog") == "/bori-blog/posts/example/", "baseurl is never duplicated")
site = Struct.new(:source, :baseurl).new(root, "/bori-blog")
post_type = Struct.new(:data, :site, :output, :url)
original = '<html><body><article><div class="content"><h2 id="real-intro">Introduction / 도입</h2><p>Unchanged prose.</p></div></article></body></html>'
unmodified = post_type.new({}, site, original.dup, "/posts/example/")
BoriVisuals.enhance_post(unmodified)
check(unmodified.output == original, "posts without visual metadata are byte-for-byte unchanged")
disabled = post_type.new({ "reader_visuals" => nil }, site, original.dup, "/posts/example/")
BoriVisuals.enhance_post(disabled)
check(disabled.output == original, "explicitly invalidated null visuals stay disabled")
enhanced = post_type.new({ "reader_visuals" => fixture }, site, original.dup, "/posts/example/")
BoriVisuals.enhance_post(enhanced)
enhanced_doc = Nokogiri::HTML(enhanced.output)
check(enhanced_doc.at_css("article .content").to_html == Nokogiri::HTML(original).at_css("article .content").to_html, "supplemental UI cannot change authored prose or schema word-count input")
check(enhanced_doc.css("article > .reader-visuals").size == 1, "one supplemental panel outside prose")
missing = Marshal.load(Marshal.dump(fixture))
missing["sources"][0]["image"] = { "path" => "/assets/absent.png", "alt" => "Missing", "credit" => "Bori", "license" => "CC-BY-4.0" }
invalid(missing, "missing local image fails loudly during build")
strict = Marshal.load(Marshal.dump(fixture))
strict["version"] = 1.0
invalid(strict, "noninteger schema version")
strict = Marshal.load(Marshal.dump(fixture))
strict["sources"] *= 7
invalid(strict, "source cap")
strict = Marshal.load(Marshal.dump(fixture))
strict["diagrams"] *= 3
invalid(strict, "diagram cap")
strict = Marshal.load(Marshal.dump(fixture))
strict["unexpected"] = "value"
invalid(strict, "unknown field")
strict = Marshal.load(Marshal.dump(fixture))
strict["diagrams"][0]["nodes"][1]["id"] = strict["diagrams"][0]["nodes"][0]["id"]
invalid(strict, "duplicate diagram node IDs")
bad = post_type.new({ "reader_visuals" => false }, site, original.dup, "/posts/example/")
begin
  BoriVisuals.enhance_post(bad)
  raise "malformed metadata was silently ignored"
rescue BoriVisuals::Invalid
  @checks += 1
end
quoted = Marshal.load(Marshal.dump(fixture))
quoted["diagrams"][0]["nodes"][0]["label"] = "What I'm Taking Away"
quoted_target = BoriVisuals.outline_targets(quoted, '<article><div class="content"><h2 id="actual">What I’m Taking Away</h2></div></article>', "/posts/example/")
check(quoted_target["diagrams"][0]["nodes"][0]["url"] == "/posts/example/#actual", "rendered smart quotes preserve real heading navigation without changing labels")
%w[outline evidence-map timeline comparison].each do |kind|
  check(BoriVisuals.diagram_title({ "kind" => kind, "title" => kind }) != kind &&
    BoriVisuals.diagram_title({ "kind" => kind, "title" => kind }).include?("/"), "internal diagram key becomes a bilingual reader-facing heading")
  check(BoriVisuals.diagram_title({ "kind" => kind, "title" => "Exact custom title" }) == "Exact custom title", "custom #{kind} titles remain exact")
end
actual_labels = 0
actual_posts = 0
Dir["_posts/*.md"].each do |path|
  frontmatter = File.read(path).match(/\A---\s*\n(.*?)\n---/m)
  next unless frontmatter
  data = YAML.safe_load(frontmatter[1], permitted_classes: [Date, Time], aliases: true)
  next unless data["reader_visuals"]
  actual_posts += 1
  BoriVisuals.validate(data["reader_visuals"], root: Dir.pwd)
  Array(data["reader_visuals"]["diagrams"]).each do |diagram|
    next unless %w[outline evidence-map].include?(diagram["kind"])
    diagram["nodes"].each do |node|
      label = node["label"]
      lines = BoriVisuals.svg_lines(label)
      actual_labels += 1
      if label.scan(/[A-Za-z]+/).all? { |word| word.length <= BoriVisuals::SVG_LINE_UNITS }
        check(lines.flat_map { |line| line.scan(/[A-Za-z]+/) } == label.scan(/[A-Za-z]+/), "real heading/source words split mid-token: #{path}: #{label}")
      end
      check(lines.all? { |line| line.each_char.sum { |char| char.ord >= 0x2e80 ? 2 : 1 } <= BoriVisuals::SVG_LINE_UNITS }, "real SVG heading exceeds width contract: #{path}")
    end
  end
end
puts "actual-inputs: #{actual_posts} posts; #{actual_labels} SVG labels validated"
puts "visual-reader: #{@checks} checks passed"
