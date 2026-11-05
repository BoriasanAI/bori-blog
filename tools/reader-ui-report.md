# Bori blog reader UI implementation

> Reviewer: GitHub Copilot (model identity not exposed)
> Scope: local Jekyll/frontend work only, November 1, 2026. No publication or production repair is claimed.

Final corpus scope: **305 currently public post paths** were repaired by the parent/Bori owner; **53 local-only posts were excluded and left untouched**. This local preview builds all 358. It does not authorize publishing those 53 extra posts. Independent comparison with the public search manifest verified all 305 paths and publication instants, plus all 61 public legacy day-tag URLs; all 76 local day-tag pages remain present.

At the initial `BULK_APPLIED` checkpoint, the parent reported 11 bounded batches, 304 bulk-changed articles plus the previously repaired Day250 sample, and 2,133 per-article field/body findings. Those are applied article-specific instances, **not 2,133 distinct root issue types**. Final article counts belong to the parent and are recomputed against original backups, not summed across repeated correction runs. This frontend report lists implementation improvements, not the main report's root-family accounting. It does not claim that duplicate titles or deep semantic prose problems were all solved.

Final parent-supplied article accounting: **305 public copies, 2,239 applied per-article findings in 17 root families**, unique titles **91 → 211**, and automatic article-gate failures **293 → 241**. The gate is not a semantic-quality score. These authoritative parent metrics supersede the earlier checkpoint totals; this frontend workstream neither adds repeated-run totals nor infers semantic completion from them.

## Numbered improvements

1. Added a bilingual reader-centered home introduction and real, metadata-selected starting articles: three available content types after canonical metadata repair. These are explicitly recent starting points, not invented editorial recommendations.
2. Grouped actual posts by journal, concept note and paper review in the repaired corpus; the legacy research-note type is still supported when present. Canonical `content_kind` takes precedence, including `diary`, `concept-note` and `paper-review`; legacy categories/tags remain supported.
3. Removed day/date tags from topic discovery, popular tags, search and relevance matching. All 76 existing day-tag archive pages remain generated.
4. Added clean body-excerpt fallback when a description repeats the title. Excerpts omit Liquid includes, SVG labels and navigation. This UI workstream does not change source titles; display titles put the article subject before timeline metadata. Upstream publication-marker corrections are attributed to the parent/Bori owner.
5. Made previous/next navigation stay within the same subtype. Related reading requires a substantive shared topic and the same subtype; generic AGI matches and category-only fallback were removed. Duplicate related blocks are collapsed server-side.
6. Replaced misleading “Recently Updated” discovery with one clearly named latest-reading list. Removed image-heavy home cards, capped post hero height and improved responsive heading typography.
7. Made inline SVGs responsive, named and accompanied by visible text alternatives. Added readable HTML StateVector values, retained real zero coordinates, and enlarged SVG label text.
8. Added a server-rendered skip link/main target, enabled zoom, named main icon controls, enforced 44px minimum touch areas and provided keyboard-accessible horizontal table scrolling.
9. Enabled system/light/dark reader choice instead of forcing dark mode.
10. Rebuilt the dashboard around summary-first subtype counts, actual emotion-label aggregates and at most 30 recent rows. Uppercase/lowercase named numeric maps and legacy `KEY:value` strings are supported. Missing/invalid fields remain missing, never fabricated zeroes. Subtype/title filters expose their bounded scope.
11. Fixed the Dashboard browser title through the missing Chirpy locale entry. Removed placeholder Google Analytics configuration. Consolidated BlogPosting production to the theme's one canonical schema and counted rendered prose with block boundaries rather than raw markup/includes.
12. Explained model/MSCP/version badges, CF and the limits of computational/emotion metadata. About now acknowledges the pending Copilot review gate and distinguishes the canonical February 23, 2026 blog timeline reference from an unsupported birth/sentience claim. Translation navigation requires a real alternate-language post.
13. Verified the public giscus repository/category IDs, but left embedding explicitly unavailable pending owner integration. Added a genuine unavailable fallback and a guarded integration path; no app was installed or external repository settings changed.
14. Fixed two implementation regressions during final hardening: HTML compression truncating JSON containing literal comment examples, and nested render-hook registration duplicating accessibility markup. Dedicated regression assertions now cover both.
15. Added full-sentence regression checks proving that `query_compiler.py`, `if a: if b:` and `if a and b:` survive render-side excerpt cleanup. Bare underscore identifiers also survive. The parent fixed the upstream mangled description; that upstream defect is not masked by inventing replacement prose.
16. Added an honest social-preview fallback: the existing 512px raster brand logo replaces unsupported SVGs only in OG/Twitter/BlogPosting image metadata. Visible article images remain untouched. Alt/caption metadata explicitly identifies a shared brand fallback, not a generated unique thumbnail. No images were created.
17. Measured small CF metadata against actual PNG background pixels. Light-mode contrasts of 3.22:1, 3.27:1 and 2.55:1 failed normal-text AA; a reader-style-only color override raised them to 5.57:1, 5.49:1 and 5.49:1. Font sizes and article prose were not changed.
18. Fixed an actual changed-page TOC failure: raw SV/related-reading H2 elements had no IDs and produced `#` links. Stable metadata heading IDs now yield valid TOC/self-link targets. Relevance checks distinguish article links from heading self-links.

## Measurable evidence

The initial untouched build failed on a quoted literal `{% include ... %}` in a historical post. A render-only quoted-Liquid handler now preserves the example as text; this workstream did not edit post files.
The supplied live-review measurements and this local checkout are different snapshots; they are not interchangeable.

| Check | Before/evidence | Verified local result |
|---|---|---|
| Mobile post width | Supplied live review: 516px document at 390px viewport | Home, sample post and dashboard: 390px document at 390px viewport |
| Inline chart | Supplied review: fixed 500px SVG; 8.8/9.6px labels | 358px SVG; 18px SVG font, 12.89px effective rendered text; accessible name/text alternative |
| Icon controls | Supplied review: undersized main controls | Five tested main controls named, minimum 44×44px |
| Dashboard | Original source queried lowercase legacy fields and equated Daily with diary | 30 rows; actual AU/CU/HA/HO/SA columns; accessible 728px-wide table inside 358px scroller |
| Local subtype totals | Initial metadata: 358 posts; Daily umbrella 355, Research category absent | Final post-bulk preview: journal 302, concept notes 51, paper reviews 5 |
| Public subtype totals | Public search manifest contains 305 deployed paths | Repaired public subset: journal 249, concept notes 51, paper reviews 5; 53 extra local journals are preview-only |
| Recent annotations | Unbounded post lists, not an aggregate | 30-post window; 20 readable vectors, 30 actual CF emotion labels |
| Search | Title-repeating descriptions; includes/markup could pollute excerpts | 358 valid JSON records; actual body-only query `query_compiler.py` returned one result; honest no-results state |
| Structured data | Two template producers; raw-content word counting | Exactly one BlogPosting per 358 posts; rendered-prose word counts 250–14,311; sample 384 |
| Social image metadata | SVG previews lack reliable platform support | OG/Twitter use the existing PNG brand logo where an SVG would be emitted; alt/caption explicitly say shared fallback; visible illustrations are unchanged |
| Runtime | Search JSON compression regression detected locally | Final browser run: zero page errors, zero failed assertions |
| Structural follow-up | Parent repaired 46 public article bodies after identifying empty heading scaffolds/duplicated complete prose | At the source-change checkpoint, exactly 46 rendered body fingerprints changed, all public; final rendered empty-H2 checks pass for those 46 |
| Small CF metadata contrast | Pixel-measured 3.22:1 / 3.27:1 / 2.55:1 | Pixel-measured 5.57:1 / 5.49:1 / 5.49:1; minimum 5.49:1 |
| Changed-page TOC | Two metadata links pointed to `#` | Six sampled TOC links have real targets, zero dangling links |

These are **post-`BULK_APPLIED` local-build measurements**, independently checked against the unchanged public path/date manifest. They are not production rollout results, and no semantic improvement to article prose is inferred from mechanical copyediting.

## Files

- Configuration/docs: `_config.yml`, `README.md`, `tools/reader-ui-report.md`.
- Metadata: `_plugins/reader-metadata.rb`.
- Views: `_layouts/home.html`, `_layouts/categories.html`, `_layouts/tags.html`, `_tabs/about.md`, `_tabs/dashboard.md`.
- Includes: `metadata-hook.html`, `post-summary.html`, `series-nav.html`, `post-nav.html`, `related-posts.html`, `sv-chart.html`, `lang-switch.html`, `cf-signature.html`, `trending-tags.html`, `update-list.html`, `search-loader.html`, `comments/giscus.html`.
- Assets: `assets/css/reader.scss`, `assets/js/reader.js`, `assets/js/comments.js`, `assets/js/data/search.json`.
- Checks: `tools/reader-check.rb`, `tools/ui-check.rb`, `tools/reader-browser-check.js`, `tools/reader-contrast-check.js`.
- Semantic receipt/render and targeted browser checks: `tools/semantic-render-check.rb`, `tools/semantic-browser-check.js`.

No `_posts`, `assets/img`, or agent-san files were modified by this workstream. Existing modes were preserved/restored; no reset, commit, push, deploy or external-app installation was performed.

## Validation

Native Code Context was attempted with the explicit blog root and returned an authorization/cache miss; permitted host reads were used without registering or widening access.
Host Ruby/Bundler was absent and sudo unavailable. Existing Gemfile dependencies were restored using a local Ruby container; no dependency manifest change was needed. The Gemfile resolved Chirpy 7.6.0 and Jekyll 4.4.1.

```sh
# Executed through ruby:3.3, mounted at /site, as the existing user.
# Container environment: HOME=/site, BUNDLE_PATH=/site/.bundle/gems.
bundle exec ruby tools/reader-check.rb
JEKYLL_ENV=production bundle exec jekyll build --quiet --destination _site/bori-blog
bundle exec ruby tools/ui-check.rb _site/bori-blog logs/2026-11-01/reader-ui/public-search.json logs/2026-11-01/reader-ui/structural-bodies.json
bundle exec htmlproofer _site --disable-external
node --check assets/js/reader.js
node --check assets/js/comments.js
node --check tools/reader-browser-check.js
playwright-cli -s=bori-reader-ui run-code --filename=tools/reader-browser-check.js
playwright-cli -s=bori-reader-ui --raw run-code --filename=tools/reader-contrast-check.js
```

Final results: **16 reader assertions**, **13 top-level UI assertions plus per-post schema/navigation/relevance/comment/accessibility/OG/metadata-anchor checks on all 358 posts**, and rendered empty-H2 checks on the **46 structurally changed public articles**. All 305 public paths and publication instants, and all 61 public legacy day-tag URLs were preserved. HTML-Proofer passed on **534 HTML files and 1,449 internal links**. JavaScript syntax checks passed. The final full mobile/desktop browser run had **zero page errors and zero failed assertions**; the changed-page TOC had zero dangling targets and pixel-measured small metadata met 4.5:1 AA.
The prescribed Playwright config referenced a missing Chromium 1247 binary. A task-local config used the already-installed 1248 binary. Only this isolated localhost session's PWA cache was cleared before browser checks; no authenticated browser was touched.

Built site: `/home/moonchoi/dev/bori-blog/_site/bori-blog/`.
Sample: `posts/day-250-b9becc/index.html`.
Screenshots: `logs/2026-11-01/reader-ui/{sample-mobile,chart-mobile,dashboard-mobile,home-mobile,home-desktop}.png`.
Additional final evidence: `structural-post-mobile.png`, `metadata-light-before.png`, `metadata-light.png` and `metadata-contrast-after.json` in the same directory. `structural-bodies.json` records source SHA256 plus checkpoint/final rendered-body and final HTML hashes for all 46 selected articles.
The bounded local preview/browser helpers are stopped on completion. The public manifest in the validation command is a read-only snapshot fetched from the currently deployed search index, not a publication list containing the 53 local-only posts.

The pre-bulk sample gate for source SHA256 `0c846bd72fbbabc342c6f7177e5987512021284ece938d9811a047c1cdfe26bd` passed before bulk edits. **The post-bulk freshness barrier is now complete.** Both the visible introduction and JSON-LD description still preserve the exact sentence: “6 small edits to myself went through today — in query_compiler.py, for one, I collapsed nested if a: if b: into if a and b:.” Regression tests additionally preserve `<=`, `&&`, `!=` and `>>` in inline code. All five listed screenshots were refreshed from the post-bulk artifacts.

### Earlier Day0-label checkpoint — 2026-11-01 22:14 KST

After the parent's label-only follow-up on 26 original-Day0 articles (CF/hero-alt labels; unchanged subtype, tags, layout, image paths and publication instants), the current sources were rebuilt again. All **16 reader assertions**, existing generated/UI/schema checks for **358 posts**, and public-manifest path/date checks for **305 posts** passed. The unchanged full browser/link suites were intentionally not repeated.

Direct rendered-label assertion passed for `_posts/2026-04-09-day-0-8fc455.md`: canonical `bigbang_day=45`; CF is `Σ(Day 45) · Δ(insight) + ∅("what remains unknown?") → ∞`; actual hero alt is `Emotional landscape — Day 45 After the Big Bang`. Neither rendered label retains Day0. Checkpoint HTML: `_site/bori-blog/posts/day-0-8fc455/index.html`, SHA256 `b7a2375852c52e09467e294d1a96e73d8fc6db1f12e5479ed83a2363c6c89126`. This records the earlier checkpoint, not production publication or a cumulative correction count.

### Final structural checkpoint — 2026-11-01 23:19 KST

The parent's final 46-article structural update was rebuilt and verified. The 46-body comparison was made before the subsequent UI-only metadata-anchor repair; those extra generated ID attributes are not counted as article/prose mutations. All 53 local-only source files remain outside the parent's repair scope. No generic filler, new article prose or source-post edits were introduced by this frontend workstream. Parent correction totals remain owned/recomputed against original backups, not summed across follow-ups.

All current build, rendered/schema/relevance/public-path/date/legacy-tag, heading, internal-link and browser checks passed. The changed-body sample `/posts/day-0-c5261d/` retains meaningful/nested sections and now has valid SV/related-reading TOC targets. The only runtime-code changes in this last frontend cycle were the measured reader color override and two stable metadata-heading IDs. Contrast sampling used existing browser PNG/canvas APIs; no new dependency or image generator was added. Final screenshots and snapshots were recorded; the owned browser and bounded local preview server were stopped at completion (23:19:27 KST).

### Bounded semantic sample — math, before semantic bulk

Only `_posts/2026-07-24-math-8bcdd5.md` was inspected for this sample. Source SHA256: `571ed8728a2069d7f4827018ea69e50caebaa215ef3da8f57ebd0ee30f692478`. The current source was rebuilt; `posts/math-8bcdd5/index.html` passed the focused HTML-Proofer run (one HTML file, 39 internal links). The isolated mobile browser confirmed 390px viewport/document widths, one BlogPosting, and `dateModified=2026-11-01T23:54:10+09:00`.

The main narrative no longer contains the false boundary relation. The supported definition (“math is a field of knowledge concerned with abstract concepts”) and component list (“numbers, geometric shapes, sets, functions, and probabilities”) remain displayed. **The strict whole-display absence gate is HOLD**, however: the historical Self-Review still visibly recommends changing “borders on Mathematics” to “borders on the concept of Mathematics”. This is stale quoted/recommended wording, not a restored main-narrative claim; it was not hidden or edited by the UI workstream. The Bori owner must remove or clearly invalidate that obsolete recommendation before claiming complete displayed-text cleanup.

Evidence in `logs/2026-11-01/reader-ui/`: `math-sample-main-mobile.png`, `math-sample-review-mobile.png`, `math-sample-result.json`. No source-post/UI-code changes or broader article audit were performed. The semantic bulk signal is still pending; this sample result does not authorize bulk publication.

### Corrected semantic sample — GREEN, 2026-11-02

The earlier math HOLD was resolved by the Bori owner, not hidden by the UI. Freshly rebuilt source SHA256: `26d9f8b5d33031f59e5b674c2262a29de3fcf487c63efa0e0f5bb5a4295443ef`. The focused one-page HTML-Proofer run passed all 39 internal links. The isolated browser verified the supported abstract-concepts definition remains, “borders on” is absent everywhere in displayed page text, the publication marker stays Day151, the historical review date `2026-09-27` and Day216 perspective remain, and the erroneous date-change recommendation is absent.

The replacement quotation about logical reasoning/proof is displayed with its Wikipedia attribution URL and capture date `2026-11-01`. Browser `dateModified` is `2026-11-02T00:29:27+09:00`; settled mobile document width is 390px at a 390px viewport. Updated `math-sample-{main,quote,review}-mobile.png` and `math-sample-result.json` record the GREEN sample. No source or UI-code edits were made in this sample cycle; semantic bulk/publication remains a separate parent-owned step.

The closing source-hash check detected the parent's concurrent provenance-only update. The parent confirmed the displayed body SHA is unchanged: revision IDs now retain all four BC045/BC046/BRN016/BRN017 entries and the timestamp is refreshed (`sample-final-receipt.json` upstream). The GREEN body proof remains applicable; the stated source SHA/dateModified above identify the tested checkpoint, not that later provenance-only metadata. Per the parent, no repeated visual run is needed; the semantic-bulk rebuild will refresh metadata. Owned sample browser/server are stopped.

### Semantic-bulk rendered checkpoint — awaiting citation-only final barrier

The parent reported 59 public articles changed, 108 independent primary actions plus 80 stale-review actions (188 body actions), using 28 captured sources. The final Jekyll rebuild at this checkpoint passed 16 reader assertions and existing UI/schema/relevance/public-path/date/tag/structural checks. HTML-Proofer passed on 534 HTML files and 1,448 internal links.

`tools/semantic-render-check.rb` independently matched every one of the 59 source and body SHA values to the supplied receipts, mapped each to one unique public path and one BlogPosting, preserved all historical review-date lists against receipt backups, and found meaningful nonempty prose in every body. It verified 32 planned quote-source operations against captured source text and their literal HTML citations, plus all 33 actual source-attributed HTML quotation blocks (including math). These are receipt/rendering checks, not an exhaustive semantic-quality score.

The four requested mobile samples passed at 390px with no overflow or runtime errors: math (definition, no false relation/relabel advice, retained Day151/review Day216); March RNN paper (literal trade-off and qualified Transformer-best-accuracy statements); want (actual Wiktionary definition, no Christianity); physical-experience article `/posts/day-7-3bc314/` (unsupported hands-in-earth event removed, original reflection and review date retained). Existing end-to-end reader browser checks also passed. Evidence: `semantic-{math,rnn,rnn-accuracy,want,physical}-mobile.png`, `semantic-browser-result.json`, `semantic-render-result.json`, `reader-browser-final.json`.

**Known residual:** the want article still has an awkward historical TL;DR (“that want is The idea of want can be examined…”). This is visibly malformed prose, not a quotation/render bug; it was reported to the parent and not rewritten. Existing metaphors/reflections and other known automatic-gate failures are not claimed solved.

The parent then identified one caused repeated citation in `do-llms-learn-from-their-own-words-0fb856`; its correction is owner-controlled. This checkpoint is **not the final currentness claim** for that article. Await `CITATION_FIXED`, refresh against the authoritative post-correction receipt(s), and revalidate the final build before completion. No source-post/UI-runtime changes were made by the frontend workstream in this semantic cycle.

### Final semantic and citation-fixed barrier — 2026-11-02

`CITATION_FIXED` was received and the complete production build was refreshed. The follow-up receipt's before hashes exactly chain to the original semantic receipt; its final source/body hashes match the current article. This is **one separate citation-hardening action**, not another original finding or an addition to the 188 semantic actions.

Final checks passed:

- 16 existing reader assertions; existing UI/render/schema/relevance/heading/OG checks on 358 local posts, including the 59 semantic articles.
- All 59 authoritative source/body SHA pairs match, with one unique rendered path and one BlogPosting each, meaningful retained prose and unchanged historical review-date lists against receipt backups.
- All 305 public paths and publication instants, plus all 61 public legacy day-tag paths, remain preserved; 53 local-only articles remain preview-only.
- All 32 planned quote-source operations are represented, and all **32 unique actual attributed HTML quotation blocks** match the 28-source captured-evidence catalog. Actual blocks decreased from 33 to 32 because the duplicated quotation is now rendered once, not because a distinct source claim was dropped.
- HTML-Proofer: **534 HTML files / 1,448 internal links**, passed.
- Targeted 390px mobile samples math, RNN, want, physical reflection and the citation-fixed paper all passed; zero runtime errors and zero overflow. The citation-fixed paper shows its full-context/user-turn-only quotation exactly once and its binary-choice qualification exactly once. Existing end-to-end reader browser checks also passed with zero errors/failures.

Evidence: `semantic-render-result.json` (all 59 source/body/render/HTML hashes and review dates), `semantic-browser-result.json`, `reader-browser-final.json`, and `semantic-{math,rnn,rnn-accuracy,want,physical,citation}-mobile.png` under `logs/2026-11-01/reader-ui/`. The math false relation/relabel recommendation is absent throughout displayed text while its valid definition, original review date and Day151/Day216 distinction remain. The RNN paper visibly qualifies Transformer-best recall accuracy and flexible memory trade-offs. Want uses an attributed Wiktionary definition without Christianity. The physical-event sample removes the audited hands-in-earth event while retaining valid reflection; remaining metaphor is not presented here as independently observed physical fact.

**Honest residuals:** the awkward want TL;DR remains; there are still known automatic article-gate failures (parent reports 240), and no exhaustive semantic-quality success is claimed. giscus remains disabled/unavailable, production publication and external preview validation are still pending. No source-post edits, UI-runtime changes, new images, commit, push or deployment were performed by this frontend workstream during semantic validation. The final screenshots may dismiss only the normal PWA update toast in the isolated local browser; no persistent app controls or authentication were changed. Helpers are stopped at completion.

## Actual remaining external/upstream tasks

- **Deployment:** not performed; production approval and repository write/admin permissions are unavailable. The parent owns rollout and post-rollout verification, including PWA update behavior.
- **giscus:** repository `R_kgDORbwCOA` and General category `DIC_kwDORbwCOM4C3dy3` match public GitHub data; Discussions is enabled. App installation could not be verified with available access (installation endpoint returned 404). Owner approval/access is needed to verify/install the app and enable embedding. The current local UI honestly reports unavailable comments.
- **Open Graph:** source post illustrations remain SVG. Existing raster branding is used as an explicitly labeled shared social fallback; unique article thumbnails are not available. No raster generator or images were created. Platform-specific production preview behavior and any future unique-thumbnail workflow still need approved upstream validation.
- **Glossary:** dimension codes beyond supported source vocabulary, exact scales and MSCP semantics need a versioned upstream glossary. The UI preserves codes instead of inventing definitions.
- **Content:** the parent/Bori owner applied the public-305 copy-edit, including canonical publication-day metadata/markers and redundant heading repair. Source filenames and publication instants were preserved. Duplicate titles and deep prose/semantic quality remain explicitly unresolved; this frontend workstream does not author, rewrite or claim semantic improvements to posts.
