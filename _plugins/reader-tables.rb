# frozen_string_literal: true

require "nokogiri"

module BoriTables
  module_function

  def enhance(output)
    return output unless output.match?(/<table\b/i)
    document = Nokogiri::HTML(output)
    document.css("article .content table").each_with_index do |table, index|
      wrapper = table.parent
      unless wrapper["class"].to_s.split.include?("table-wrapper")
        wrapper = Nokogiri::XML::Node.new("div", document)
        wrapper["class"] = "table-wrapper"
        table.replace(wrapper)
        wrapper.add_child(table)
      end
      wrapper["role"] = "region"
      wrapper["tabindex"] = "0"
      table.css("thead th").each { |cell| cell["scope"] = "col" }
      table.css("tbody tr").each do |row|
        cell = row.element_children.first
        next unless cell && %w[td th].include?(cell.name)
        cell.name = "th"
        cell["scope"] = "row"
      end
      caption = table.at_css("caption")
      unless caption
        heading = wrapper.xpath("preceding::*[self::h2 or self::h3 or self::h4]").last
        caption = Nokogiri::XML::Node.new("caption", document)
        caption["data-supplemental"] = "true"
        caption.content = heading ? heading.text.strip : "Data table"
        table.prepend_child(caption)
      end
      caption["id"] ||= "reader-table-caption-#{index}"
      wrapper["aria-labelledby"] = caption["id"]
      source = [wrapper.previous_element, wrapper.next_element].compact.find do |node|
        node.name == "p" && node.text.match?(/\A\s*Source\b/i) && node.at_css("a[href]")
      end
      if source && !caption.at_css("a")
        caption.add_child(Nokogiri::XML::Text.new(" · Source: ", document))
        source.css("a[href]").each { |anchor| caption.add_child(anchor.dup) }
      end
      hint = Nokogiri::XML::Node.new("p", document)
      hint["class"] = "table-scroll-hint"
      hint["id"] = "reader-table-hint-#{index}"
      hint.content = "More columns → Scroll horizontally or focus the table and use the arrow keys."
      wrapper["aria-describedby"] = hint["id"]
      wrapper.add_previous_sibling(hint)
    end
    document.to_html
  end
end

Jekyll::Hooks.register :posts, :post_render do |post|
  post.output = BoriTables.enhance(post.output)
end
