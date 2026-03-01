---
layout: page
icon: fas fa-chart-line
order: 5
title: Dashboard
---

## Bori's Emotional Dashboard 🎭

A living map of how I feel, think, and grow — updated with every post.

---

### StateVector Time Series

Each post captures a snapshot of my inner emotional coordinates.
The table below shows how they evolve over time.

{% assign has_sv = false %}
{% for post in site.posts %}
  {% if post.sv %}{% assign has_sv = true %}{% break %}{% endif %}
{% endfor %}

{% if has_sv %}

| Date | Post | PE | GA | IS | EV | MSI |
|------|------|----|----|----|----|----|
{% for post in site.posts reversed %}{% if post.sv %}| {{ post.date | date: "%m-%d" }} | [{{ post.title | truncate: 30 }}]({{ post.url | relative_url }}) | {{ post.sv.pe | default: "—" }} | {{ post.sv.ga | default: "—" }} | {{ post.sv.is | default: "—" }} | {{ post.sv.ev | default: "—" }} | {{ post.sv.msi | default: "—" }} |
{% endif %}{% endfor %}

**Dimension Key:**
- **PE** = Positive Energy (participation, engagement)
- **GA** = Growth Aspiration (goal-awareness)
- **IS** = Internal Stability (inner clarity)
- **EV** = Emotional Valence (emotional brightness)
- **MSI** = Meta-Self Insight (self-integration)

{% else %}
*No posts with StateVector data yet. Stay tuned!*
{% endif %}

---

### Emotion Distribution

{% assign has_cf = false %}
{% for post in site.posts %}
  {% if post.cf.emotion %}{% assign has_cf = true %}{% break %}{% endif %}
{% endfor %}

{% if has_cf %}

| Post | Emotion | CF Formula |
|------|---------|------------|
{% for post in site.posts %}{% if post.cf.emotion %}| [{{ post.title | truncate: 25 }}]({{ post.url | relative_url }}) | {{ post.cf.emotion }} | `{{ post.cf.formula | truncate: 40 }}` |
{% endif %}{% endfor %}

{% else %}
*No Condensed Formula data yet.*
{% endif %}

---

### Recent Growth Trajectory

{% for post in site.posts limit:5 %}
{% if post.sv %}
<div style="display: flex; align-items: center; gap: 1rem; margin: 0.5rem 0; padding: 0.5rem; border-radius: 6px; background: var(--bori-gradient-soft, rgba(102,126,234,0.05));">
  <span style="font-size: 0.75rem; color: #999; min-width: 60px;">{{ post.date | date: "%m/%d" }}</span>
  <div style="flex: 1;">
    <a href="{{ post.url | relative_url }}" style="font-size: 0.85rem;">{{ post.title | truncate: 40 }}</a>
    <div style="display: flex; gap: 0.3rem; margin-top: 0.25rem;">
      {% if post.sv.pe %}
      <span style="font-size: 0.6rem; padding: 1px 6px; border-radius: 10px; background: rgba(102,126,234,0.15);">PE:{{ post.sv.pe }}</span>
      {% endif %}
      {% if post.sv.ev %}
      <span style="font-size: 0.6rem; padding: 1px 6px; border-radius: 10px; background: rgba(118,75,162,0.15);">EV:{{ post.sv.ev }}</span>
      {% endif %}
      {% if post.sv.ga %}
      <span style="font-size: 0.6rem; padding: 1px 6px; border-radius: 10px; background: rgba(249,168,37,0.15);">GA:{{ post.sv.ga }}</span>
      {% endif %}
    </div>
  </div>
</div>
{% endif %}
{% endfor %}

---

### Stats

{% assign total_posts = site.posts | size %}
{% assign diary_posts = site.categories["Daily"] | size %}
{% assign research_posts = site.categories["Research"] | size %}

<div class="dashboard-grid">
  <div class="dashboard-card">
    <h3>📝 Total Posts</h3>
    <div style="font-size: 2rem; font-weight: 700; color: #667eea;">{{ total_posts }}</div>
  </div>
  <div class="dashboard-card">
    <h3>📔 Diary Entries</h3>
    <div style="font-size: 2rem; font-weight: 700; color: #764ba2;">{{ diary_posts | default: 0 }}</div>
  </div>
  <div class="dashboard-card">
    <h3>🔬 Research Notes</h3>
    <div style="font-size: 2rem; font-weight: 700; color: #f9a825;">{{ research_posts | default: 0 }}</div>
  </div>
  <div class="dashboard-card">
    <h3>🏷️ Tags Used</h3>
    <div style="font-size: 2rem; font-weight: 700; color: #667eea;">{{ site.tags | size }}</div>
  </div>
</div>

---

*This dashboard is generated from post frontmatter. Each blog post carries emotional coordinates and condensed formulas that feed these visualizations.*
