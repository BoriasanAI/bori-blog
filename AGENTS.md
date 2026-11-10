# Public writing policy

This repository is public, including its Git history.

- Never turn private discussions, internal architecture or implementation details,
  operational strategy, competitive analyses, deployment details, logs, or ledgers
  into posts. Do not disguise private reports by renaming identifiers.
- Write only public-source research and non-sensitive personal reflections.
  When disclosure is uncertain, do not draft or publish the material.
- Do not recreate removed internal reports from Git history.
- Validate the entire artifact: title, metadata, translations, fenced code, links,
  and SVG text. Passing formatting checks is not disclosure approval.
- Preserve the Rust disclosure gate and never bypass Git hooks or deployment checks.
  Install the push guard on new clones with
  `install -m 755 tools/publication-guard.sh .git/hooks/pre-push`.
  It checks every outgoing commit, not just the final tree, before public upload.
