# SUREON independent reader validation

> **Reviewer**: GitHub Copilot — independent frontend validation

Status: **FINAL READY — local render verified; production remains unrepaired.**

All relative evidence paths below are under `logs/2026-11-03/sureon-validation/`.

## Final source identity and scope

- Post: `_posts/2026-11-02-2603-06570v2.md`.
- Independently verified complete source SHA-256: `d7f1e0207d4b0133f9aac7e9b7e57622305f023550ac1b87b862afeaa8a3a829`.
- Supplied authored-body digest matches the source's `visual_body_sha256`: `e2dcd75556902896839511529784f861440811fd0eb772d8fb00b979ac3257d6`. The producer owns canonical body normalization; this check does not substitute a different raw-whitespace hash.
- Final HTML: `site/bori-blog/posts/2603-06570v2/index.html`.
- Final HTML SHA-256: `6241e986ca25af50704c100628961ae9275a8f2011703653c164dfd938dd6002`.
- Original URL `/bori-blog/posts/2603-06570v2/` and publication field `2026-11-02 16:22:54 +0900` are unchanged. The known historical UTC/KST labeling problem is not reinterpreted here.
- This agent did not edit any post or agent-san file. The only functional frontend edit is the five-line print-only block appended to `assets/css/reader.scss`.

## Before → after

| Reader measurement | Public before | Final local render |
|---|---:|---:|
| Parent's canonical prose count | 211 | 1,891 |
| Main article headings | 3 | 9: eight roles + References |
| Broken TOC targets | 1 (`href="#"`) | 0 |
| References section | absent | present |
| Evidence paragraphs with associated citations | no paper links | 35/35 |
| Actual outline nodes | none | 9/9, all linked |
| Emotional hero / CF | 1 / 1 | 0 / 0 |
| SV / duplicated CTA | not used as evidence | 0 / 0 |
| Horizontal page overflow, 390/1440 | 0 / 0 px | 0 / 0 px |

No public-before horizontal-overflow defect was reproduced; this report does not invent one.

Independent rendered prose measurement is **1,887 whitespace-delimited tokens in 35 substantive paragraphs**, excluding References, standalone citation paragraphs, tables, visual cards, and URLs. The stricter English-letter token counter is 1,799. These are explicitly different tokenizers from the producer's 1,891 and are not represented as the same count. All remain within the requested 1,200–2,000 prose-word range.

The current canonical BlogPosting schema has **2,328 rendered-content tokens**. The pre-DOI build's 2,335 count was independently checked against the existing reader counter; replacing the raw DOI URL text with the short clickable label changes that supplementary-text count, not the 1,891-word prose. Schema tokens are **not** used to inflate evidence-prose length.

## Executed validation

- Actual final Jekyll production build, Ruby 3.3.13 Docker, existing `.bundle/gems`, source mounted read-only, isolated destination, `--disable-disk-cache`: **success, 28.103 seconds**.
- Existing `tools/reader-check.rb`: **16 assertions passed**.
- Existing `tools/visual-reader-check.rb`: **191 checks passed**, including 19 existing actual-input posts and 54 SVG labels. No fixture-post copying was used.
- Hash-bound `render-check.rb` on the license-ready predecessor: **84 checks passed**, no failures, including the actual license hyperlink in article References.
- Full actual Playwright mobile/desktop/print assertions on the layout predecessor: **0 failures**, JavaScript page errors **0**, captured console errors **0**.
- License-only delta: **eight freshness/invariant checks passed**. Final DOI-only delta: **14 targeted checks passed**, covering three DOM invariants, DOI click, preserved license/version references, authors, publication metadata and figure hash; current source/body identity was additionally asserted and the HTML digest recorded. Fresh final References screenshots and a fresh complete PDF include both legal and DOI links. Unchanged full layout suites were not rerun.
- Helpers: `node --check after-browser.js` and `bash -n build.sh` passed. The Ruby checker was executed successfully, not merely syntax checked.

### Navigation, citations and bibliography

- Main headings are exactly Overview; Problem and context; Method; Data and curation; Evaluation design; Results; Limitations; Interpretation; References.
- Both viewport TOCs have ten valid targets: all nine main sections plus the Table 4 subheading.
- All nine mobile TOC links were actually clicked. Target headings settled **55.6–88.1 px** below the viewport top, rather than merely changing the URL hash.
- Nine outline SVG rectangles and nine textual links resolve to the actual headings; mobile SVG label size is approximately **15.3 px** after scaling. Print retains all nine textual entries.
- **35 substantive prose paragraphs** each have an immediately following source-citation paragraph. The report does not falsely describe those links as nested inside the prose paragraph's DOM node.
- Four paragraphs are explicitly marked `Interpretation.`.
- **14 unique local navigation targets** resolve against the built site; **25 unique fixed-paper arXiv links** resolve, including every cited fragment.
- The fixed `2603.06570v2` arXiv HTML/abstract endpoints both returned HTTP 200. The final explicitly requested DOI check additionally performed one real Control-click into a new tab: `https://doi.org/10.48550/arXiv.2603.06570` returned **302**, resolving to `https://arxiv.org/abs/2603.06570` with **200** and the correct paper title. The original article test page remained open. The DOI is version-independent; explicit v2 abstract/full-paper references remain separately available. Other external destinations were not probed.
- All twelve author names and the title match the fixed arXiv abstract's citation metadata. The 2026-10-30 v2 date matches submission history; the abstract's v1 `citation_date` was not mistaken for the v2 date.
- One canonical BlogPosting, original publication date and URL, and valid JSON-LD were verified.
- No leaked Liquid/HTML/Markdown, tested raw-math fragments, PDF control fragments, or Unicode replacement characters were found in article text.

### Table 4 and print-only repair

The one article table contains the header plus exactly three stage rows:

| Stage | Reported pairs | Video % | Blind % | Gain, percentage points |
|---|---:|---:|---:|---:|
| 1 | 176.6K | 22.4 | 13.7 | 8.7 |
| 2 | 176.6K | 39.5 | 22.7 | 16.8 |
| 3 | 76K | 48.2 | 19.1 | 29.1 |

At 390 px the table is 1,000 px wide inside a **358 px** keyboard-focusable scrolling region. Actual ArrowRight input moves it **40 px**; left/right screenshots show the accessible columns. Desktop scrolling remains available. No screen content is suppressed.

The first local print-media test exposed a real defect: a **1,030 px** nowrap table was clipped inside a **714 px** region. The print-only repair makes wrapper overflow visible, constrains table width, and permits cell wrapping. The final table is **714/714 px**, and all five header-cell bounds are inside the region (rightmost edge 754 px in the 794 px emulated viewport).

`after-print.pdf` was generated using Chromium A4 output. This proves browser print-media layout and PDF generation, **not compatibility with every physical printer**. Existing print behavior hides duplicate outline SVG shapes while retaining their complete textual alternative; no new rule hides article text, warnings, figures, or table cells.

### Figure and provenance

- Actual paper Figure 3 is local PNG `source-pipeline-1bf04e7d08ad48564188.png`, **227,541 bytes**, **2040×431** intrinsic pixels.
- SHA-256: `1bf04e7d08ad485641889ad7d06fae8fe1c3f6693433f5dceb7c2b53ba572b31`.
- Visible caption explicitly identifies **Paper Figure 3**, reproduced unchanged, and calls it a research-data pipeline, **not a guide to performing surgery**.
- Visible credit identifies Perez et al., SUREON v2, Figure 3; license is **CC BY 4.0**, distinct from the dataset's non-commercial/share-alike license.
- The source-title SVG is separately labeled **original typography, not a paper figure**.
- Figure and title preview load without cropping or aspect distortion at both widths. The figure is approximately **327 px** wide on mobile and **544 px** on desktop: its small internal labels are **not claimed readable at those sizes**.
- The figure-credit link has an explicit accessible external-source label and a **44 px** target. An actual click reaches `https://arxiv.org/html/2603.06570v2#S3.F3`; that figure exists and its original PNG loads at 2040×431. No native inline zoom control is claimed.
- Article References additionally contain the actual clickable **CC BY 4.0** link to `https://creativecommons.org/licenses/by/4.0/`, visible in both screen and print media. Its URL was inspected without broadening external network checks to another host.

## Warnings and remaining limitations — not “all quality green”

1. **Two generic pipeline warnings remain: R08 and R17**, per the parent's current revalidated receipt (**0 errors, 2 warnings**). The parent fixed the R03 table-row false warning in common code. This agent did not independently run that Python pipeline or relabel warnings as zero.
2. Jekyll emits **two pre-existing destination conflicts**: `assets/img/favicons/site.webmanifest` and `categories/journal/index.html`. Build succeeds; complete output remains in `build.log`.
3. Figure microtext requires inspecting the original at higher magnification. Its working paper-source link is provided; mobile thumbnail readability is not asserted.
4. Scientific/clinical claim validation belongs to the parent's source-evidence review; this frontend validation does not establish clinical readiness.
5. **Production is still unrepaired**: the latest independent public-browser observation still sees Summary/Findings/Recommendation, no References, one CF, and the emotional hero. Local success is not a deployment claim.

## Screenshot and machine evidence

Minimum requested views were captured and visually inspected:

- `after-390-intro.png`
- `after-390-method.png`
- `after-1440-results.png`
- `after-390-limits.png`
- `after-390-references.png`
- `after-390-figure.png`, `after-1440-figure.png`
- `after-390-table-left.png`, `after-390-table-right.png`
- `print-table-before-fix.png`, `after-print-table.png`
- `figure-original-paper-mobile.png`
- `production-final-mobile.png`

Machine evidence: `source-identity.json`, `doi-freshness.json`, `doi-click.json`, `render-check.json`, `after-browser.json`, `layout-invariants-before-license.json`, `license-freshness.json`, `final-extra-meter.json`, `figure-original-link.json`, `production-final.json`; before evidence remains in `before-browser.json` and `before-toc-interaction.json`.

`pre-update-browser.json` is superseded exploratory output, not final proof. The final screenshot capture uses settled/instant positioning so method/results/references images actually show their named sections.

`after-browser.json` and non-References layout screenshots correspond to the validated layout predecessor `5189cc59…`; the three matching final DOM fingerprints establish that those areas are unchanged in `d7f1e020…`. `render-check.json` records the successful 84-check license-ready predecessor `48884b10…`; it is not misrepresented as a rerun on the DOI-only delta. The final `source-identity.json` and `doi-freshness.json` identify the current build. References screenshots and PDF were regenerated from that build.

One reused isolated browser initially returned stale content at the license stage despite a successful disk check; `license-stale-session.json` preserves that observation. A fresh isolated session removed the stale state. The final DOI stage also used a new isolated session; the current browser schema count is **2,328**.

## Hardening and operational safety

The complete new validation helpers and the exact print-only CSS change were reread. No new Critical/High issue was found after targeted validation. The change does not add display/visibility hiding, source rewriting, remote publishing, or production toggles. No commit, push, deployment, production restart, or configuration/authorization widening occurred. Task-owned browser and local server are stopped before handoff.
