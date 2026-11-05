# frozen_string_literal: true

require "digest"
require "json"
require "jekyll"
require "nokogiri"
require "pathname"
require "uri"
require "yaml"
require "time"
require_relative "../../../_plugins/reader-metadata"

output = Pathname.new(ENV.fetch("SUREON_OUTPUT", __dir__))
site = output.join("site")
source = Pathname.new("_posts/2026-11-02-2603-06570v2.md")
expected_sha = ARGV.fetch(0)
front = YAML.safe_load(source.read.split(/^---\s*$/, 3)[1], permitted_classes: [Time, Date])
document = Nokogiri::HTML(site.join("bori-blog/posts/2603-06570v2/index.html").read)
paper = Nokogiri::HTML(output.join("paper-v2.html").read)
abstract = Nokogiri::HTML(output.join("paper-abs-v2.html").read)
failures = []
checks = 0
check = lambda do |condition, message|
  checks += 1
  failures << message unless condition
end
check.call(Digest::SHA256.file(source).hexdigest == expected_sha, "Source identity changed")
check.call(front["date"] == "2026-11-02 16:22:54 +0900", "Original publication field changed")
check.call(%w[image cf sv].all? { |key| front[key].nil? }, "Hero/CF/SV must be null")
check.call(front.dig("paper", "id") == "2603.06570v2", "Paper metadata must identify v2")
paper_authors = abstract.css('meta[name="citation_author"]').map { |node| node["content"].split(", ", 2).reverse.join(" ") }
check.call(paper_authors == front.dig("paper", "authors"), "Bibliographic authors differ from fixed arXiv v2")
paper_title = abstract.at_css('meta[name="citation_title"]')&.[]("content")
check.call(paper_title == front.dig("paper", "title"), "Bibliographic title differs from fixed arXiv v2")
history = abstract.at_css(".submission-history")&.text.to_s
check.call(history.match?(/\[v2\].*30 Oct 2026/m) && front.dig("paper", "published") == "2026-10-30", "Paper metadata must use the actual v2 history date, not v1 citation_date")
canonical = URI(document.at_css('link[rel="canonical"]')["href"])
check.call(canonical.path == "/bori-blog/posts/2603-06570v2/", "Original URL changed")
schemas = document.css('script[type="application/ld+json"]').map { |node| JSON.parse(node.text) }
posting = schemas.select { |entry| entry["@type"] == "BlogPosting" }
check.call(posting.size == 1, "Duplicate or missing canonical BlogPosting")
visible_words = BoriReader.rendered_word_count(document.at_css("article .content").dup)
check.call(posting.first&.[]("wordCount") == visible_words, "Schema word count must equal actual rendered content counter")
check.call(document.at_css('article .content a[href="https://creativecommons.org/licenses/by/4.0/"]'), "Article References must include the actual CC BY 4.0 license link")

local_links = []
paper_links = []
unchecked_external = []
document.css('article a[href], #toc a[href], #toc-popup-content a[href]').each do |link|
  value = link["href"]
  next if value.empty? || value.start_with?("javascript:", "mailto:")
  uri = URI.join("https://boriasanai.github.io/bori-blog/posts/2603-06570v2/", value)
  if uri.host&.downcase == "boriasanai.github.io"
    relative = URI::DEFAULT_PARSER.unescape(uri.path).delete_prefix("/")
    target = site.join(relative)
    target = target.join("index.html") if uri.path.end_with?("/")
    resolves = target.file?
    if resolves && uri.fragment
      target_document = uri.path == canonical.path ? document : Nokogiri::HTML(target.read)
      resolves &&= target_document.xpath("//*[@id]").any? { |node| node["id"] == URI::DEFAULT_PARSER.unescape(uri.fragment) }
    end
    local_links << { "url" => uri.to_s, "resolves" => resolves }
    check.call(resolves, "Unresolved local navigation: #{uri}")
  elsif uri.host == "arxiv.org" && uri.path.match?(%r{\A/(?:html|abs)/2603\.06570v2(?:/|\z)})
    fragment_resolves = uri.fragment.nil? || paper.xpath("//*[@id]").any? { |node| node["id"] == URI::DEFAULT_PARSER.unescape(uri.fragment) }
    paper_links << { "url" => uri.to_s, "fragment_resolves" => fragment_resolves }
    check.call(fragment_resolves, "Missing fixed paper fragment: #{uri}")
  else
    unchecked_external << uri.to_s
  end
end
gallery = front.dig("reader_visuals", "gallery").first
image_path = Pathname.new(gallery.fetch("path").delete_prefix("/"))
check.call(image_path.size == 227_541, "Actual paper Figure 3 byte size changed")
check.call(gallery["license"] == "CC BY 4.0", "Figure license must be distinguished from dataset NC-SA license")
check.call(gallery["url"] == "https://arxiv.org/html/2603.06570v2#S3.F3", "Figure credit must link to the actual v2 Figure 3")
report = {
  "checks" => checks, "failures" => failures, "source_sha256" => Digest::SHA256.file(source).hexdigest,
  "declared_visual_body_sha256" => front["visual_body_sha256"], "schema_visible_words" => visible_words,
  "fixed_paper_title" => paper_title, "fixed_paper_authors" => paper_authors,
  "local_links_checked" => local_links.uniq, "fixed_arxiv_links_checked" => paper_links.uniq,
  "other_external_urls_not_requested" => unchecked_external.uniq,
  "figure_sha256" => Digest::SHA256.file(image_path).hexdigest
}
output.join("render-check.json").write(JSON.pretty_generate(report) + "\n")
puts JSON.generate(report.reject { |key, _| %w[local_links_checked fixed_arxiv_links_checked fixed_paper_authors].include?(key) })
exit(failures.empty? ? 0 : 1)
