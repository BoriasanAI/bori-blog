# frozen_string_literal: true

require "cgi"
require_relative "reader-visuals-schema"

module BoriVisuals
  module_function

  def escape(value)
    CGI.escapeHTML(value.to_s)
  end

  def href(value, baseurl)
    base = baseurl.to_s.sub(%r{/\z}, "")
    internal = value.start_with?("/") && !value.start_with?("#{base}/") && value != base
    escape(internal ? "#{base}#{value}" : value)
  end

  def link(label, value, baseurl)
    external = value.start_with?("https://")
    host = external && URI.parse(value).host
    attributes = external ? " rel=\"external noopener noreferrer\" aria-label=\"#{escape(label)} — external source at #{escape(host)} / 외부 출처\"" : ""
    "<a href=\"#{href(value, baseurl)}\"#{attributes}>#{escape(label)}</a>"
  end

  def image_figure(image, root, baseurl, css = "")
    width, height = local_image(image, root, "image")
    credit = escape(image["credit"])
    credit = link(image["credit"], image["url"], baseurl) if image["url"]
    title_preview = image["path"].match?(%r{\A/assets/img/posts/visual-reference-[a-zA-Z0-9_-]+\.svg\z})
    <<~HTML
      <figure class="rv-image #{css}">
        <img src="#{href(image['path'], baseurl)}" alt="#{escape(image['alt'])}" width="#{width}" height="#{height}" loading="lazy" decoding="async">
        <figcaption>#{title_preview ? '<span class="rv-preview-label">Source-title preview / 출처 제목 미리보기 · Original typography, not a paper figure / 논문 도해 아님</span>' : ""}#{image['caption'] ? "<span class=\"rv-caption\">#{escape(image['caption'])}</span>" : ""}<span class="rv-credit">#{credit} · #{escape(image['license'])}</span></figcaption>
      </figure>
    HTML
  end

  def source_card(source, root, baseurl)
    host = URI.parse(source["url"]).host || "This site / 이 블로그"
    bibliographic = source["kind"] == "paper"
    publication = source["published"] && date(source["published"], "published").iso8601
    archive = { "arxiv.org" => "arXiv", "doi.org" => "DOI", "dx.doi.org" => "DOI" }[host]
    <<~HTML
      <article class="rv-source#{bibliographic ? ' rv-paper-source' : ''}#{source['image'] ? ' rv-has-image' : ''}" id="rv-source-#{escape(source['id'])}">
        #{source['image'] ? image_figure(source['image'], root, baseurl, 'rv-source-image') : '<p class="rv-no-image">Text source / 텍스트 출처 · No licensed preview supplied / 허가된 미리보기 없음</p>'}
        <div class="rv-source-body">
          <div class="rv-source-meta"><span class="rv-host">#{escape(host)}</span><span class="rv-kind">#{bibliographic ? 'Paper / 논문' : 'Reference / 참고'}#{archive ? " · #{archive}" : ""}</span></div>
          <h3>#{link(source['title'], source['url'], baseurl)}</h3>
          #{source['authors']&.any? ? "<p class=\"rv-authors\">#{escape(source['authors'].join(', '))}</p>" : ""}
          #{publication ? "<time class=\"rv-published\" datetime=\"#{publication}\">#{publication}</time>" : ""}
          #{source['description'] ? "<p>#{escape(source['description'])}</p>" : ""}
        </div>
      </article>
    HTML
  end

  def gallery_html(images, root, baseurl)
    return "" if images.nil? || images.empty?
    <<~HTML
      <section class="rv-gallery" aria-label="Licensed image gallery / 허가된 이미지 모음">
        <h3>Image notebook / 이미지 노트</h3>
        <div class="rv-gallery-grid rv-gallery-count-#{images.size}">#{images.map { |image| image_figure(image, root, baseurl) }.join}</div>
      </section>
    HTML
  end

  def outline_targets(data, output, post_url)
    copy = Marshal.load(Marshal.dump(data))
    document = Nokogiri::HTML(output)
    headings = document.css("article .content h2[id], article .content h3[id]").to_h do |heading|
      [heading_key(heading.text), "#{post_url}##{heading['id']}"]
    end
    Array(copy["diagrams"]).select { |diagram| diagram["kind"] == "outline" }.each do |diagram|
      Array(diagram["nodes"]).each do |node|
        key = node.is_a?(Hash) && heading_key(node["label"])
        node["url"] ||= headings[key] if key && headings.key?(key)
      end
    end
    copy
  end

  def heading_key(label)
    label.to_s.unicode_normalize(:nfkc).tr("‘’“”", %q{''""}).gsub(/\s+/, " ").strip
  end

  def render(data, root:, baseurl: "")
    validate(data, root: root)
    style = data.fetch("style", "essay")
    sources = data["sources"].empty? ? "" : "<div class=\"rv-sources rv-count-#{data['sources'].size}\">#{data['sources'].map { |source| source_card(source, root, baseurl) }.join}</div>"
    diagrams = diagrams_html(data["diagrams"], baseurl)
    gallery = gallery_html(data["gallery"], root, baseurl)
    body = { "paper" => [sources, diagrams, gallery], "essay" => [diagrams, sources, gallery],
             "journal" => [diagrams, gallery, sources] }.fetch(style).join
    <<~HTML
      <section class="reader-visuals rv-#{escape(style)}" aria-label="Sources and article maps / 출처와 글 지도" data-visuals-version="1">
        <header class="rv-heading"><p class="rv-kicker">Reading companion / 함께 읽기</p><h2>Sources &amp; maps / 출처와 지도</h2></header>
        #{body}
      </section>
    HTML
  end

  def enhance_post(post)
    return if !post.data.key?("reader_visuals") || post.data["reader_visuals"].nil?
    validate(post.data["reader_visuals"], root: post.site.source)
    data = outline_targets(post.data["reader_visuals"], post.output, post.url)
    html = render(data, root: post.site.source, baseurl: post.site.baseurl)
    marker = /(<div\b[^>]*class=["']content["'][^>]*>)/
    raise Invalid, "article content container is missing" unless post.output.match?(marker)
    post.output = post.output.sub(marker) { "#{html}\n#{Regexp.last_match(1)}" }
  end
end

Jekyll::Hooks.register :posts, :post_render do |post|
  BoriVisuals.enhance_post(post)
rescue BoriVisuals::Invalid => error
  raise Jekyll::Errors::FatalException, "#{post.relative_path}: #{error.message}"
end
