# frozen_string_literal: true

require "json"
require "nokogiri"
require "pathname"

root = Pathname.new(ARGV.fetch(0, "_site/bori-blog"))
baseurl = "/bori-blog"
origin = "https://boriasanai.github.io"
failures = []

%w[.well-known/api-catalog openapi.json auth.md llms.txt llms-full.txt api/posts-index.json index.md about/index.md robots.txt sitemap.xml feed.xml 619cc279ff5e440cb04e9c2b53a7778a.txt assets/img/banner/og-default.png].each do |rel|
  failures << "missing_required_export:#{rel}" unless root.join(rel).file?
end
failures << "forbidden_acp_json_present" if root.join(".well-known/acp.json").exist?

if root.join(".well-known/api-catalog").file?
  catalog = JSON.parse(root.join(".well-known/api-catalog").read)
  failures << "api_catalog_missing_linkset" unless catalog["linkset"].is_a?(Array) && catalog["linkset"].any?
end

if root.join("openapi.json").file?
  oa = JSON.parse(root.join("openapi.json").read)
  failures << "openapi_version_mismatch" unless oa["openapi"] == "3.1.0"
  (oa["paths"] || {}).each_key do |p|
    local = root.join(p.sub(%r{\A/}, ""))
    failures << "openapi_endpoint_missing:#{p}" unless local.file?
  end
end

if root.join("auth.md").file?
  auth = root.join("auth.md").read
  failures << "auth_md_invalid_h1" unless auth.start_with?("# auth.md")
  failures << "auth_md_missing_anonymous" unless auth.include?('"anonymous"')
end

if root.join("robots.txt").file?
  robots = root.join("robots.txt").read
  %w[Googlebot bingbot Yeti OAI-SearchBot Claude-SearchBot PerplexityBot GPTBot ClaudeBot].each do |bot|
    failures << "robots_missing_agent:#{bot}" unless robots.include?(bot)
  end
  failures << "robots_missing_sitemap" unless robots.include?("#{origin}#{baseurl}/sitemap.xml")
end

if root.join("assets/img/banner/og-default.png").file?
  sig = root.join("assets/img/banner/og-default.png").binread(8).unpack1("H*")
  failures << "og_default_invalid_png_magic" unless sig == "89504e470d0a1a0a"
end

titles = {}
html_files = Dir.glob(root.join("**/*.html").to_s).sort
html_files.each do |file|
  rel = Pathname.new(file).relative_path_from(root).to_s
  html = File.read(file, encoding: "UTF-8")
  doc = Nokogiri::HTML(html)
  head = doc.at_css("head")
  next unless head
  robots_meta = head.at_css('meta[name="robots"]')&.[]("content").to_s
  noindex = robots_meta.include?("noindex") || rel == "404.html" || html.include?('http-equiv="refresh"')
  next if noindex

  title = head.at_css("title")&.text.to_s.gsub(/\s+/, " ").strip
  og_title = head.at_css('meta[property="og:title"]')&.[]("content").to_s.gsub(/\s+/, " ").strip
  tw_title = head.at_css('meta[name="twitter:title"]')&.[]("content").to_s.gsub(/\s+/, " ").strip
  desc = head.at_css('meta[name="description"]')&.[]("content").to_s.gsub(/\s+/, " ").strip

  failures << "#{rel}:missing_title" if title.empty?
  failures << "#{rel}:missing_description" if desc.empty?
  failures << "#{rel}:og_title_mismatch" unless title == og_title
  failures << "#{rel}:twitter_title_mismatch" unless title == tw_title
  failures << "#{rel}:missing_h1" unless doc.at_css("h1")

  key = title.downcase
  if titles.key?(key) && !rel.start_with?("page")
    failures << "#{rel}:duplicate_title:#{titles[key]}"
  else
    titles[key] = rel
  end

  doc.css("img").each do |img|
    failures << "#{rel}:empty_img_alt" if img["alt"].to_s.strip.empty?
  end

  doc.css('script[type="application/ld+json"]').each do |ld|
    JSON.parse(ld.text)
  rescue JSON::ParserError
    failures << "#{rel}:invalid_json_ld"
  end

  failures << "#{rel}:missing_api_catalog_link" unless head.at_css('link[rel="api-catalog"]')
  failures << "#{rel}:missing_llms_link" unless head.at_css('link[href$="/llms.txt"]')
end

post_htmls = root.join("posts").glob("*/index.html")
post_htmls.each do |ph|
  md_twin = ph.dirname.join("index.md")
  failures << "#{ph}:missing_markdown_twin" unless md_twin.file?
end

if failures.any?
  warn "seo-geo-agent-check FAILED (#{failures.size}):\n  - #{failures.first(25).join("\n  - ")}"
  exit 1
end

puts "seo-geo-agent-check: passed across #{html_files.size} HTML files and #{post_htmls.size} post Markdown twins"
