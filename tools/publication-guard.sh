#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"
work="$(mktemp -d)"
trap 'rm -f -- "$work/policy" "$work/commits" "$work/paths"; rmdir -- "$work"' EXIT
rustc --edition=2021 -D warnings tools/publication-policy.rs -o "$work/policy"

while read -r local_ref local_oid remote_ref remote_oid; do
  if [[ "$local_oid" =~ ^0+$ ]]; then
    continue
  fi
  if [[ "$remote_oid" =~ ^0+$ ]]; then
    git rev-list "$local_oid" > "$work/commits"
  else
    git cat-file -e "$remote_oid"
    git rev-list "$remote_oid..$local_oid" > "$work/commits"
  fi
  while IFS= read -r commit; do
    git diff-tree --root -m --no-commit-id --no-renames --diff-filter=AM \
      -r --name-only -z "$commit" -- _posts assets/img/posts _data > "$work/paths"
    while IFS= read -r -d '' path; do
      case "$path" in
        *.md|*.svg|*.html|*.json|*.yml|*.yaml)
          if ! git show "$commit:$path" | "$work/policy" --stdin; then
            echo "Public push blocked: $path at $commit requires disclosure review." >&2
            exit 1
          fi
          ;;
      esac
    done < "$work/paths"
  done < "$work/commits"
done
