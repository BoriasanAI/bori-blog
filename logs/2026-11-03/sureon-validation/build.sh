#!/usr/bin/env bash
set -euo pipefail
cd /home/moonchoi/dev/bori-blog
output="$PWD/logs/2026-11-03/sureon-validation"
docker run --rm --user "$(id -u):$(id -g)" \
  -e BUNDLE_PATH=/site/.bundle/gems \
  -e BUNDLE_APP_CONFIG=/output/bundle \
  -e HOME=/output -e JEKYLL_ENV=production \
  -v "$PWD:/site:ro" -v "$output:/output" -w /site ruby:3.3 \
  bundle exec jekyll build --destination /output/site/bori-blog --disable-disk-cache \
  > "$output/build.log" 2>&1
test -s "$output/site/bori-blog/posts/2603-06570v2/index.html"
printf 'Build HTML: %s/site/bori-blog/posts/2603-06570v2/index.html\n' "$output"
