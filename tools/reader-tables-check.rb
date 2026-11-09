# frozen_string_literal: true

require "jekyll"
require "nokogiri"
require_relative "../_plugins/reader-tables"

checks = 0
assert = lambda do |condition, message|
  checks += 1
  raise message unless condition
end
source = '<html><body><article><div class="content"><h2>Reported results</h2><table><thead><tr><th>Model</th><th>Score</th></tr></thead><tbody><tr><td>Model A</td><td>22.4%</td></tr></tbody></table><p>Source: <a href="https://arxiv.org/abs/2603.06570v2">Table 3</a></p></div></article></body></html>'
original = Nokogiri::HTML(source)
document = Nokogiri::HTML(BoriTables.enhance(source))
wrapper = document.at_css(".table-wrapper")
assert.call(wrapper && wrapper["role"] == "region" && wrapper["tabindex"] == "0", "table has a keyboard-focusable region")
assert.call(document.at_css("caption").text.strip == "Reported results · Source: Table 3", "caption reuses actual preceding heading and available source reference")
assert.call(document.at_css("caption")["data-supplemental"] == "true", "generated accessibility caption is excluded from canonical prose count")
assert.call(wrapper["aria-labelledby"] == document.at_css("caption")["id"], "scroll region is named by its caption")
assert.call(document.css('thead th[scope="col"]').size == 2, "column scopes")
assert.call(document.css('tbody th[scope="row"]').map(&:text) == ["Model A"], "first body cell is a row header")
assert.call(document.css("tbody tr").map { |row| row.element_children.map { |cell| cell.text.strip } } ==
  original.css("tbody tr").map { |row| row.element_children.map { |cell| cell.text.strip } }, "no table values are changed")
assert.call(wrapper.previous_element["class"] == "table-scroll-hint", "overflow hint is associated with its scroll wrapper")
explicit = source.sub("<table>", '<table><caption>Original authored caption</caption>')
assert.call(Nokogiri::HTML(BoriTables.enhance(explicit)).at_css("caption").text.start_with?("Original authored caption"), "authored captions are preserved")
without_tables = "<article><p>Original authored text, including Unicode symbols (Ψ, ∇, ∞).</p></article>"
assert.call(BoriTables.enhance(without_tables) == without_tables, "ordinary prose without tables is byte-for-byte unchanged")
puts "reader-tables: #{checks} checks passed"
