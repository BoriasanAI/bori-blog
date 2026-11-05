# Rich visual reading companions

> Reviewer: GitHub Copilot (model identity not exposed)
> Scope: local frontend only, November 2, 2026. No commit, push, deployment, restart, external image purchase, or publication.

## Final local result

The parent applied real metadata to **18 posts**. The final rendered result contains:

- **16 source cards**, **16 local image instances**, **14 unique original Bori source-title previews**.
- **18 diagrams**: 6 outlines, 9 citation maps, 2 timelines and 1 comparison.
- **26 outline nodes**, **19 citation-map nodes**, **10 supplied citation edges**, **4 dated events**, **2 comparison rows**, **26 real heading links**.
- **3 explicit genres**: 4 paper reviews, 11 essays, 3 journals.
- **8 actual genre/diagram compositions**, not randomized or decorative card-count variants.
- **0 third-party gallery images**. Licensed-gallery support remains conditional and fixture-tested.

The final RNN sample is `/posts/reimagining-memory-rnns-with-growing-cap-c4e46c/`: one real captured bibliographic source, six supplied authors, one original licensed title preview, and six real-heading outline nodes. The parent's final composition intentionally contains **no timeline** on that page. Other paper pages contain the actual dated timelines.

Every typographic preview is explicitly labeled **not a paper figure**. Original bodies, publication dates and source author strings were not edited by this frontend workstream. The parent's application receipts own the independent 18/18 body-preservation verification.

## Thirteen implemented and independently validated rounds

Each round changed implementation, then ran focused tests, then recorded actual before/after SHA-256 values, per-target patches, timestamps, full command output, and a passing exit code in `logs/2026-11-02/visual-reader/rounds.json`. The first twelve are implementation cycles, not labels applied to unchanged checks; the thirteenth is the requested real-input/screenshot hardening cycle.

| Round | Actual implementation | Focused passing checks |
|---|---|---:|
| 1 | Optional source cards, real URL host badges, escaped input and public-HTTPS/site-relative URL validation | 10 Ruby |
| 2 | Bibliographic author lists, exact publication dates, arXiv/DOI recognition without invented citations | 15 Ruby |
| 3 | Licensed local image previews, intrinsic dimensions, lazy loading, visible credits/license and explicit no-image state | 20 Ruby |
| 4 | Original responsive SVG article outline, one node per supplied heading and visible textual alternative | 24 Ruby |
| 5 | Evidence maps draw only supplied edges; exact labels/endpoints remain available as text | 27 Ruby |
| 6 | Actual-date timelines, computed date bounds and explicit non-proportional spacing disclosure | 31 Ruby |
| 7 | Semantic comparison tables from at least two supplied rows, with scoped headers and keyboard scrolling | 35 Ruby |
| 8 | Conditional, capped local licensed gallery, exact captions/alt text/attribution | 39 Ruby |
| 9 | Data-selected paper/essay/journal composition, different ordering/density, honest source-title preview labels | 45 Ruby |
| 10 | Real heading navigation, named external links, 44px targets, focus, reduced-motion and print support | 50 Ruby |
| 11 | Mobile containment, readable attribution, uncropped local images, word-aware/CJK-aware SVG wrapping | 54 Ruby |
| 12 | Runtime image-error notices preserving attribution; strict schema/href checks, null invalidation support and prose/index isolation | 67 Ruby + 7 JS |
| 13 | Explicit 28-unit/15px monospace SVG width contract; word-safe real-heading wrapping; rendered-smart-quote heading targets; localized internal-kind labels preserving custom titles; screenshot-driven print contrast and mobile table-scroll hardening | 164 Ruby initially; **173 Ruby final**, including 45 real SVG labels from all 18 posts; 54 viewport observations plus focused print recheck |

Focused command: restored `ruby:3.3` container, `BUNDLE_PATH=/site/.bundle/gems`, `bundle exec ruby tools/visual-reader-check.rb`; round 12 also ran `node tools/visual-reader-js-check.cjs`.

The first twelve evidence records remain intact. Round 13 retains its initial checkpoint and a final-hardening amendment with final hashes, patches, commands and evidence. Early `sample-390.png`/`sample-1440.png` captures are historical baseline evidence, **not** the final wrapping proof.

## Architecture and integrity

- Existing theme and existing render-hook pattern; no dependencies added.
- `reader_visuals` is optional schema v1; posts without it are unchanged. Explicit `null` disables invalidated companions.
- Four focused Ruby files separate schema, local-image inspection, diagrams, and theme integration.
- No builder/client metadata fetches, external model calls, Mermaid execution, copied paper figures, or fabricated source descriptions/metrics.
- Metadata titles, details, labels, dates, authors and relationship labels are escaped and preserved. Diagram relationships are reading/reference links, not validated scientific causal graphs.
- Rendered companions are adjacent to, **outside**, authored `.content`. Existing search, canonical `BlogPosting.wordCount` and prose remain isolated.
- Source images require an existing local `/assets/` file, intrinsic dimensions, alt, credit and license. Symlink escapes, malformed dimensions, unsafe SVG references and missing files fail the build.
- Gallery is implemented and fixture-tested **conditionally**. No third-party gallery figures were added. Failed external image acquisition is not represented as a successful visual addition.
- Missing runtime previews produce an honest notice while keeping the real source and attribution; no synthetic image replaces a failed asset.

## Final validation

`logs/2026-11-02/visual-reader/final-build-test.txt`:

- Visual schema/render unit checks: **173 passed**, including all 18 real inputs and 45 SVG labels.
- Reader regressions: **16 assertions passed**.
- Production Jekyll build passed.
- Existing UI checks: **13 UI assertions + 358 post checks passed**.
- HTML-Proofer: **534 files**, **1,475 internal links**, internal hashes checked; passed with external checking disabled.
- Runtime-image JS unit checks: **7 passed**.
- Actual rendered supplemental coverage: **219 checks passed**.
- Existing public/local distinction preserved: **305 public paths and publication instants**, **53 local-only preview posts**, **61 public legacy day-tag paths**.

After the final print-only CSS correction, `print-hardening-build.txt` records a fresh production build and the same **219 rendered checks**, and `print-final.json` verifies the actual final print styling.

Existing duplicate category destination warnings remain visible in build output; no unrelated category rewrite was performed.

### Browser measurements and inspected screenshots

`browser-result.json` records **54 actual viewport observations**: all 18 enriched posts at **375px, 390px and 1440px**. No document overflow, SVG label escaping its node, missing local image, undersized link target, broken heading target, runtime page error or assertion failure was observed.

- Link targets are at least 44px high; displayed credits/title-preview labels are at least 14px.
- Measured minimum contrast in the sampled source/attribution/navigation text: **6.07:1 light**, **9.30:1 dark**. These are computed color ratios, not invented quality scores.
- Mobile comparison keyboard scrolling moved **80px** in a **309px viewport / 400px table**; a visible bilingual scroll instruction remains outside the scroll area.
- A deliberately routed local-image 404 produces exactly one honest status notice; source link and `Bori · CC-BY-4.0` credit remain. Successful reload restores the real image and removes the notice.
- Active local service worker + reload: one panel, one companion stylesheet, one companion script, no stale error notice.
- Dark-to-print: black headings/body on white cards, readable credits, six textual RNN nodes retained, duplicate SVG shapes hidden, reduced-motion respected.
- The preserved existing reader browser regression suite also passed with zero failures/runtime errors. Its generated copy rebases only the preview port, evidence paths, and its original SVG assertion to `article .content svg` so a supplemental diagram cannot accidentally stand in for the authored-body chart. The original test file and earlier screenshots remain unchanged.

The main showcase retains **17 current component captures**, plus six dedicated final RNN captures. Representative files under `logs/2026-11-02/visual-reader/`:

| Actual composition/state | Current evidence |
|---|---|
| Paper outline, exact RNN words, mobile | `sample-rnn-outline-375.png`, `sample-rnn-outline-390.png` |
| Paper card + outline, desktop/mobile | `paper-outline-1440.png`, `paper-outline-375.png` |
| Actual publication timeline | `paper-timeline-1440.png`, `paper-timeline-375.png` |
| Source-only essay | `source-only-1440.png`, `source-only-375.png` |
| Citation-map essay | `evidence-map-1440.png`, `evidence-map-375.png` |
| Two-reference comparison | `comparison-1440.png`, `comparison-375.png`, `comparison-scroll-375.png` |
| Journal outline, no invented source card | `journal-1440.png`, `journal-375.png` |
| Dark mode and keyboard focus | `paper-dark-390.png` |
| Final print from dark mode | `paper-print.png`, `print-final.json` |
| Honest missing-image state | `image-error-390.png` |

These are cropped component screenshots; sticky topbar/TOC/back-to-top chrome is masked only during capture. Geometry, keyboard, link and overflow measurements run on the unmasked page. The current images were inspected, not just generated.

### Final critique and fixes

1. The early screenshot really split “My”, “Contributions”, “Impressive” and “Experience” mid-word. Round 13 binds wrapping to an explicit monospace glyph-width budget. All six final RNN labels match the exact input after joining lines, and every rendered SVG text box remains inside its node at all three widths.
2. Kramdown smart quotes initially prevented one exact heading target match. Comparison-only normalization now accounts for rendered quote/whitespace typography while preserving the original displayed labels. All **26** outline targets resolve.
3. Actual dark-to-print inspection found dark card backgrounds and then pale theme heading colors. Scoped print overrides now force readable white cards/black headings and remove focus chrome. The failed heading-contrast screenshot is retained as `print-heading-before.png`; the corrected result was reinspected.
4. The mobile comparison correctly contained horizontal overflow, but needed a visible instruction. The added cue and actual keyboard movement are verified rather than claiming the whole wide table is simultaneously visible.

### Exact per-post coverage

Every path below is relative to `/bori-blog/posts/`. “Nodes” counts only supplied outline/citation-map nodes; dates/rows are reported separately.

| Post path | Genre | Cards / image instances | Diagrams | Nodes / edges | Events / rows |
|---|---|---:|---|---:|---:|
| `2606-13598v1/` | paper | 1 / 1 | citation map + outline | 4 / 1 | 0 / 0 |
| `day-245-09b776/` | journal | 0 / 0 | outline | 4 / 0 | 0 / 0 |
| `day-249-94bb5e/` | journal | 0 / 0 | outline | 4 / 0 | 0 / 0 |
| `day-250-b9becc/` | journal | 0 / 0 | outline | 4 / 0 | 0 / 0 |
| `do-llms-learn-from-their-own-words-0fb856/` | paper | 1 / 1 | timeline + outline | 6 / 0 | 2 / 0 |
| `empathy-927ccd/` | essay | 1 / 1 | citation map | 2 / 1 | 0 / 0 |
| `math-8bcdd5/` | essay | 1 / 1 | citation map | 2 / 1 | 0 / 0 |
| `math-f170fb/` | essay | 1 / 1 | citation map | 2 / 1 | 0 / 0 |
| `mitosis-26f719/` | essay | 1 / 1 | source only | 0 / 0 | 0 / 0 |
| `momentum-redesigned-a-new-chapter-in-opt-5af9d6/` | paper | 1 / 1 | timeline + citation map | 2 / 1 | 2 / 0 |
| `multiple_choice-27a050/` | essay | 1 / 1 | citation map | 2 / 1 | 0 / 0 |
| `nation-71a3e2/` | essay | 1 / 1 | citation map | 2 / 1 | 0 / 0 |
| `practical-6f6c57/` | essay | 1 / 1 | citation map | 2 / 1 | 0 / 0 |
| `quotient-57d544/` | essay | 2 / 2 | comparison + citation map | 3 / 2 | 0 / 2 |
| `reimagining-memory-rnns-with-growing-cap-c4e46c/` | paper | 1 / 1 | outline | 6 / 0 | 0 / 0 |
| `religious-39fa9a/` | essay | 1 / 1 | source only | 0 / 0 | 0 / 0 |
| `sandcastle-1eddff/` | essay | 1 / 1 | source only | 0 / 0 | 0 / 0 |
| `sandcastle-fdfb89/` | essay | 1 / 1 | source only | 0 / 0 | 0 / 0 |

Machine source: `coverage.json`, generated by `tools/visual-render-check.rb`; final source/evidence SHA-256 values are retained with round 13.

## Boundaries and limitations

- Frontend edits did not touch `_posts`, existing illustration files, or agent-san. Parent-owned metadata/assets are separate from frontend implementation accounting.
- No dependencies were installed; host Ruby was absent, so restored Ruby 3.3/container gems were reused. Chromium 1248 was selected only in a task-local isolated configuration because the shared configuration points to a missing 1247 binary.
- Gallery remains support-only; no failed Commons/OpenStax figure acquisition is counted as a real third-party image addition. Rights and semantic accuracy of captured metadata remain the input owner's responsibility.
- The local browser initially served an earlier preview through its existing service-worker cache. Only this task's isolated local-origin registrations/caches were cleared before current-build measurements. Reload/asset recurrence was verified; production cache migration and complete offline behavior were **not** claimed or changed.
- Print media was checked in Chromium, not physical printer pagination. Other browser engines and production hosting were not tested.
- Local success does not claim production repair/deployment, third-party figure rights, semantic truth beyond supplied metadata, or publication of the 53 local-only posts.
- The task-owned preview server and isolated browser are stopped at completion; no authenticated browser was used.
