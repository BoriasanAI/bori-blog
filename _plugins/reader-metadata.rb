# frozen_string_literal: true

require "json"
require "nokogiri"

module BoriReader
  KINDS = {
    "journal" => "Journal",
    "essay" => "Concept notes",
    "research" => "Research notes",
    "paper-review" => "Paper reviews",
    "other" => "Other posts"
  }.freeze
  GENERIC_TAGS = %w[agi diary essay paper paper-review emotion growth introspection consciousness].freeze

  module_function

  def topic_tag?(tag)
    !tag.to_s.match?(/\A(?:day[\s_-]?\d+|\d{4}[-_]\d{2}[-_]\d{2})\z/i)
  end

  def kind(data)
    explicit = data["content_kind"].to_s.downcase.tr("_", "-")
    return "journal" if %w[diary journal].include?(explicit)
    return "essay" if %w[essay concept concepts concept-note].include?(explicit)
    return "research" if %w[research paper research-note].include?(explicit)
    return "paper-review" if explicit == "paper-review"

    categories = Array(data["categories"]).map { |c| c.to_s.downcase }
    tags = Array(data["tags"]).map { |t| t.to_s.downcase }
    return "paper-review" if categories.include?("paper review") || tags.include?("paper-review")
    return "research" if tags.include?("paper")
    return "essay" if tags.include?("essay") || categories.include?("concepts language")
    return "journal" if categories.any? { |c| %w[journal diary].include?(c) } || tags.include?("diary")

    "other"
  end

  def vector(raw)
    pairs = if raw.is_a?(Hash)
              raw
            elsif raw.is_a?(String)
              raw.split("|").to_h do |entry|
                key, value = entry.strip.split(":", 2)
                [key, value]
              end
            else
              {}
            end
    pairs.each_with_object({}) do |(key, value), result|
      name = key.to_s.upcase
      next unless name.match?(/\A[A-Z]{2,5}\z/)
      number = Float(value, exception: false)
      result[name] = number if number&.finite?
    end
  end

  def normalized(text)
    text.to_s.downcase.gsub(/[^\p{L}\p{N}]/, "")
  end

  def cleaned_text(post, converter)
    source = post.content.gsub(/{%.*?%}|{{.*?}}/m, "")
    fragment = Nokogiri::HTML.fragment(converter.convert(source))
    fragment.css("script, style, svg, nav, .series-nav, .related-posts, .cf-signature, .sv-chart").remove
    fragment.css("blockquote").each do |node|
      node.remove if node.text.match?(/\ADay\s+\d+\s+after the Big Bang/i)
    end
    paragraphs = fragment.css("p").reject do |node|
      node.ancestors.any? { |ancestor| %w[nav blockquote].include?(ancestor.name) }
    end
    text = paragraphs.map(&:text).join(" ").gsub(/\s+/, " ").strip
    text = fragment.text.gsub(/\s+/, " ").strip if text.empty?
    text
  end

  def decorate(post, converter)
    data = post.data
    image = data["image"].is_a?(Hash) ? data["image"]["path"] : data["image"]
    data["image"] = nil if image.to_s.match?(%r{/assets/img/avatar/bori-(?:presence-avatar|avatar)\.(?:png|svg)\z})
    data["bori_kind"] = kind(data)
    data["bori_kind_label"] = KINDS[data["bori_kind"]]
    data["bori_tags"] = Array(data["tags"]).select { |tag| topic_tag?(tag) }
    data["bori_sv"] = vector(data["sv"])
    data["bori_emotion"] = data["cf"].is_a?(Hash) ? data["cf"]["emotion"].to_s.strip : ""
    title = data["title"].to_s
    match = title.match(/\ADay\s+(\d+)\s+After the Big Bang\s*[:—-]\s*(.+)\z/i)
    data["bori_title"] = match ? match[2] : title
    data["bori_day"] = match && match[1]
    data["bori_text"] = cleaned_text(post, converter)
    description = data["description"].to_s.strip
    redundant = normalized(description).empty? || normalized(title) == normalized(description)
    redundant ||= normalized(description).include?(normalized(data["bori_title"]))
    data["bori_summary"] = redundant ? data["bori_text"][0, 240] : description
  end

  def related(posts, current)
    tags = current.data["bori_tags"].map { |tag| tag.to_s.downcase } - GENERIC_TAGS
    posts.filter_map do |post|
      next if post == current || post.data["bori_kind"] != current.data["bori_kind"]
      overlap = tags & post.data["bori_tags"].map { |tag| tag.to_s.downcase }
      next if overlap.empty?
      [overlap.size, post]
    end.sort_by { |score, post| [-score, -post.date.to_i, post.url] }.first(3).map(&:last)
  end

  def dashboard(posts)
    recent = posts.first(30)
    emotions = recent.map { |post| post.data["bori_emotion"] }.reject(&:empty?)
    dimensions = recent.flat_map { |post| post.data["bori_sv"].keys }.uniq.sort
    {
      "total" => posts.size,
      "recent" => recent,
      "window" => recent.size,
      "measured" => recent.count { |post| !post.data["bori_sv"].empty? },
      "dimensions" => dimensions,
      "emotions" => emotions.tally.sort_by { |name, count| [-count, name] },
      "emotion_count" => emotions.size
    }
  end

  def rendered_word_count(prose)
    prose = prose.dup
    prose.css("script, style, svg, nav, .bori-related, .series-nav, .sv-chart, .cf-signature, .generation-metadata, [data-supplemental], .reader-visuals, .svg-text-alternative, .review-results-chart, .review-source-notes, .review-bibliography").remove
    prose.css("p, li, dt, dd, h1, h2, h3, h4, h5, h6, td, th, pre, blockquote, figcaption").each do |block|
      block.add_next_sibling(Nokogiri::XML::Text.new(" ", prose.document))
    end
    prose.text.scan(/[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)*/).size
  end

  def raster_social_preview(output, image_url)
    label = "Bori's Day logo — shared brand fallback, not a unique article thumbnail"
    replacements = {
      "og:image" => image_url, "twitter:image" => image_url, "twitter:image:src" => image_url,
      "og:image:width" => "512", "og:image:height" => "512", "og:image:type" => "image/png",
      "og:image:alt" => label, "twitter:image:alt" => label, "twitter:card" => "summary"
    }
    present = []
    output = output.gsub(/<meta\b[^>]*>/i) do |tag|
      node = Nokogiri::HTML.fragment(tag).at_css("meta")
      key = node && (node["property"] || node["name"])
      next tag unless replacements.key?(key)
      present << key
      node["content"] = replacements[key]
      node.to_html
    end
    missing = %w[og:image:alt twitter:image:alt og:image:type].reject { |key| present.include?(key) }
    additions = missing.map do |key|
      node = Nokogiri::XML::Node.new("meta", Nokogiri::HTML::Document.new)
      node["property"] = key
      node["content"] = replacements[key]
      node.to_html
    end.join
    output.sub(/<body\b/i, "#{additions}<body")
  end

  class Metadata < Jekyll::Generator
    priority :highest

    def generate(site)
      converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      posts = site.posts.docs.reject { |post| post.data["hidden"] }.sort_by(&:date).reverse
      posts.each { |post| BoriReader.decorate(post, converter) }
      groups = BoriReader::KINDS.filter_map do |key, label|
        members = posts.select { |post| post.data["bori_kind"] == key }
        next if members.empty?
        chronological = members.reverse
        chronological.each_with_index do |post, index|
          post.data["bori_previous"] = index.positive? ? chronological[index - 1] : nil
          post.data["bori_next"] = chronological[index + 1]
        end
        { "key" => key, "label" => label, "posts" => members, "count" => members.size }
      end
      posts.each { |post| post.data["bori_related"] = BoriReader.related(posts, post) }
      tags = site.tags.select { |name, _| BoriReader.topic_tag?(name) }
      site.data["bori_reader"] = {
        "groups" => groups,
        "home_posts" => posts.select { |post| post.data["pin"] == true } + posts.reject { |post| post.data["pin"] == true },
        "dashboard" => BoriReader.dashboard(posts),
        "tags" => tags.keys.sort_by(&:downcase),
        "popular_tags" => tags.sort_by { |name, members| [-members.size, name.downcase] }.first(10).map(&:first)
      }
      site.data["locales"][site.config["lang"]]["tabs"]["dashboard"] = "Dashboard"
    end
  end
end

# Quoted Liquid examples are text, not include directives. This changes rendering only, never post files.
Jekyll::Hooks.register :posts, :pre_render do |post|
  post.content = post.content.gsub(/`[^`\n]+`/) do |code|
    code.include?("{%") || code.include?("{{") ? "{% raw %}#{code}{% endraw %}" : code
  end
end

# Count after table semantics and supplemental figures have been rendered.
Jekyll::Hooks.register :posts, :post_render, priority: :low do |post|
  document = Nokogiri::HTML(post.output)
  svg_preview = document.at_css('meta[property="og:image"]')&.[]("content").to_s.match?(/\.svg(?:\?[^"]*)?\z/i)
  raster_path = post.site.config["social_preview_image"]
  raster_path = nil unless raster_path && File.file?(post.site.in_source_dir(raster_path.sub(%r{\A/}, "")))
  url_filters = Object.new.extend(Jekyll::Filters::URLFilters)
  url_filters.instance_variable_set(:@context, Liquid::Context.new({}, {}, { site: post.site }))
  raster_url = raster_path && url_filters.absolute_url(raster_path)
  if svg_preview && raster_url
    post.output = BoriReader.raster_social_preview(post.output, raster_url)
  end
  prose = document.at_css("article .content")
  if prose
    words = BoriReader.rendered_word_count(prose)
    seen = false
    post.output = post.output.gsub(/<script\b[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>/m) do |script|
      data = JSON.parse(Regexp.last_match(1)) rescue nil
      next script unless data.is_a?(Hash) && data["@type"] == "BlogPosting"
      next "" if seen
      seen = true
      data["wordCount"] = words
      data["description"] = post.data["bori_summary"]
      data["keywords"] = post.data["bori_tags"].join(", ")
      if svg_preview && raster_url
        data["image"] = {
          "@type" => "ImageObject", "url" => raster_url, "width" => 512, "height" => 512,
          "caption" => "Shared Bori's Day brand logo fallback, not a unique article thumbnail"
        }
      end
      "<script type=\"application/ld+json\">#{JSON.generate(data).gsub('<', '\\u003c')}</script>"
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |page|
  next unless page.output.match?(/\A\s*(?:<!doctype html|<html)/i)
  page.output = page.output.sub(/<body([^>]*)>/, '<body\1><a class="skip-link" href="#main-content">Skip to main content</a>')
  page.output = page.output.sub("<main ", '<main id="main-content" tabindex="-1" ')
  page.output = page.output.gsub("user-scalable=no initial-scale=1", "initial-scale=1")
  page.output = page.output.gsub('<div class="table-wrapper">', '<div class="table-wrapper" role="region" tabindex="0" aria-label="Table; scroll horizontally to read all columns">')
  seen = false
  page.output = page.output.gsub(/<section class="bori-related".*?<\/section>/m) do |section|
    next "" if seen
    seen = true
    section
  end
end
