# frozen_string_literal: true

require "jekyll"
require_relative "../_plugins/reader-metadata"

def check(condition, message)
  @checks = (@checks || 0) + 1
  raise message unless condition
end

check(BoriReader.vector({ "cu" => "0.7", "AU" => 0, "EV" => "bad", "PE" => nil }) == { "CU" => 0.7, "AU" => 0.0 }, "Numeric vectors must retain zero and exclude invalid values")
check(BoriReader.vector("PE:0.75 | GA:0.65 | IS:0.80 | EV:0.55 | MSI:0.70")["IS"] == 0.8, "Legacy vectors must parse named keys")
check(BoriReader.vector("bad | CU:NaN | AU:Infinity").empty?, "Non-finite legacy coordinates must not become zero")
check(!BoriReader.topic_tag?("Day250") && !BoriReader.topic_tag?("2026-10-31") && BoriReader.topic_tag?("daylight"), "Date filtering must not hide actual topics")
check(BoriReader.kind({ "categories" => ["Daily", "paper review"], "tags" => ["AGI"] }) == "paper-review", "Daily must not imply diary")
check(BoriReader.kind({ "categories" => ["Daily", "concepts language"], "tags" => ["paper"] }) == "research", "Paper metadata must be distinguished from journal")
check(BoriReader.kind({ "content_kind" => "paper_review" }) == "paper-review", "Canonical content kind must take precedence")
check(BoriReader.kind({ "content_kind" => "concept-note", "tags" => ["paper"] }) == "essay", "Canonical concept notes must not be inferred as paper reviews")

Post = Struct.new(:data, :date, :url, :content)
def sample(kind, tags, date, url)
  Post.new({ "bori_kind" => kind, "bori_tags" => tags }, Time.at(date), url, "")
end
current = sample("essay", ["AGI", "memory"], 3, "/current")
generic = sample("essay", ["AGI"], 4, "/generic")
different = sample("journal", ["memory"], 5, "/different")
match = sample("essay", ["memory"], 1, "/match")
check(BoriReader.related([current, generic, different, match], current) == [match], "Related posts require the same subtype and a substantive shared topic")

converter = Jekyll::Converters::Markdown.new(Jekyll.configuration("quiet" => true))
post = Post.new({ "title" => "Day 250 After the Big Bang: Real title", "description" => "Day 250 after the Big Bang — Real title." }, Time.now, "/excerpt",
                "> Day 250 after the Big Bang — Real title.\n\n## Overview\n\nActual body, not the title.\n\n{% include series-nav.html %}\n\n<svg><text>Chart labels</text></svg>")
BoriReader.decorate(post, converter)
check(post.data["bori_title"] == "Real title" && post.data["title"].start_with?("Day 250"), "Display titles must not mutate source titles")
check(post.data["bori_summary"] == "Actual body, not the title.", "Redundant descriptions must use cleaned real body text")
prose = Nokogiri::HTML.fragment("<h2>First heading</h2><p>Two words.</p><nav>Ignore navigation.</nav><svg><text>Ignore chart.</text></svg>")
check(BoriReader.rendered_word_count(prose) == 4, "Visible word count must separate adjacent blocks and exclude navigation/SVG text")
check(prose.at_css("svg") && prose.at_css("nav"), "Counting must not mutate rendered source")
supplemental = Nokogiri::HTML.fragment('<p>Two words.</p><figure data-supplemental="true"><figcaption>Not prose</figcaption></figure><figure class="review-results-chart">22.4% chart</figure><ol class="review-source-notes"><li>Source notes</li></ol><p class="svg-text-alternative">Original labels and values</p>')
check(BoriReader.rendered_word_count(supplemental) == 2, "Supplemental figure captions, evidence chart labels and source notes do not inflate prose word count")
post.data["image"] = { "path" => "/assets/img/avatar/bori-presence-avatar.png" }
BoriReader.decorate(post, converter)
check(post.data["image"].nil?, "Generic avatar must not become an article hero")
post.data["image"] = { "path" => "/assets/img/avatar/article-portrait.png" }
BoriReader.decorate(post, converter)
check(post.data["image"]["path"] == "/assets/img/avatar/article-portrait.png", "Only the generic brand avatars are removed; meaningful article images are preserved")
signature_template = File.read("_includes/cf-signature.html").gsub("{{ '/about/' | relative_url }}", "/about/")
[{ "formula" => "x + y", "emotion" => "curiosity", "sv" => "CU=0.7" }, "Original plain annotation"].each do |annotation|
  rendered_signature = Liquid::Template.parse(signature_template).render!("page" => { "cf" => annotation })
  signature = Nokogiri::HTML.fragment(rendered_signature)
  check(rendered_signature.strip.end_with?("</details>") && signature.element_children.size == 1 && signature.at_css("details.cf-signature > summary") &&
    signature.at_css("details.cf-signature").text.include?(annotation.is_a?(Hash) ? annotation["emotion"] : annotation),
    "Both generation annotation formats remain entirely inside one well-formed native disclosure")
end
source_sentence = "In `query_compiler.py`, I collapsed nested `if a: if b:` into `if a and b:`."
expected_sentence = "In query_compiler.py, I collapsed nested if a: if b: into if a and b:."
code_post = Post.new({ "title" => "A code note", "description" => "A code note" }, Time.now, "/code", "#{source_sentence}\n\n{% include series-nav.html %}")
BoriReader.decorate(code_post, converter)
check(code_post.data["bori_text"] == expected_sentence && code_post.data["bori_summary"] == expected_sentence, "The complete source sentence, identifiers and inline code must survive excerpt cleanup")
code_post.content = "Identifiers like query_compiler.py and meta_design_evidence.py remain meaningful."
check(BoriReader.cleaned_text(code_post, converter) == code_post.content, "Bare underscore identifiers must remain unchanged")
code_post.content = "In `parser.py`, keep `x <= 3 && y != 0` and `flags >> 1`."
check(BoriReader.cleaned_text(code_post, converter) == "In parser.py, keep x <= 3 && y != 0 and flags >> 1.", "Meaningful inline-code comparison/boolean/shift operators must survive")
preview = BoriReader.raster_social_preview('<html><head><meta property="og:image" content="/original.svg"><meta name="twitter:card" content="summary_large_image"></head><body><img src="/original.svg"></body></html>', "https://example.test/logo.png")
preview_doc = Nokogiri::HTML(preview)
check(preview_doc.at_css('meta[property="og:image"]')["content"] == "https://example.test/logo.png" && preview_doc.at_css('meta[property="og:image:alt"]')["content"].include?("shared brand fallback") && preview_doc.at_css("img")["src"] == "/original.svg", "Social fallback must be honestly labeled without replacing visible article images")
puts "reader-check: #{@checks} assertions passed"
