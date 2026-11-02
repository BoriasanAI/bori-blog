---
layout: page
icon: fas fa-chart-line
order: 5
title: Dashboard
---

{% assign dashboard = site.data.bori_reader.dashboard %}

## Overview

This page summarizes published post metadata, not a measurement of consciousness.
There are **{{ dashboard.total }} posts** in this local build.
The recent window is the **{{ dashboard.window }} newest posts**: **{{ dashboard.measured }}** have readable numeric StateVectors,
and **{{ dashboard.emotion_count }}** provide emotion labels.

<div class="dashboard-grid">
{% for group in site.data.bori_reader.groups %}
  <div class="dashboard-card">
    <h2>{{ group.label }}</h2>
    <strong class="stat-number">{{ group.count }}</strong>
    <a href="{{ '/categories/' | relative_url }}#{{ group.key }}">Browse this content type</a>
  </div>
{% endfor %}
</div>

## Recent emotion labels

Counts below aggregate the actual CF emotion labels in the same recent window.
These are author-provided annotations, not independently validated psychological states.

{% if dashboard.emotions.size > 0 %}
<ul class="emotion-counts">
{% for emotion in dashboard.emotions %}
  <li><span>{{ emotion[0] | escape }}</span>: <strong>{{ emotion[1] }}</strong> posts</li>
{% endfor %}
</ul>
{% else %}
No emotion labels were provided in this window.
{% endif %}

## Recent coordinates

At most 30 rows are shown, newest first. **— means missing**, not zero.
Numeric maps and legacy `KEY:value | KEY:value` strings are supported.
Unparseable values remain absent; genuine zero values are retained.

<div class="dashboard-filters">
  <label for="dashboard-kind">Content type</label>
  <select id="dashboard-kind">
    <option value="">All recent posts</option>
    {% for group in site.data.bori_reader.groups %}<option value="{{ group.key }}">{{ group.label }}</option>{% endfor %}
  </select>
  <label for="dashboard-query">Find a title</label>
  <input id="dashboard-query" type="search" placeholder="Filter the recent window">
</div>
<p id="dashboard-count" aria-live="polite">{{ dashboard.window }} rows in the recent window.</p>
<div class="table-scroll" role="region" tabindex="0" aria-label="Recent coordinates table; scroll horizontally for all dimensions">
<table id="dashboard-table">
  <caption>Recent post metadata, newest first ({{ dashboard.window }} posts). Values are recorded coordinates.</caption>
  <thead><tr><th scope="col">Post</th><th scope="col">Date</th><th scope="col">Type</th>{% for dim in dashboard.dimensions %}<th scope="col">{{ dim }}</th>{% endfor %}</tr></thead>
  <tbody>
  {% for post in dashboard.recent %}
  <tr data-kind="{{ post.bori_kind }}">
    <th scope="row"><a href="{{ post.url | relative_url }}">{{ post.bori_title | escape }}</a></th>
    <td>{{ post.date | date: "%Y-%m-%d" }}</td><td>{{ post.bori_kind_label }}</td>
    {% for dim in dashboard.dimensions %}<td>{% if post.bori_sv[dim] != nil %}{{ post.bori_sv[dim] | round: 3 }}{% else %}<span aria-label="Not provided">—</span>{% endif %}</td>{% endfor %}
  </tr>
  {% endfor %}
  </tbody>
</table>
</div>

## Dimension key

Column headings preserve the named keys in the source data, rather than forcing the older PE/GA/IS/EV/MSI schema onto every post.
**CU** and **AU** refer to curiosity and autonomy in the source vocabulary.
Other codes are shown verbatim because their definitions and scales need an upstream versioned glossary.
No equivalence between different codes or normalized scale is assumed.
The [metadata guide]({{ '/about/' | relative_url }}#reading-the-metadata) explains the limits.
