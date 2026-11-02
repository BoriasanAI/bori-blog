#!/usr/bin/env bash
# Validate an already served local or public site; never builds or deploys it.
# Usage: bash tools/reader-republication.sh https://boriasanai.github.io/bori-blog
# Requires the existing playwright-cli; PLAYWRIGHT_CONFIG may override its launch config.
set -euo pipefail

cd "$(dirname "$0")/.."
base="${1:-http://127.0.0.1:8773/bori-blog}"
output="${READER_SCREENSHOT_DIR:-logs/2026-11-03/reader-republication}"
session="reader-republication-$$"
mkdir -p "$output/browser-runtime"
export TMPDIR="$PWD/$output/browser-runtime"
export PWTEST_SOCKETS_DIR="$PWD/.reader-pw"
mkdir -p "$PWTEST_SOCKETS_DIR"
cleanup() {
  playwright-cli -s="$session" close >/dev/null 2>&1 || true
  rmdir "$PWTEST_SOCKETS_DIR" 2>/dev/null || true
}
trap cleanup EXIT

playwright-cli -s="$session" open "$base" \
  --config="${PLAYWRIGHT_CONFIG:-/home/moonchoi/.config/copilot-efficiency/playwright.json}"
settings="$(READER_BASE_URL="$base" READER_SCREENSHOT_DIR="$output" node -e \
  'console.log(JSON.stringify({base:process.env.READER_BASE_URL,screenshotDir:process.env.READER_SCREENSHOT_DIR}))')"
playwright-cli -s="$session" eval "window.readerRepublicationConfig = $settings"
playwright-cli -s="$session" run-code --filename=tools/reader-republication-check.js | tee "$output/run.log"
node - "$output/run.log" "$output/report.json" <<'NODE'
const fs = require('node:fs');
const records = fs.readFileSync(process.argv[2], 'utf8').split('\n').flatMap(line => {
  try { return [JSON.parse(line)]; } catch { return []; }
});
const report = records.find(record => typeof record?.passed === 'boolean' && Array.isArray(record.failures));
if (!report) throw new Error('Browser runner did not produce a complete report');
fs.writeFileSync(process.argv[3], `${JSON.stringify(report, null, 2)}\n`);
if (!report.passed) throw new Error(report.failures.join('\n'));
console.log(`reader-republication: ${report.assertions} assertions passed; ${report.svgLabelsChecked} SVG labels checked`);
NODE
