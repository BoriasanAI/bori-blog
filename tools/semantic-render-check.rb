# frozen_string_literal: true

require "jekyll"
require "nokogiri"
require "json"
require "digest"
require "pathname"
require "uri"

upstream = Pathname.new("/home/moonchoi/dev/agent-san")
audit = upstream.join("logs/2026-11-01/blog-content-audit")
site = Pathname.new("_site/bori-blog")
receipts = JSON.parse(audit.join("semantic-application-receipts.json").read)
receipts << JSON.parse(audit.join("sample-final-receipt.json").read)
hardening = JSON.parse(audit.join("citation-hardening-receipt.json").read)
previous = receipts.find { |receipt| receipt.fetch("filename") == hardening.fetch("filename") }
raise "Citation hardening receipt is not chained to semantic receipt" unless previous &&
  previous.fetch("after_sha256") == hardening.fetch("before_sha256") &&
  previous.fetch("after_body_sha256") == hardening.fetch("before_body_sha256")
previous["after_sha256"] = hardening.fetch("after_sha256")
previous["after_body_sha256"] = hardening.fetch("after_body_sha256")
previous["findings"] |= hardening.fetch("findings")
plan = JSON.parse(audit.join("final-owner-plan.json").read)
catalog = JSON.parse(upstream.join(plan.fetch("catalog").fetch("path")).read)
plans = plan.fetch("articles").to_h { |article| [article.fetch("filename"), article] }
search = JSON.parse(site.join("assets/js/data/search.json").read)

def check(condition, message)
  raise message unless condition
end
def body(source)
  source.split("\n---\n", 2).fetch(1)
end
def normalized(text)
  text.gsub(/\s+/, " ").strip
end

check(receipts.size == 59 && receipts.map { |row| row.fetch("filename") }.uniq.size == 59, "Expected 59 unique semantic article receipts")
rows = receipts.map do |receipt|
  filename = receipt.fetch("filename")
  path = Pathname.new("_posts").join(filename)
  source = path.read
  source_hash = Digest::SHA256.hexdigest(source)
  check(source_hash == receipt.fetch("after_sha256"), "Receipt source SHA mismatch: #{filename}")
  check(Digest::SHA256.hexdigest(body(source)) == receipt.fetch("after_body_sha256"), "Receipt body SHA mismatch: #{filename}")
  slug = filename.sub(/\.md\z/, "").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
  records = search.select { |post| URI.parse(post.fetch("url")).path == "/bori-blog/posts/#{slug}/" }
  check(records.size == 1, "Semantic source must map to exactly one rendered path: #{filename}")
  html_path = site.join("posts", slug, "index.html")
  document = Nokogiri::HTML(html_path.read)
  content = document.at_css("article .content")
  check(content, "Missing article body: #{filename}")
  schemas = document.css('script[type="application/ld+json"]').map { |node| JSON.parse(node.text) }
  check(schemas.count { |schema| schema["@type"] == "BlogPosting" } == 1, "Semantic page needs exactly one BlogPosting: #{filename}")
  meaningful = content.dup
  meaningful.css("nav, .series-nav, .bori-related, .cf-signature, .sv-chart, .bori-cta, script, style, svg").remove
  check(meaningful.text.scan(/[\p{L}\p{N}]+/).size >= 30 && meaningful.css("p").any? { |paragraph| paragraph.text.strip.size >= 50 }, "Semantic body must retain meaningful prose: #{filename}")
  original = upstream.join(receipt.fetch("backup")).read
  old_reviews = body(original).scan(/Review date:\s*([^\n<]+)/).flatten.map(&:strip)
  reviews = body(source).scan(/Review date:\s*([^\n<]+)/).flatten.map(&:strip)
  check(old_reviews == reviews, "Historical review dates changed: #{filename}")
  data = SafeYAML.load(source.split(/^---\s*$/, 3).fetch(1))
  findings = data.fetch("content_revision").fetch("findings")
  check((receipt.fetch("findings") - findings).empty?, "Receipt finding provenance missing: #{filename}")
  quotes = (plans[filename]&.fetch("edits") || []).select { |edit| edit["operation"] == "quote-source" }
  quotes.each do |edit|
    quote = normalized(edit.fetch("source_quote"))
    evidence = catalog.fetch(edit.fetch("source_id"))
    check(normalized(evidence.fetch("text")).include?(quote), "Quotation absent from captured source: #{filename} / #{edit['id']}")
    quoted = content.css("blockquote").find do |block|
      block.css("p").any? { |paragraph| normalized(paragraph.text) == quote } &&
        block.css("cite a").any? { |link| link["href"] == evidence.fetch("url") } &&
        block.at_css("cite")&.text.to_s.include?(Date.parse(evidence.fetch("retrieved_at")).to_s)
    end
    check(quoted, "Literal attributed HTML quotation missing from rendered body: #{filename} / #{edit['id']}")
  end
  literal_blocks = Nokogiri::HTML.fragment(body(source)).css("blockquote").select { |block| block.at_css("cite a") }
  citation_keys = literal_blocks.map { |block| [normalized(block.at_css("p")&.text.to_s), block.at_css("cite a")["href"]] }
  check(citation_keys.uniq.size == citation_keys.size, "Repeated identical attributed source block: #{filename}")
  literal_blocks.each do |block|
    quote = normalized(block.at_css("p")&.text.to_s)
    link = block.at_css("cite a")
    evidence = catalog.values.find do |entry|
      entry["url"] == link["href"] && normalized(entry.fetch("text")).include?(quote)
    end
    check(evidence && !quote.empty?, "Literal source HTML quote lacks captured evidence: #{filename}")
    check(content.css("blockquote").any? { |rendered| normalized(rendered.at_css("p")&.text.to_s) == quote &&
          rendered.css("cite a").any? { |anchor| anchor["href"] == link["href"] } },
          "Literal source HTML quote not preserved in rendered content: #{filename}")
  end
  {
    "filename" => filename, "source_sha256" => source_hash,
    "body_sha256" => receipt.fetch("after_body_sha256"), "url" => records.first.fetch("url"),
    "html" => html_path.to_s, "html_sha256" => Digest::SHA256.file(html_path).hexdigest,
    "rendered_body_sha256" => Digest::SHA256.hexdigest(content.to_html),
    "historical_review_dates" => reviews, "literal_captured_quotes_checked" => quotes.size,
    "literal_source_html_blocks_checked" => literal_blocks.size,
    "meaningful_body_words" => meaningful.text.scan(/[\p{L}\p{N}]+/).size
  }
end
result = {
  "receipt_articles" => rows.size, "source_and_body_sha_matches" => rows.size,
  "unique_rendered_paths_and_single_blogposting" => rows.size,
  "historical_review_dates_preserved" => rows.size, "meaningful_bodies" => rows.size,
  "literal_captured_quotes_checked" => rows.sum { |row| row.fetch("literal_captured_quotes_checked") },
  "literal_source_html_blocks_checked" => rows.sum { |row| row.fetch("literal_source_html_blocks_checked") },
  "captured_source_catalog_size" => catalog.size, "articles" => rows
}
result["citation_hardening_receipt_chain_verified"] = true
File.write("logs/2026-11-01/reader-ui/semantic-render-result.json", JSON.pretty_generate(result))
puts JSON.pretty_generate(result.reject { |key, _| key == "articles" })
