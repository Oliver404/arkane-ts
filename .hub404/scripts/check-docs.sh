#!/usr/bin/env bash
# scripts/check-docs.sh — verify the Wiki docs.
#
# Checks:
#   1. Every .md under docs/wiki/ has YAML frontmatter with title, version,
#      created, last_modified.
#   2. Every cross-doc markdown link resolves to an existing .md file.
#   3. Every frontmatter `version:` matches docs/VERSIONS.md's most-recent
#      declared version.
#
# Usage:   ./scripts/check-docs.sh
# Exit 0 on success, 1 on any failure.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIKI_DIR="$ROOT/docs/wiki"
VERSIONS_FILE="$ROOT/docs/VERSIONS.md"

fail=0

# -------- 1) Frontmatter --------
echo "[1/3] Verifying frontmatter on every wiki file..."

issues=()
while IFS= read -r -d '' md; do
  rel="${md#"$ROOT"/}"
  first_line="$(head -n 1 "$md")"
  if [[ "$first_line" != "---" ]]; then
    issues+=("$rel: missing frontmatter (first line is not '---')")
    continue
  fi
  # Grab the frontmatter block (up to the next '---' on its own line)
  fm="$(awk 'NR==1{next} /^---$/{exit} {print}' "$md")"
  for field in title version created last_modified; do
    if ! grep -qE "^${field}:" <<<"$fm"; then
      issues+=("$rel: missing field '$field'")
    fi
  done
done < <(find "$WIKI_DIR" -name '*.md' -print0)

if [[ "${#issues[@]}" -gt 0 ]]; then
  echo "  FAIL:"
  for i in "${issues[@]}"; do
    echo "    $i"
  done
  fail=1
else
  echo "  OK"
fi

# -------- 2) Cross-doc links --------
echo "[2/3] Verifying cross-doc links..."

broken=()
while IFS= read -r -d '' md; do
  rel="${md#"$ROOT"/}"
  dir="$(dirname "$rel")"
  # Extract markdown link targets: [text](target)
  # Skip http(s), mailto, anchors.
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    [[ "$target" =~ ^https?:// ]] && continue
    [[ "$target" =~ ^mailto: ]] && continue
    [[ "$target" =~ ^# ]] && continue
    # Strip anchor
    target_no_anchor="${target%%#*}"
    [[ -z "$target_no_anchor" ]] && continue
    # Skip directory-only targets (those end with '/').
    [[ "$target_no_anchor" =~ /$ ]] && continue
    # Resolve relative to file's directory.
    target_path="$target_no_anchor"
    # Strip leading './'
    target_path="${target_path#./}"
    abs="$ROOT/$dir/$target_path"
    # Normalize the path
    abs_norm="$(cd "$(dirname "$abs")" && pwd)/$(basename "$abs")"
    if [[ ! -f "$abs_norm" ]]; then
      broken+=("$rel: [$target]")
    fi
  done < <(grep -oE '\]\([^)]+\)' "$md" | sed -E 's/^\]\(//; s/\)$//')
done < <(find "$WIKI_DIR" -name '*.md' -print0)

if [[ "${#broken[@]}" -gt 0 ]]; then
  echo "  FAIL:"
  for b in "${broken[@]}"; do
    echo "    $b"
  done
  fail=1
else
  echo "  OK"
fi

# -------- 3) Version consistency --------
echo "[3/3] Verifying version consistency..."

declared_version="$(
  awk '/^## / {v=$0; sub(/^## /, "", v); sub(/ — .*/, "", v); print v; exit}' \
    "$VERSIONS_FILE"
)"

if [[ -z "$declared_version" ]]; then
  echo "  FAIL: could not parse most-recent version from $VERSIONS_FILE"
  fail=1
else
  echo "  declared: $declared_version"
  mismatches=()
  while IFS= read -r -d '' md; do
    rel="${md#"$ROOT"/}"
    fm_version="$(awk 'NR==1{next} /^---$/{exit} /^version:/{print $2; exit}' "$md")"
    if [[ -z "$fm_version" ]]; then
      mismatches+=("$rel: no version in frontmatter")
    elif [[ "$fm_version" != "$declared_version" ]]; then
      mismatches+=("$rel: frontmatter version '$fm_version' != declared '$declared_version'")
    fi
  done < <(find "$WIKI_DIR" -name '*.md' -print0)
  if [[ "${#mismatches[@]}" -gt 0 ]]; then
    echo "  FAIL:"
    for m in "${mismatches[@]}"; do
      echo "    $m"
    done
    fail=1
  else
    echo "  OK"
  fi
fi

echo ""
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed."
else
  echo "One or more checks failed. See above."
  exit 1
fi
