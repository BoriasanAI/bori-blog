# frozen_string_literal: true

module BoriVisuals
  module_function

  def validate_diagrams(diagrams, source_ids)
    list(diagrams, 2, "diagrams").each_with_index do |diagram, index|
      at = "diagrams[#{index}]"
      object(diagram, %w[kind title nodes edges events], at)
      text(diagram["title"], "#{at}.title", 300)
      raise Invalid, "#{at}.kind: unsupported diagram" unless %w[outline evidence-map timeline comparison].include?(diagram["kind"])
      nodes = list(diagram.fetch("nodes", diagram["kind"] == "timeline" ? [] : nil), 12, "#{at}.nodes")
      ids = []
      nodes.each_with_index do |node, node_index|
        place = "#{at}.nodes[#{node_index}]"
        object(node, %w[id label url detail], place)
        id = text(node["id"], "#{place}.id", 100)
        raise Invalid, "#{place}.id: invalid or duplicate ID" unless id.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/) && !ids.include?(id)
        ids << id
        text(node["label"], "#{place}.label", 300)
        text(node["detail"], "#{place}.detail") if node.key?("detail")
        url(node["url"], "#{place}.url") if node.key?("url")
      end
      raise Invalid, "#{at}: empty diagram" if nodes.empty? && diagram["kind"] != "timeline"
      if diagram["kind"] == "comparison"
        raise Invalid, "#{at}: comparison needs at least two supplied rows" if nodes.size < 2
        nodes.each { |node| text(node["detail"], "#{at}.nodes[].detail") }
      end
      if diagram["kind"] == "timeline"
        raise Invalid, "#{at}.nodes: use dated events for timelines" unless nodes.empty?
        events = list(diagram["events"], 12, "#{at}.events")
        raise Invalid, "#{at}.events: at least one dated event is required" if events.empty?
        events.each do |event|
          object(event, %w[date label url], "#{at}.events[]")
          date(event["date"], "#{at}.events[].date")
          text(event["label"], "#{at}.events[].label", 500)
          url(event["url"], "#{at}.events[].url") if event.key?("url")
        end
      elsif diagram.key?("events")
        raise Invalid, "#{at}.events: only timelines accept events"
      end
      if diagram.key?("edges")
        list(diagram["edges"], 18, "#{at}.edges").each do |edge|
          object(edge, %w[from to label], "#{at}.edges[]")
          %w[from to].each do |key|
            raise Invalid, "#{at}.edges[].#{key}: unknown node" unless ids.include?(edge[key])
          end
          text(edge["label"], "#{at}.edges[].label", 200) if edge.key?("label")
        end
        if diagram["kind"] != "evidence-map" && !diagram["edges"].empty?
          raise Invalid, "#{at}.edges: only evidence-map accepts explicit relationships"
        end
      end
    end
  end

  def node_list(nodes, baseurl, ordered: false)
    tag = ordered ? "ol" : "ul"
    "<#{tag} class=\"rv-node-list\">" + nodes.map do |node|
      label = escape(node["label"])
      label = link(node["label"], node["url"], baseurl) if node["url"]
      "<li><span>#{label}</span>#{node['detail'] ? "<p>#{escape(node['detail'])}</p>" : ""}</li>"
    end.join + "</#{tag}>"
  end

  def diagram_title(diagram)
    return diagram["title"] unless diagram["title"] == diagram["kind"]
    {
      "outline" => "Article map",
      "evidence-map" => "Citation map",
      "timeline" => "Publication timeline",
      "comparison" => "Source comparison"
    }.fetch(diagram["kind"])
  end

  SVG_LINE_UNITS = 28

  def svg_lines(label, width = SVG_LINE_UNITS)
    remaining = label.dup
    lines = []
    until remaining.empty?
      units = 0
      count = remaining.each_char.take_while do |character|
        units += character.ord >= 0x2e80 ? 2 : 1
        units <= width
      end.size
      count = 1 if count.zero?
      part = remaining[0, count]
      boundary = part.rindex(/\s/)
      count = boundary + 1 if count < remaining.length && boundary && boundary.positive?
      lines << remaining.slice!(0, count).strip
    end
    lines
  end

  def wrapped_svg_label(label, x, y, width = SVG_LINE_UNITS)
    lines = svg_lines(label, width)
    spans = lines.each_with_index.map { |line, index| "<tspan x=\"#{x}\" y=\"#{y + index * 21}\">#{escape(line)}</tspan>" }.join
    "<text class=\"rv-svg-label\">#{spans}</text>"
  end

  def outline(diagram, baseurl)
    <<~HTML
      <nav class="rv-diagram rv-outline" aria-label="#{escape(diagram_title(diagram))}">
        <h3>#{escape(diagram_title(diagram))}</h3>
        #{node_list(diagram['nodes'], baseurl, ordered: true)}
      </nav>
    HTML
  end

  def diagrams_html(diagrams, baseurl)
    Array(diagrams).map do |diagram|
      case diagram["kind"]
      when "outline" then outline(diagram, baseurl)
      when "evidence-map" then evidence_map(diagram, baseurl)
      when "timeline" then timeline(diagram, baseurl)
      when "comparison" then comparison(diagram, baseurl)
      else raise Invalid, "diagram renderer not available: #{diagram['kind']}"
      end
    end.join
  end

  def timeline(diagram, baseurl)
    events = diagram["events"].sort_by { |event| date(event["date"], "event date") }
    bounds = events.map { |event| date(event["date"], "event date").iso8601 }
    rows = events.map do |event|
      day = date(event["date"], "event date").iso8601
      label = escape(event["label"])
      label = link(event["label"], event["url"], baseurl) if event["url"]
      "<li><time datetime=\"#{day}\">#{day}</time><div>#{label}</div></li>"
    end.join
    <<~HTML
      <figure class="rv-diagram rv-timeline">
        <figcaption><h3>#{escape(diagram_title(diagram))}</h3><p>#{bounds.first} — #{bounds.last} · Dated records; spacing is not duration</p></figcaption>
        <ol>#{rows}</ol>
      </figure>
    HTML
  end

  def comparison(diagram, baseurl)
    rows = diagram["nodes"].map do |node|
      label = escape(node["label"])
      label = link(node["label"], node["url"], baseurl) if node["url"]
      "<tr><th scope=\"row\">#{label}</th><td>#{escape(node['detail'])}</td></tr>"
    end.join
    <<~HTML
      <figure class="rv-diagram rv-comparison">
        <figcaption><h3>#{escape(diagram_title(diagram))}</h3><p>Supplied excerpts side by side · No inferred rankings or relationships</p></figcaption>
        #{map_svg(diagram)}
        <p class="table-scroll-hint">More columns → Scroll horizontally or focus the table and use the arrow keys.</p>
        <div class="rv-table-scroll" role="region" tabindex="0" aria-label="#{escape(diagram_title(diagram))} — horizontally scrollable">
          <table><caption>Supplied excerpts side by side · No inferred rankings</caption>
            <thead><tr><th scope="col">Source</th><th scope="col">Supplied note</th></tr></thead>
            <tbody>#{rows}</tbody>
          </table>
        </div>
      </figure>
    HTML
  end

  MAP_WIDTH = 640
  MAP_LABEL_UNITS = 22
  MAP_LINE = 16

  def map_grid(count, row_pitch = 90)
    cols = [count, 2].min
    rows = (count / cols.to_f).ceil
    gap = MAP_WIDTH / (cols + 1.0)
    top = (row_pitch / 2.0).round
    centers = (0...count).map { |i| [gap * (i % cols + 1), top + (i / cols) * row_pitch] }
    [centers, rows * row_pitch]
  end

  def map_centers(count, height, pad = 40)
    cx = MAP_WIDTH / 2.0
    cy = height / 2.0 + (count >= 3 ? 15 : 0)
    return [[cx, cy]] if count == 1
    return [[cx - 170, cy], [cx + 170, cy]] if count == 2
    radius_y = [height / 2.0 - pad - 15, 40.0].max
    (0...count).map do |index|
      angle = (-90 + index * 360.0 / count) * Math::PI / 180
      [cx + 210 * Math.cos(angle), cy + radius_y * Math.sin(angle)]
    end
  end

  def map_clip(center, other, half_w, half_h)
    dx = other[0] - center[0]
    dy = other[1] - center[1]
    scale = [dx.zero? ? Float::INFINITY : half_w / dx.abs, dy.zero? ? Float::INFINITY : half_h / dy.abs].min
    [center[0] + dx * scale, center[1] + dy * scale]
  end

  def map_text(lines, x, y, css)
    start = y - (lines.size - 1) * MAP_LINE / 2.0
    spans = lines.each_with_index.map { |line, i| "<tspan x=\"#{x.round(1)}\" y=\"#{(start + i * MAP_LINE).round(1)}\">#{escape(line)}</tspan>" }.join
    "<text class=\"#{css}\" text-anchor=\"middle\" dominant-baseline=\"central\">#{spans}</text>"
  end

  def map_svg(diagram)
    nodes = diagram["nodes"]
    raw_boxes = nodes.map do |node|
      lines = svg_lines(node["label"], MAP_LABEL_UNITS)
      half_h = diagram["kind"] == "comparison" ? [26.0, (lines.size * MAP_LINE + 18) / 2.0].max : (lines.size * MAP_LINE + 18) / 2.0
      { lines: lines, half_w: 92, half_h: half_h }
    end
    max_half_h = raw_boxes.map { |b| b[:half_h] }.max || 26.0
    if diagram["kind"] == "comparison"
      pitch = [(max_half_h * 2 + 24).ceil, 90].max
      centers, height = map_grid(nodes.size, pitch)
    elsif nodes.size <= 2
      height = [150, (max_half_h * 2 + 24).ceil].max
      centers = map_centers(nodes.size, height)
    else
      pad = [40.0, max_half_h + 12.0].max
      height = [340, (pad * 2 + 190).ceil].max
      centers = map_centers(nodes.size, height, pad)
    end
    index_of = nodes.each_with_index.to_h { |node, i| [node["id"], i] }
    boxes = raw_boxes.each_with_index.map { |box, i| box.merge(center: centers[i]) }
    marker = "rv-arrow-#{diagram['title'].to_s.hash.abs}"
    edges = Array(diagram["edges"])
    arrows = edges.map do |edge|
      a = index_of.fetch(edge["from"])
      b = index_of.fetch(edge["to"])
      next "" if a == b
      pa = map_clip(boxes[a][:center], boxes[b][:center], boxes[a][:half_w] + 3, boxes[a][:half_h] + 3)
      pb = map_clip(boxes[b][:center], boxes[a][:center], boxes[b][:half_w] + 5, boxes[b][:half_h] + 5)
      dx = pb[0] - pa[0]
      dy = pb[1] - pa[1]
      length = Math.hypot(dx, dy)
      nx = -dy / length
      ny = dx / length
      shift = edges.any? { |other| other["from"] == edge["to"] && other["to"] == edge["from"] } ? 7 : 0
      sx = pa[0] + nx * shift
      sy = pa[1] + ny * shift
      ex = pb[0] + nx * shift
      ey = pb[1] + ny * shift
      line = "<path class=\"rv-edge\" d=\"M#{sx.round(1)} #{sy.round(1)} L#{ex.round(1)} #{ey.round(1)}\" marker-end=\"url(##{marker})\"/>"
      label = edge["label"] ? map_text(svg_lines(edge["label"], 18).first(2), (sx + ex) / 2 + nx * 12, (sy + ey) / 2 + ny * 12, "rv-svg-edge") : ""
      line + label
    end.join
    shapes = boxes.each_with_index.map do |box, i|
      cx, cy = box[:center]
      "<g><rect x=\"#{(cx - box[:half_w]).round(1)}\" y=\"#{(cy - box[:half_h]).round(1)}\" width=\"#{box[:half_w] * 2}\" height=\"#{(box[:half_h] * 2).round(1)}\"/>" \
        "#{map_text(box[:lines], cx, cy, 'rv-svg-label')}" \
        "<text class=\"rv-svg-index\" x=\"#{(cx - box[:half_w] + 6).round(1)}\" y=\"#{(cy - box[:half_h] + 12).round(1)}\">#{i + 1}</text></g>"
    end.join
    "<svg class=\"rv-map-svg\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 #{MAP_WIDTH} #{height}\" aria-hidden=\"true\" focusable=\"false\">" \
      "<defs><marker id=\"#{marker}\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><polygon class=\"rv-arrowhead\" points=\"0,0 10,5 0,10\"/></marker></defs>" \
      "#{arrows}#{shapes}</svg>"
  end

  def evidence_map(diagram, baseurl)
    labels = diagram["nodes"].to_h { |node| [node["id"], node["label"]] }
    alternatives = Array(diagram["edges"]).map do |edge|
      "<li>#{escape(labels.fetch(edge['from']))} → #{escape(labels.fetch(edge['to']))}" \
        "#{edge['label'] ? " — <strong>#{escape(edge['label'])}</strong>" : ""}</li>"
    end.join
    <<~HTML
      <figure class="rv-diagram rv-evidence-map">
        <figcaption><h3>#{escape(diagram_title(diagram))}</h3><p>Supplied source links · not causal inference</p></figcaption>
        <div class="rv-outline-layout">#{map_svg(diagram)}
        <div>#{node_list(diagram['nodes'], baseurl)}<ul class="rv-edge-list" aria-label="Supplied relationships">#{alternatives}</ul></div></div>
      </figure>
    HTML
  end
end
