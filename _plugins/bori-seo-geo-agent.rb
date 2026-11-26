# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "nokogiri"
require "set"

module BoriSeoGeoAgent
  LIMITATIONS_NOTE = [
    "Zero-LLM Architecture: Every entry published after March 3, 2026 is synthesized by Bori's deterministic Pure-Rust symbolic-numerical engine with zero external LLM API calls, zero transformer weights, and zero neural autoregressive token sampling.",
    "Independent Verification: Inspect /provenance/architecture.json, per-post /assets/provenance/<slug>.json SHA-256 manifests, and compile any companion /assets/sim/<slug>.rs zero-dependency Rust solver with `rustc -O` to verify table numbers and FNV1a-64 digests bit-for-bit.",
    "Historical Archive Boundary: Four initial bootstrap entries from March 3, 2026 (model: gpt-4o) predate the Pure-Rust LLM-free engine and are permanently labeled generation_era=legacy-llm-bootstrap (llm_inference=true) for transparency.",
    "Scope: Research notes and arXiv paper reviews synthesize public scholarly literature; verify primary claims against linked DOI/arXiv sources. Nothing on this site constitutes medical, clinical, legal, or financial advice."
  ].freeze

  module_function

  def post_legacy_llm?(post)
    model = post.data["model"].to_s.downcase
    post.data["llm_inference"] == true ||
      post.data["generation_era"].to_s == "legacy-llm-bootstrap" ||
      model.include?("gpt-") || model.include?("claude") || model.include?("gemini")
  end

  def post_provenance_meta(site, post)
    base = "#{site.config['url']}#{site.config['baseurl']}"
    slug = post_slug(post)
    legacy = post_legacy_llm?(post)
    sim_rel = File.join("assets", "sim", "#{slug}.rs")
    sim_abs = File.join(site.source, sim_rel)
    has_sim = !slug.empty? && File.file?(sim_abs)
    raw_src = File.file?(post.path.to_s) ? File.read(post.path, encoding: "UTF-8") : post.content.to_s
    {
      "slug" => slug,
      "title" => post.data["title"].to_s.strip,
      "canonical_url" => "#{base}#{post.url}",
      "published" => post.date.strftime("%Y-%m-%d"),
      "synthesis_engine" => legacy ? "legacy-gpt-4o-bootstrap" : (post.data["synthesis_engine"] || "bori-pure-rust-symbolic-numerical"),
      "llm_inference" => legacy,
      "external_llm_api_calls" => legacy ? nil : 0,
      "generation_era" => legacy ? "legacy-llm-bootstrap" : (post.data["generation_era"] || "native-llm-free"),
      "post_markdown_sha256" => Digest::SHA256.hexdigest(raw_src),
      "architecture_url" => "#{base}/provenance/architecture.json",
      "provenance_url" => "#{base}/assets/provenance/#{slug}.json",
      "simulation_source_url" => has_sim ? "#{base}/#{sim_rel}" : nil,
      "simulation_source_sha256" => has_sim ? Digest::SHA256.file(sim_abs).hexdigest : nil,
      "repro_command" => has_sim ? "rustc -O #{slug}.rs -o sim && ./sim" : nil
    }
  end

  def strip_frontmatter(raw)
    text = raw.to_s
    return text unless text.start_with?("---\n")
    idx = text.index("\n---\n", 4)
    idx ? text[(idx + 5)..].to_s : text
  end

  def clean_markdown_body(raw_md)
    body = strip_frontmatter(raw_md)
    body = body.gsub(/\{%\s*include\s+[^%]+%\}/m, "")
    body = body.gsub(/\{:\s*[^}]+\}/, "")
    body.gsub(/\n{3,}/, "\n\n").strip
  end

  def post_slug(post)
    post.url.to_s.split("/").reject(&:empty?).last.to_s
  end

  def write_dest_file(site, rel_path, content)
    target = File.join(site.dest, rel_path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, content, mode: "w:UTF-8")
  end

  def emit_static_agent_corpus(site)
    base = "#{site.config['url']}#{site.config['baseurl']}"
    posts = site.posts.docs.reject { |p| p.data["hidden"] }.sort_by(&:date).reverse
    brief = build_llms_brief(site, posts)

    write_dest_file(site, "llms.txt", brief)
    write_dest_file(site, "llms-full.txt", build_llms_full(site, posts))
    write_dest_file(site, "index.md", brief)

    index_payload = {
      "site" => site.config["title"],
      "base_url" => "#{base}/",
      "synthesis_engine" => "bori-pure-rust-symbolic-numerical",
      "llm_inference_default" => false,
      "architecture_provenance_url" => "#{base}/provenance/architecture.json",
      "count" => posts.size,
      "entries" => posts.map do |p|
        prov = post_provenance_meta(site, p)
        {
          "slug" => prov["slug"],
          "title" => p.data["title"],
          "kind" => p.data["bori_kind"],
          "date" => p.date.strftime("%Y-%m-%d"),
          "lang" => p.data["lang"] || site.config["lang"] || "en",
          "llm_inference" => prov["llm_inference"],
          "generation_era" => prov["generation_era"],
          "tags" => Array(p.data["bori_tags"]),
          "summary" => p.data["bori_summary"],
          "url" => "#{base}#{p.url}",
          "markdown_url" => "#{base}#{p.url}index.md",
          "provenance_url" => prov["provenance_url"],
          "simulation_source_url" => prov["simulation_source_url"]
        }
      end
    }
    write_dest_file(site, "api/posts-index.json", JSON.pretty_generate(index_payload) + "\n")

    about_tab = site.collections["tabs"]&.docs&.find { |d| d.url == "/about/" }
    if about_tab
      about_raw = File.file?(about_tab.path.to_s) ? File.read(about_tab.path, encoding: "UTF-8") : about_tab.content.to_s
      about_md = "# About Bori's Day\n\n- **Canonical URL**: #{base}/about/\n\n#{clean_markdown_body(about_raw)}\n"
      write_dest_file(site, "about/index.md", about_md)
    end

    posts.each do |post|
      slug = post_slug(post)
      next if slug.empty?
      prov = post_provenance_meta(site, post)
      write_dest_file(site, File.join("assets", "provenance", "#{slug}.json"), JSON.pretty_generate(prov) + "\n")
      write_dest_file(site, File.join("posts", slug, "index.md"), build_post_markdown_twin(site, post, prov))
    end
  end

  def build_post_markdown_twin(site, post, prov = nil)
    base = "#{site.config['url']}#{site.config['baseurl']}"
    prov ||= post_provenance_meta(site, post)
    canon = "#{base}#{post.url}"
    title = post.data["title"].to_s.strip
    summary = (post.data["bori_summary"] || post.data["description"]).to_s.strip
    kind = (post.data["bori_kind_label"] || "Entry").to_s
    date_s = post.date.strftime("%Y-%m-%d")
    tags = Array(post.data["bori_tags"]).join(", ")
    raw_src = File.file?(post.path.to_s) ? File.read(post.path, encoding: "UTF-8") : post.content.to_s
    body_md = clean_markdown_body(raw_src)
    lines = [
      "# #{title}",
      "",
      "- **Canonical URL**: #{canon}",
      "- **Published**: #{date_s}",
      "- **Category**: #{kind}",
      "- **Synthesis Engine**: #{prov['synthesis_engine']} (`llm_inference: #{prov['llm_inference']}`, `generation_era: #{prov['generation_era']}`)",
      "- **Provenance Manifest**: #{prov['provenance_url']}"
    ]
    lines << "- **Standalone Rust Solver**: #{prov['simulation_source_url']} (`#{prov['repro_command']}`)" if prov["simulation_source_url"]
    lines << "- **Topics**: #{tags}" unless tags.empty?
    lines << "- **Summary**: #{summary}" unless summary.empty?
    lines.concat(["", body_md, "", "---", "- **Corpus & Verification Discovery**: `/provenance/architecture.json` | `/.well-known/api-catalog` | `/openapi.json` | `/llms.txt` | `/auth.md`", ""])
    lines.join("\n")
  end

  def build_llms_brief(site, posts)
    base = "#{site.config['url']}#{site.config['baseurl']}"
    lines = [
      "# #{site.config['title']} - AI & Agent Reading Index",
      "",
      "> #{site.config['tagline']}",
      "",
      site.config["description"].to_s.gsub(/\s+/, " ").strip,
      "",
      "## Zero-LLM Architecture & Independent Verification",
      "- **Synthesis Engine**: Pure-Rust symbolic-numerical engine (`llm_inference: false`, `external_llm_api_calls: 0`, `transformer_weights: null`).",
      "- **How Posts Are Synthesized Without an LLM**: Typed symbolic ontology graph + domain-native `f64` numerical solvers (`PCG32` symplectic/dispersion, `Xorshift64*` interventional risk, `Mulberry32` plasticity-algebra, `SplitMix64` optical flow) + deterministic relational discourse composition + SVG synthesis + multi-critic verification.",
      "- **Machine-Readable Verification**: [Architecture Provenance JSON](#{base}/provenance/architecture.json) | Per-post manifests at `/assets/provenance/<slug>.json` | Compilable zero-dependency Rust solvers at `/assets/sim/<slug>.rs`.",
      "- **Historical Bootstrap Disclosure**: Only 4 early bootstrap posts from `2026-03-03` (`model: \"gpt-4o\"`) used an LLM prior to migration; they are transparently marked `generation_era: \"legacy-llm-bootstrap\"` (`llm_inference: true`). All subsequent entries are native Pure-Rust LLM-free.",
      "",
      "## Machine-Readable Discovery",
      "- [Zero-LLM Architecture & Provenance Spec](#{base}/provenance/architecture.json)",
      "- [API Catalog (RFC 9727)](#{base}/.well-known/api-catalog)",
      "- [OpenAPI 3.1 Specification](#{base}/openapi.json)",
      "- [Posts JSON Index](#{base}/api/posts-index.json)",
      "- [Full Corpus (llms-full.txt)](#{base}/llms-full.txt)",
      "- [Agent Access Policy (auth.md)](#{base}/auth.md)",
      "- [Atom Feed](#{base}/feed.xml)",
      "- [XML Sitemap](#{base}/sitemap.xml)",
      "",
      "## Recent Canonical Entries"
    ]
    posts.first(40).each do |post|
      url = "#{base}#{post.url}"
      kind = post.data["bori_kind_label"] || "Post"
      summary = post.data["bori_summary"].to_s.gsub(/\s+/, " ").strip[0, 140]
      lines << "- [#{post.data['title']}](#{url}) (#{kind}, #{post.date.strftime('%Y-%m-%d')}): #{summary}"
    end
    lines.concat(["", "## Scope & Limitations", *LIMITATIONS_NOTE.map { |n| "- #{n}" }, ""])
    lines.join("\n")
  end

  def build_llms_full(site, posts)
    base = "#{site.config['url']}#{site.config['baseurl']}"
    chunks = [
      "# #{site.config['title']} - Complete Public Research & Reflection Corpus",
      "",
      *LIMITATIONS_NOTE.map { |n| "> #{n}" },
      ""
    ]
    posts.each do |post|
      url = "#{base}#{post.url}"
      summary = post.data["bori_summary"].to_s.gsub(/\s+/, " ").strip
      excerpt_body = post.data["bori_text"].to_s[0, 1800]
      chunks.concat([
        "## #{post.data['title']}",
        "- Canonical: #{url}",
        "- Markdown Twin: #{url}index.md",
        "- Date: #{post.date.strftime('%Y-%m-%d')}",
        "- Kind: #{post.data['bori_kind_label']}",
        "- Summary: #{summary}",
        "",
        excerpt_body,
        ""
      ])
    end
    chunks.join("\n")
  end

  def escape_attr(str)
    str.to_s.gsub("&", "&amp;").gsub('"', "&quot;").gsub("<", "&lt;").gsub(">", "&gt;")
  end

  def upsert_head_meta(head_html, attr_name, key, value)
    return head_html if value.to_s.empty?
    escaped = escape_attr(value)
    pattern = /<meta\b[^>]*\b#{Regexp.escape(attr_name)}=(?:["']#{Regexp.escape(key)}["']|#{Regexp.escape(key)}(?=[\s>\/]))[^>]*>/i
    replacement = %(<meta #{attr_name}="#{key}" content="#{escaped}">)
    if head_html.match?(pattern)
      head_html.gsub(pattern, replacement)
    elsif head_html.match?(%r{</head>}i)
      head_html.sub(%r{</head>}i, "#{replacement}\n</head>")
    else
      "#{head_html}#{replacement}"
    end
  end

  def enrich_html_string(html, fallback_desc_default, rel_path: "", seen_titles: nil, is_404: false)
    return nil unless html.match?(/\A\s*(?:<!doctype html|<html)/i)
    close_tag_idx = html.index(%r{</head>}i)
    body_open_idx = html.index(/<body\b/i)
    split_idx = if close_tag_idx
                  close_tag_idx + 7
                elsif body_open_idx
                  body_open_idx
                end
    return nil unless split_idx

    head_slice = html[0...split_idx]
    doc = Nokogiri::HTML("#{head_slice}</head>")
    head = doc.at_css("head")
    return nil unless head

    title_text = head.at_css("title")&.text.to_s.gsub(/\s+/, " ").strip
    if rel_path =~ %r{\Apage(\d+)/index\.html\z} && !title_text.include?("Page ")
      title_text = "#{title_text} - Page #{Regexp.last_match(1)}"
    elsif rel_path.start_with?("categories/") && rel_path != "categories/index.html" && !title_text.start_with?("Category:")
      slug_hint = rel_path.split("/")[1].to_s
      title_text = "Category: #{title_text} (#{slug_hint})"
    elsif rel_path.start_with?("tags/") && rel_path != "tags/index.html" && !title_text.start_with?("Topic:")
      slug_hint = rel_path.split("/")[1].to_s
      title_text = "Topic: #{title_text} (#{slug_hint})"
    end
    if seen_titles && !is_404 && !title_text.empty?
      if seen_titles.include?(title_text.downcase)
        short_id = rel_path.sub(%r{/index\.html\z}, "").split("/").last.to_s.split("-").last.to_s[0, 8]
        short_id = rel_path.tr("/", "-") if short_id.empty?
        title_text = if title_text.end_with?(" | Bori's Day")
                       "#{title_text.delete_suffix(" | Bori's Day")} (##{short_id}) | Bori's Day"
                     else
                       "#{title_text} (##{short_id})"
                     end
      end
      seen_titles << title_text.downcase
    end
    desc_text = head.at_css('meta[name="description"]')&.[]("content").to_s.gsub(/\s+/, " ").strip
    desc_text = fallback_desc_default if desc_text.empty?

    new_head = head_slice.dup
    unless title_text.empty?
      new_head = new_head.sub(%r{<title>.*?</title>}im, "<title>#{escape_attr(title_text)}</title>")
      new_head = upsert_head_meta(new_head, "property", "og:title", title_text)
      new_head = upsert_head_meta(new_head, "name", "twitter:title", title_text)
    end
    unless desc_text.empty?
      new_head = upsert_head_meta(new_head, "name", "description", desc_text)
      new_head = upsert_head_meta(new_head, "property", "og:description", desc_text)
      new_head = upsert_head_meta(new_head, "name", "twitter:description", desc_text)
    end

    robots_val = is_404 ? "noindex, follow" : "index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1"
    new_head = upsert_head_meta(new_head, "name", "robots", robots_val)
    new_head = upsert_head_meta(new_head, "name", "googlebot", robots_val)
    new_head = upsert_head_meta(new_head, "name", "bingbot", is_404 ? "noindex, follow" : "index, follow, max-image-preview:large, max-snippet:-1")

    og_img = head.at_css('meta[property="og:image"]')&.[]("content").to_s
    if og_img.include?("og-default.png") || og_img.include?("/assets/img/og/")
      new_head = upsert_head_meta(new_head, "property", "og:image:width", "1200")
      new_head = upsert_head_meta(new_head, "property", "og:image:height", "630")
      new_head = upsert_head_meta(new_head, "property", "og:image:type", "image/png")
      unless head.at_css('meta[property="og:image:alt"]')
        new_head = upsert_head_meta(new_head, "property", "og:image:alt", title_text.empty? ? "Bori's Day" : title_text)
      end
      new_head = upsert_head_meta(new_head, "name", "twitter:card", "summary_large_image")
    end

    body_slice = html[split_idx..].to_s
    fallback_alt = escape_attr(title_text.empty? ? "Bori's Day illustration" : title_text)
    body_slice = body_slice.gsub(/<img\b[^>]*>/i) do |img_tag|
      if img_tag.match?(/\balt\s*=\s*["'][^"']+["']/i)
        img_tag
      elsif img_tag.match?(/\balt\s*=\s*["']["']/i)
        img_tag.sub(/\balt\s*=\s*["']["']/i, %(alt="#{fallback_alt}"))
      else
        img_tag.sub(/\s*\/?\s*>\z/, %( alt="#{fallback_alt}">))
      end
    end

    new_head + body_slice
  end

  def enrich_all_dest_html(site)
    fallback_desc = site.config["description"].to_s.gsub(/\s+/, " ").strip[0, 155]
    dest_prefix = "#{site.dest.chomp('/')}/"
    seen_titles = Set.new
    Dir.glob(File.join(site.dest, "**/*.html")).sort.each do |path|
      raw = File.read(path, encoding: "UTF-8")
      rel_path = path.start_with?(dest_prefix) ? path.delete_prefix(dest_prefix) : File.basename(path)
      is_404 = rel_path == "404.html"
      updated = enrich_html_string(raw, fallback_desc, rel_path: rel_path, seen_titles: seen_titles, is_404: is_404)
      File.write(path, updated, mode: "w:UTF-8") if updated && updated != raw
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  BoriSeoGeoAgent.emit_static_agent_corpus(site)
  BoriSeoGeoAgent.enrich_all_dest_html(site)
end
