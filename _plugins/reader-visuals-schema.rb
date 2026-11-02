# frozen_string_literal: true

require "uri"
require "ipaddr"
require "date"
require_relative "reader-visuals-images"
require_relative "reader-visuals-diagrams"

module BoriVisuals
  class Invalid < StandardError; end

  module_function

  def object(value, keys, at)
    raise Invalid, "#{at}: expected an object" unless value.is_a?(Hash)
    unknown = value.keys - keys
    raise Invalid, "#{at}: unknown fields #{unknown.join(', ')}" unless unknown.empty?
    value
  end

  def text(value, at, max = 2000)
    raise Invalid, "#{at}: expected nonempty plain text (max #{max})" unless value.is_a?(String) &&
      !value.strip.empty? && value.length <= max && !value.match?(/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/)
    value
  end

  def list(value, limit, at)
    raise Invalid, "#{at}: expected an array of at most #{limit}" unless value.is_a?(Array) && value.size <= limit
    value
  end

  def url(value, at)
    text(value, at)
    raise Invalid, "#{at}: unsafe URL" if value.match?(/[\s\\]/) || value.match?(/%(?:00|0a|0d|2e|2f|5c)/i)
    uri = URI.parse(value)
    if value.start_with?("/") && !value.start_with?("//")
      raise Invalid, "#{at}: unsafe internal path" if uri.path.split("/").include?("..")
      return value
    end
    host = uri.host.to_s.downcase
    raise Invalid, "#{at}: expected public HTTPS or a site-relative URL" unless uri.scheme == "https" &&
      !uri.userinfo && uri.port == 443 && host.include?(".") && !host.end_with?(".") &&
      host.split(".").all? { |part| part.match?(/\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/) } &&
      !host.match?(/(?:\A|\.)(?:localhost|local|internal|test|invalid|lan|home|onion)\z/) &&
      !host.match?(/\A(?:0x[0-9a-f]+|\d+)(?:\.(?:0x[0-9a-f]+|\d+))*\z/)
    begin
      address = IPAddr.new(host.delete_prefix("[").delete_suffix("]"))
      raise Invalid, "#{at}: IP literals are not public source names" if address
    rescue IPAddr::InvalidAddressError
      # Host names are checked syntactically; the builder never resolves or fetches them.
    end
    value
  rescue URI::InvalidURIError
    raise Invalid, "#{at}: malformed URL"
  end

  def validate(data, root:)
    object(data, %w[version sources diagrams gallery style], "reader_visuals")
    raise Invalid, "reader_visuals.version: expected integer 1" unless data["version"].is_a?(Integer) && data["version"] == 1
    if data["style"] && !%w[paper essay journal].include?(data["style"])
      raise Invalid, "reader_visuals.style: expected paper, essay, or journal"
    end
    ids = []
    list(data["sources"], 6, "sources").each_with_index do |source, index|
      at = "sources[#{index}]"
      object(source, %w[id url title description authors published kind image], at)
      id = text(source["id"], "#{at}.id", 100)
      raise Invalid, "#{at}.id: invalid or duplicate ID" unless id.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/) && !ids.include?(id)
      ids << id
      text(source["title"], "#{at}.title", 500)
      url(source["url"], "#{at}.url")
      text(source["description"], "#{at}.description") if source.key?("description")
      raise Invalid, "#{at}.kind: expected paper or reference" unless %w[paper reference].include?(source["kind"])
      if source.key?("authors")
        list(source["authors"], 30, "#{at}.authors").each { |author| text(author, "#{at}.authors[]", 200) }
      end
      date(source["published"], "#{at}.published") if source.key?("published")
      local_image(source["image"], root, "#{at}.image") if source.key?("image")
    end
    validate_diagrams(data["diagrams"], ids) if data.key?("diagrams")
    if data.key?("gallery")
      list(data["gallery"], 3, "gallery").each_with_index do |image, index|
        local_image(image, root, "gallery[#{index}]")
        text(image["caption"], "gallery[#{index}].caption")
      end
    end
    unless [data["sources"], data["diagrams"], data["gallery"]].any? { |items| items.is_a?(Array) && items.any? }
      raise Invalid, "reader_visuals: at least one source, diagram, or gallery image is required"
    end
    data
  end

  def date(value, at)
    candidate = value.is_a?(Date) ? value.iso8601 : text(value, at, 10)
    raise Invalid, "#{at}: expected YYYY-MM-DD" unless candidate.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    Date.iso8601(candidate)
  rescue Date::Error
    raise Invalid, "#{at}: invalid calendar date"
  end
end
