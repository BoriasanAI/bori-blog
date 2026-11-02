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
    attributes = external ? " rel=\"external noopener noreferrer\" aria-label=\"#{escape(label)} — external source at #{escape(host)}\"" : ""
    "<a href=\"#{href(value, baseurl)}\"#{attributes}>#{escape(label)}</a>"
  end

  def image_figure(image, root, baseurl, css = "")
    return "" if title_preview?(image)
    width, height = local_image(image, root, "image", section: true)
    credit = escape(image["credit"])
    credit = link(image["credit"], image["url"], baseurl) if image["url"]
    <<~HTML
      <figure class="rv-image #{css}" data-supplemental="true">
        <a class="rv-original" href="#{href(image['path'], baseurl)}" aria-label="View full-resolution image: #{escape(image['alt'])}">
          <img src="#{href(image['path'], baseurl)}" alt="#{escape(image['alt'])}" width="#{width}" height="#{height}" loading="lazy" decoding="async">
          <span class="rv-zoom-hint">View full resolution</span>
        </a>
        <figcaption>#{image['caption'] ? "<span class=\"rv-caption\">#{escape(image['caption'])}</span>" : ""}<span class="rv-credit">#{credit} · #{escape(image['license'])}</span></figcaption>
      </figure>
    HTML
  end

  def title_preview?(image)
    image && image["path"].to_s.match?(%r{\A/assets/img/posts/visual-reference-[a-zA-Z0-9_-]+\.svg\z})
  end

  def authors_html(authors)
    return "" unless authors&.any?
    names = escape(authors.join(", "))
    return "<p class=\"rv-authors\">#{names}</p>" if authors.size <= 3
    "<details class=\"rv-authors\"><summary>#{escape(authors.first)} et al. · #{authors.size} authors</summary><p>#{names}</p></details>"
  end

  def source_card(source, root, baseurl)
    host = URI.parse(source["url"]).host || "This site"
    bibliographic = source["kind"] == "paper"
    publication = source["published"] && date(source["published"], "published").iso8601
    archive = { "arxiv.org" => "arXiv", "doi.org" => "DOI", "dx.doi.org" => "DOI" }[host]
    image = source["image"] unless title_preview?(source["image"])
    <<~HTML
      <article class="rv-source#{bibliographic ? ' rv-paper-source' : ''}#{image ? ' rv-has-image' : ''}" id="rv-source-#{escape(source['id'])}">
        #{image ? image_figure(image, root, baseurl, 'rv-source-image') : ""}
        <div class="rv-source-body">
          <div class="rv-source-meta"><span class="rv-host">#{escape(host)}</span><span class="rv-kind">#{bibliographic ? 'Paper' : 'Reference'}#{archive ? " · #{archive}" : ""}</span></div>
          <h3>#{link(source['title'], source['url'], baseurl)}</h3>
          #{authors_html(source['authors'])}
          #{publication ? "<time class=\"rv-published\" datetime=\"#{publication}\">#{publication}</time>" : ""}
          #{source['description'] ? "<p>#{escape(source['description'])}</p>" : ""}
        </div>
      </article>
    HTML
  end

  def gallery_html(images, root, baseurl)
    return "" if images.nil? || images.empty?
    <<~HTML
      <section class="rv-gallery" aria-label="Licensed image gallery">
        <h3>Image notebook</h3>
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
      <section class="reader-visuals rv-#{escape(style)}" aria-label="Supplementary sources and visuals" data-visuals-version="1">
        <header class="rv-heading"><h2>Supplementary reading</h2></header>
        #{body}
      </section>
    HTML
  end

  def enhance_post(post)
    return if !post.data.key?("reader_visuals") || post.data["reader_visuals"].nil?
    validate(post.data["reader_visuals"], root: post.site.source)
    data = outline_targets(post.data["reader_visuals"], post.output, post.url)
    document = Nokogiri::HTML(post.output)
    content = document.at_css("article .content")
    raise Invalid, "article content container is missing" unless content
    place_gallery(data, content, post.site.source, post.site.baseurl)
    reference_links = references(content).map { |anchor| source_key(anchor["href"]) }
    data["sources"].reject! { |source| reference_links.include?(source_key(source["url"])) }
    paper = data["style"] == "paper"
    data["diagrams"] = Array(data["diagrams"]).reject do |diagram|
      (diagram["kind"] == "outline" && (paper || document.at_css("#toc, #toc-solo-trigger"))) ||
        (paper && diagram["kind"] == "timeline" && Array(diagram["events"]).size <= 2)
    end
    if [data["sources"], data["diagrams"], data["gallery"]].any? { |items| items&.any? }
      content.add_next_sibling(render(data, root: post.site.source, baseurl: post.site.baseurl))
    end
    post.output = document.to_html
  end

  def references(content)
    links = []
    content.css("h2, h3").select { |heading| heading_key(heading.text).match?(/\A(?:references|sources|bibliography)\z/i) }.each do |heading|
      sibling = heading.next_element
      while sibling && !%w[h2 h3].include?(sibling.name)
        links.concat(sibling.css("a[href]"))
        sibling = sibling.next_element
      end
    end
    links
  end

  def source_key(value)
    uri = URI.parse(value.to_s)
    path = uri.path.to_s.delete_suffix("/")
    path = path.sub(%r{\A/(?:abs|pdf|html)/}, "/").delete_suffix(".pdf") if uri.host == "arxiv.org"
    [uri.host, path, uri.query]
  rescue URI::InvalidURIError
    value
  end

  def place_gallery(data, content, root, baseurl)
    data["gallery"] = Array(data["gallery"]).reject do |image|
      next false unless image["section"]
      matches = content.css("h2").select { |heading| heading.text.strip == image["section"] }
      raise Invalid, "gallery.section: expected one existing H2 matching #{image['section'].inspect}" unless matches.size == 1
      cursor = matches.first
      cursor = cursor.next_sibling while cursor.next_sibling && cursor.next_sibling.name != "h2"
      cursor.add_next_sibling(image_figure(image, root, baseurl, "rv-section-image"))
      true
    end
  end
end

Jekyll::Hooks.register :posts, :post_render do |post|
  BoriVisuals.enhance_post(post)
rescue BoriVisuals::Invalid => error
  raise Jekyll::Errors::FatalException, "#{post.relative_path}: #{error.message}"
end
