#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST="$SCRIPT_DIR/manifest.json"
DEST=${1:-}
[ -n "$DEST" ] || {
  printf 'usage: %s SNAPSHOT_DIRECTORY\n' "$0" >&2
  exit 2
}
command -v jq >/dev/null 2>&1 || {
  printf 'tool-missing: jq is required\n' >&2
  exit 2
}

case "$DEST" in
  /|"${HOME:-}/"|"${HOME:-}")
    printf 'unsafe-snapshot-destination: choose a dedicated directory\n' >&2
    exit 2
    ;;
esac
if [ -e "$DEST" ] && [ ! -d "$DEST" ]; then
  printf 'invalid-snapshot-destination: destination is not a directory\n' >&2
  exit 2
fi
if [ -d "$DEST" ] && [ -n "$(find "$DEST" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
  printf 'snapshot-destination-not-empty: refusing to overwrite existing data\n' >&2
  exit 2
fi
mkdir -p "$DEST/data" "$DEST/metadata"

HOME_ROOT=${FOUR_TOOL_RENAME_HOME:-${HOME:-}}
GIT_ROOT=${FOUR_TOOL_RENAME_GIT_ROOT:-$(jq -r '.paths.repositories_root' "$MANIFEST")}
WORKTREE_ROOT=${FOUR_TOOL_RENAME_WORKTREE_ROOT:-$(jq -r '.paths.worktrees_root' "$MANIFEST")}
ASSETS_FILE=$(mktemp "$DEST/metadata/assets.XXXXXX")
REPOS_FILE=$(mktemp "$DEST/metadata/repositories.XXXXXX")
BINARIES_FILE=$(mktemp "$DEST/metadata/binaries.XXXXXX")

resolve_path() {
  local value=$1
  case "$value" in
    '~/'*) printf '%s/%s\n' "$HOME_ROOT" "${value#\~/}" ;;
    /Users/tfinklea/git/*) printf '%s/%s\n' "$GIT_ROOT" "${value#/Users/tfinklea/git/}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

capture_asset() {
  local product=$1
  local kind=$2
  local configured=$3
  [ "$configured" != null ] || return 0
  local source relative target exists sha
  source=$(resolve_path "$configured")
  relative="data/$product/$kind"
  target="$DEST/$relative"
  exists=false
  sha=null
  if [ -e "$source" ]; then
    exists=true
    mkdir -p "$(dirname "$target")"
    cp -R -p "$source" "$target"
    if [ -f "$source" ]; then
      sha="\"$(shasum -a 256 "$source" | awk '{print $1}')\""
    fi
  fi
  jq -cn \
    --arg product "$product" --arg kind "$kind" --arg source "$source" \
    --arg snapshot_path "$relative" --argjson exists "$exists" --argjson sha256 "$sha" \
    '{product:$product,kind:$kind,source:$source,exists:$exists,snapshot_path:$snapshot_path,sha256:$sha256}' \
    >> "$ASSETS_FILE"
}

while IFS=$'\t' read -r old new config state report repository; do
  capture_asset "$old" config "$config"
  capture_asset "$old" state "$state"
  capture_asset "$old" report "$report"

  repo_path="$WORKTREE_ROOT/$old"
  [ -d "$repo_path" ] || repo_path="$GIT_ROOT/$old"
  commit=null
  origin=null
  if [ -d "$repo_path" ] && git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1; then
    commit="\"$(git -C "$repo_path" rev-parse HEAD)\""
    origin_value=$(git -C "$repo_path" remote get-url origin 2>/dev/null || true)
    [ -z "$origin_value" ] || origin="\"$origin_value\""
  fi
  repository_id=null
  if command -v gh >/dev/null 2>&1; then
    id=$(gh repo view "$repository" --json id --jq '.id' 2>/dev/null || true)
    [ -z "$id" ] || repository_id="\"$id\""
  fi
  jq -cn --arg old "$old" --arg new "$new" --arg repository "$repository" \
    --arg repo_path "$repo_path" --argjson commit "$commit" --argjson origin "$origin" \
    --argjson repository_id "$repository_id" \
    '{old:$old,new:$new,repository:$repository,path:$repo_path,commit:$commit,origin:$origin,repository_id:$repository_id}' \
    >> "$REPOS_FILE"

done < <(jq -r '.products[] | [.old,.new,(.paths.config.old // "null"),(.paths.state.old // "null"),(.paths.report.old // "null"),.repository.old] | @tsv' "$MANIFEST")

while IFS= read -r name; do
  path=$(command -v "$name" 2>/dev/null || true)
  exists=false
  sha=null
  if [ -n "$path" ] && [ -f "$path" ]; then
    exists=true
    sha="\"$(shasum -a 256 "$path" | awk '{print $1}')\""
  else
    path=null
  fi
  if [ "$path" = null ]; then
    path_json=null
  else
    path_json="\"$path\""
  fi
  jq -cn --arg name "$name" --argjson path "$path_json" --argjson exists "$exists" --argjson sha256 "$sha" \
    '{name:$name,path:$path,exists:$exists,sha256:$sha256}' >> "$BINARIES_FILE"
done < <(jq -r '.products[] | .old,.new' "$MANIFEST")

for managed in base personal; do
  configured=$(jq -r ".paths.managed_config.$managed" "$MANIFEST")
  capture_asset managed-config "$managed" "$configured"
done

CREATED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
MANIFEST_SHA=$(shasum -a 256 "$MANIFEST" | awk '{print $1}')
ASSETS=$(jq -s '.' "$ASSETS_FILE")
REPOSITORIES=$(jq -s '.' "$REPOS_FILE")
BINARIES=$(jq -s '.' "$BINARIES_FILE")

jq -n \
  --arg created_at "$CREATED_AT" \
  --arg source_manifest_sha256 "$MANIFEST_SHA" \
  --argjson rollback_order "$(jq '.rollback_order' "$MANIFEST")" \
  --argjson repositories "$REPOSITORIES" \
  --argjson binaries "$BINARIES" \
  --argjson assets "$ASSETS" \
  '{
    schema:"four-tool-rename/snapshot@1",
    complete:true,
    created_at:$created_at,
    source_manifest_sha256:$source_manifest_sha256,
    rollback_order:$rollback_order,
    repositories:$repositories,
    binaries:$binaries,
    assets:$assets
  }' > "$DEST/snapshot.json"

rm -f "$ASSETS_FILE" "$REPOS_FILE" "$BINARIES_FILE"
SNAPSHOT_SHA=$(shasum -a 256 "$DEST/snapshot.json" | awk '{print $1}')
printf '%s\n' "$SNAPSHOT_SHA" > "$DEST/COMPLETE"
printf '%s\n' "$DEST/snapshot.json"
