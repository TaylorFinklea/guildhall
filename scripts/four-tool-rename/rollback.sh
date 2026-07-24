#!/bin/bash
set -euo pipefail

MODE=${1:-}
SNAPSHOT_DIR=${2:-}
if [ "$MODE" != "--dry-run" ] || [ -z "$SNAPSHOT_DIR" ] || [ "$#" -ne 2 ]; then
  printf 'dry-run-only: usage: %s --dry-run SNAPSHOT_DIRECTORY\n' "$0" >&2
  exit 2
fi
command -v jq >/dev/null 2>&1 || {
  printf 'tool-missing: jq is required\n' >&2
  exit 2
}
SNAPSHOT="$SNAPSHOT_DIR/snapshot.json"
MARKER="$SNAPSHOT_DIR/COMPLETE"
if [ ! -f "$SNAPSHOT" ] || [ ! -f "$MARKER" ]; then
  printf 'incomplete-snapshot: snapshot.json and COMPLETE are required\n' >&2
  exit 3
fi
expected=$(cat "$MARKER")
actual=$(shasum -a 256 "$SNAPSHOT" | awk '{print $1}')
if [ "$expected" != "$actual" ]; then
  printf 'incomplete-snapshot: snapshot manifest hash does not match COMPLETE\n' >&2
  exit 3
fi
if ! jq -e '
  .schema == "four-tool-rename/snapshot@1" and
  .complete == true and
  (.source_manifest_sha256 | test("^[0-9a-f]{64}$")) and
  .rollback_order == ["cautionlight","afterfact","undertake","musterroll"] and
  (.repositories | length) == 4 and
  all(.repositories[]; has("old") and has("new") and has("commit") and has("origin") and has("repository_id")) and
  (.assets | type) == "array" and
  all(.assets[]; has("product") and has("kind") and has("source") and has("exists") and has("snapshot_path"))
' "$SNAPSHOT" >/dev/null 2>&1; then
  printf 'incomplete-snapshot: snapshot manifest failed validation\n' >&2
  exit 3
fi

while IFS=$'\t' read -r new old; do
  printf 'rollback %s -> %s\n' "$new" "$old"
  jq -r --arg product "$old" '
    .assets[] | select(.product == $product and .exists == true) |
    "  restore \(.kind): \(.snapshot_path) -> \(.source)"
  ' "$SNAPSHOT"
  jq -r --arg product "$old" '
    .repositories[] | select(.old == $product) |
    "  restore repository: \(.repository) at commit \(.commit // "unavailable") with origin \(.origin // "unavailable")"
  ' "$SNAPSHOT"
done < <(jq -r '.rollback_order[] as $new | .repositories[] | select(.new == $new) | [$new,.old] | @tsv' "$SNAPSHOT")

printf 'dry-run-only: no files, repositories, remotes, state, installs, or HOME paths were changed\n'
