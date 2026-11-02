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
      "outline" => "Article map / 글 지도",
      "evidence-map" => "Citation map / 인용 지도",
      "timeline" => "Publication timeline / 발행 연표",
      "comparison" => "Source comparison / 출처 비교"
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
    offset = 12
    shapes = diagram["nodes"].map.with_index do |node, index|
      rows = svg_lines(node["label"]).size
      height = [54, 25 + rows * 21].max
      y = offset
      offset += height + 18
      <<~SVG
        <g><rect x="12" y="#{y}" width="296" height="#{height}" rx="9"/>
        <circle cx="30" cy="#{y + 22}" r="3"/>
        #{wrapped_svg_label(node['label'], 44, y + 28)}</g>
      SVG
    end.join
    <<~HTML
      <figure class="rv-diagram rv-outline">
        <figcaption><h3>#{escape(diagram_title(diagram))}</h3><p>Article outline / 글의 구성 · supplied headings, not causal links / 인과관계 아님</p></figcaption>
        <div class="rv-outline-layout"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 #{offset}" aria-hidden="true" focusable="false">#{shapes}</svg>
        #{node_list(diagram['nodes'], baseurl, ordered: true)}</div>
      </figure>
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
        <figcaption><h3>#{escape(diagram_title(diagram))}</h3><p>#{bounds.first} — #{bounds.last} · Dated records; spacing is not duration / 날짜 기록 · 간격은 기간을 나타내지 않음</p></figcaption>
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
        <figcaption><h3>#{escape(diagram_title(diagram))}</h3></figcaption>
        <p class="rv-scroll-hint">Scroll horizontally for both columns / 두 열을 보려면 가로로 밀어 주세요.</p>
        <div class="rv-table-scroll" role="region" tabindex="0" aria-label="#{escape(diagram_title(diagram))} — horizontally scrollable / 가로 스크롤">
          <table><caption>Supplied excerpts side by side / 입력된 발췌 비교 · No inferred rankings / 순위 추정 없음</caption>
            <thead><tr><th scope="col">Source / 출처</th><th scope="col">Supplied note / 입력된 내용</th></tr></thead>
            <tbody>#{rows}</tbody>
          </table>
        </div>
      </figure>
    HTML
  end

  def evidence_map(diagram, baseurl)
    positions = {}
    offset = 12
    shapes = diagram["nodes"].map.with_index do |node, index|
      height = 28 + svg_lines(node["label"]).size * 21
      positions[node["id"]] = [offset, height]
      shape = "<g><rect x=\"42\" y=\"#{offset}\" width=\"266\" height=\"#{height}\" rx=\"3\"/>" \
        "#{wrapped_svg_label(node['label'], 54, offset + 27)}</g>"
      offset += height + 42
      shape
    end.join
    labels = diagram["nodes"].to_h { |node| [node["id"], node["label"]] }
    edges = Array(diagram["edges"])
    paths = edges.map.with_index do |edge, index|
      from_y, from_height = positions.fetch(edge["from"])
      to_y, to_height = positions.fetch(edge["to"])
      track = 10 + (index % 4) * 7
      "<path d=\"M42 #{from_y + from_height / 2} H#{track} V#{to_y + to_height / 2} H42\"/>"
    end.join
    alternatives = edges.map do |edge|
      "<li>#{escape(labels.fetch(edge['from']))} → #{escape(labels.fetch(edge['to']))}" \
        "#{edge['label'] ? " — <strong>#{escape(edge['label'])}</strong>" : ""}</li>"
    end.join
    <<~HTML
      <figure class="rv-diagram rv-evidence-map">
        <figcaption><h3>#{escape(diagram_title(diagram))}</h3><p>Supplied source links / 입력된 출처 연결 · not causal inference / 인과 추론 아님</p></figcaption>
        <div class="rv-outline-layout"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 #{offset}" aria-hidden="true" focusable="false">#{paths}#{shapes}</svg>
        <div>#{node_list(diagram['nodes'], baseurl)}<ul class="rv-edge-list" aria-label="Supplied relationships / 입력된 연결">#{alternatives}</ul></div></div>
      </figure>
    HTML
  end
end
