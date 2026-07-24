#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST="$SCRIPT_DIR/manifest.json"
MODE=${1:-}
[ "$MODE" = "--json" ] || {
  printf 'usage: %s --json\n' "$0" >&2
  exit 2
}
command -v jq >/dev/null 2>&1 || {
  printf '{"ready":false,"mappings":[],"blockers":[{"type":"tool-missing","message":"jq is required"}]}\n'
  exit 0
}

HOME_ROOT=${FOUR_TOOL_RENAME_HOME:-${HOME:-}}
GIT_ROOT=${FOUR_TOOL_RENAME_GIT_ROOT:-$(jq -r '.paths.repositories_root' "$MANIFEST")}
WORKTREE_ROOT=${FOUR_TOOL_RENAME_WORKTREE_ROOT:-$(jq -r '.paths.worktrees_root' "$MANIFEST")}
BLOCKERS=''
CANDIDATES=''

add_blocker() {
  local type=$1
  local message=$2
  local context=${3:-}
  [ -n "$context" ] || context='{}'
  local item
  item=$(jq -cn --arg type "$type" --arg message "$message" --argjson context "$context" \
    '{type:$type,message:$message,context:$context}')
  BLOCKERS="${BLOCKERS}${item}
"
}

add_candidate() {
  local repo=$1
  local path=$2
  local item
  item=$(jq -cn --arg repo "$repo" --arg path "$path" '{repo:$repo,path:$path}')
  CANDIDATES="${CANDIDATES}${item}
"
}

if ! jq -e '
  .schema == "four-tool-rename/manifest@1" and
  (.products | length) == 4 and
  (.historical_classification.complete | type) == "boolean" and
  ((.historical_classification.candidate_count | type) == "number" or
    .historical_classification.candidate_count == null) and
  (.historical_value_allowlist | type) == "array" and
  ([.historical_value_allowlist[] | [.repo,.path,.literal]] | unique | length) ==
    (.historical_value_allowlist | length) and
  all(.historical_value_allowlist[];
    (.repo | type) == "string" and
    (.path | type) == "string" and
    (.path | startswith("/") | not) and
    (.path | endswith("/") | not) and
    (.path | test("[*?\\[]") | not) and
    (.literal | type) == "string" and
    (.literal | length) > 0 and
    (.literal | test("[*?\\[]") | not) and
    (.sha256 | test("^[0-9a-f]{64}$")) and
    (.kind == "closed-bead-id" or .kind == "one-shot-migration" or .kind == "strict-legacy-assertion") and
    (.reason | type) == "string" and (.reason | length) > 0) and
  all(.classification_control_paths[];
    (.repo | type) == "string" and
    (.path | type) == "string" and
    (.path | startswith("/") | not) and
    (.path | endswith("/") | not) and
    (.path | test("[*?\\[]") | not)) and
  all(.historical_allowlist[];
    (.path | startswith("/") | not) and
    (.path | endswith("/") | not) and
    (.path | test("[*?\\[]") | not) and
    (.sha256 | test("^[0-9a-f]{64}$")))
' "$MANIFEST" >/dev/null 2>&1; then
  add_blocker manifest-invalid 'Canonical manifest failed structural validation.'
fi

while IFS=$'\t' read -r repo path expected; do
  file="$WORKTREE_ROOT/$repo/$path"
  [ -f "$file" ] || file="$GIT_ROOT/$repo/$path"
  if [ ! -f "$file" ]; then
    add_blocker historical-path-mismatch 'An immutable-history allowlist file is missing.' \
      "$(jq -cn --arg repo "$repo" --arg path "$path" '{repo:$repo,path:$path}')"
    continue
  fi
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  if [ "$actual" != "$expected" ]; then
    add_blocker historical-hash-mismatch 'An immutable-history allowlist file changed.' \
      "$(jq -cn --arg repo "$repo" --arg path "$path" '{repo:$repo,path:$path}')"
  fi
done < <(jq -r '.historical_allowlist[] | [.repo,.path,.sha256] | @tsv' "$MANIFEST")

while IFS=$'\t' read -r repo path literal expected; do
  file="$WORKTREE_ROOT/$repo/$path"
  [ -f "$file" ] || file="$GIT_ROOT/$repo/$path"
  if [ ! -f "$file" ]; then
    add_blocker historical-value-path-mismatch 'A historical value exception file is missing.' \
      "$(jq -cn --arg repo "$repo" --arg path "$path" '{repo:$repo,path:$path}')"
    continue
  fi
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  if [ "$actual" != "$expected" ]; then
    add_blocker historical-value-hash-mismatch 'A historical value exception file changed.' \
      "$(jq -cn --arg repo "$repo" --arg path "$path" '{repo:$repo,path:$path}')"
  elif ! grep -F "$literal" "$file" >/dev/null 2>&1; then
    add_blocker historical-value-missing 'A historical value exception literal is absent.' \
      "$(jq -cn --arg repo "$repo" --arg path "$path" '{repo:$repo,path:$path}')"
  fi
done < <(jq -r '.historical_value_allowlist[] | [.repo,.path,.literal,.sha256] | @tsv' "$MANIFEST")

for repo in guildhall bursar conductor hindsight warden chezmoi-base chezmoi-personal; do
  path="$WORKTREE_ROOT/$repo"
  if [ ! -d "$path" ] || ! git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
    add_blocker worktree-missing 'Required rename worktree is missing.' \
      "$(jq -cn --arg repo "$repo" '{repo:$repo}')"
    continue
  fi
  branch=$(git -C "$path" branch --show-current 2>/dev/null || true)
  if [ "$branch" != feat/four-tool-clean-rename ]; then
    add_blocker branch-mismatch 'Required worktree is on the wrong branch.' \
      "$(jq -cn --arg repo "$repo" --arg branch "$branch" '{repo:$repo,branch:$branch}')"
  fi
  if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
    add_blocker dirty-worktree 'Required rename worktree is dirty.' \
      "$(jq -cn --arg repo "$repo" '{repo:$repo}')"
  fi

done

while IFS=$'\t' read -r old new source target origin backlog_source backlog_target; do
  repo_path="$GIT_ROOT/$old"
  [ -d "$repo_path/.git" ] || repo_path="$WORKTREE_ROOT/$old"
  if [ ! -d "$repo_path" ]; then
    add_blocker source-checkout-missing 'Source checkout is missing.' \
      "$(jq -cn --arg product "$old" '{product:$product}')"
  else
    actual_origin=$(git -C "$repo_path" remote get-url origin 2>/dev/null || true)
    if [ "$actual_origin" != "$origin" ]; then
      add_blocker origin-mismatch 'Source checkout origin does not match the manifest.' \
        "$(jq -cn --arg product "$old" '{product:$product}')"
    fi
  fi

done < <(jq -r '.products[] | [.old,.new,.repository.old,.repository.new,.repository.origin_old,.backlog.repository_old,.backlog.repository_new] | @tsv' "$MANIFEST")

GH_AUTH=false
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GH_AUTH=true
  while IFS=$'\t' read -r source target backlog_source backlog_target; do
    gh repo view "$source" --json id,nameWithOwner >/dev/null 2>&1 || \
      add_blocker source-repository-missing 'A source GitHub repository is unavailable.' \
        "$(jq -cn --arg repository "$source" '{repository:$repository}')"
    if gh repo view "$target" --json id,nameWithOwner >/dev/null 2>&1; then
      add_blocker target-slug-unavailable 'A target GitHub repository slug already exists.' \
        "$(jq -cn --arg repository "$target" '{repository:$repository}')"
    fi
    gh repo view "$backlog_source" --json id,nameWithOwner >/dev/null 2>&1 || \
      add_blocker source-backlog-missing 'A source backlog repository is unavailable.' \
        "$(jq -cn --arg repository "$backlog_source" '{repository:$repository}')"
    if gh repo view "$backlog_target" --json id,nameWithOwner >/dev/null 2>&1; then
      add_blocker target-backlog-slug-unavailable 'A target backlog repository slug already exists.' \
        "$(jq -cn --arg repository "$backlog_target" '{repository:$repository}')"
    fi
  done < <(jq -r '.products[] | [.repository.old,.repository.new,.backlog.repository_old,.backlog.repository_new] | @tsv' "$MANIFEST")
else
  add_blocker gh-auth-unavailable 'GitHub CLI authentication is unavailable.'
fi

active_processes=0
for binary in conductor undertake; do
  if command -v pgrep >/dev/null 2>&1 && pgrep -x "$binary" >/dev/null 2>&1; then
    active_processes=$((active_processes + 1))
  fi
done
active_runs=0
unreadable_runs=0
for root in "$HOME_ROOT/.local/state/conductor" "$HOME_ROOT/.local/state/undertake"; do
  [ -d "$root" ] || continue
  for run_manifest in "$root"/runs/*/manifest.json "$root"/runs-v2/*/manifest.json; do
    [ -f "$run_manifest" ] || continue
    if ! lifecycle=$(jq -er '.lifecycle | select(type == "string")' "$run_manifest" 2>/dev/null); then
      unreadable_runs=$((unreadable_runs + 1))
      continue
    fi
    case "$lifecycle" in
      finished) ;;
      started|running) active_runs=$((active_runs + 1)) ;;
      *) unreadable_runs=$((unreadable_runs + 1)) ;;
    esac
  done
done
if [ "$active_processes" -ne 0 ] || [ "$active_runs" -ne 0 ]; then
  add_blocker active-runs-present 'Undertake/Conductor quiescence is not proven.' \
    "$(jq -cn --argjson processes "$active_processes" --argjson runs "$active_runs" '{processes:$processes,runs:$runs}')"
fi
if [ "$unreadable_runs" -ne 0 ]; then
  add_blocker run-state-unreadable 'Undertake/Conductor run lifecycle is malformed or unknown.' \
    "$(jq -cn --argjson count "$unreadable_runs" '{count:$count}')"
fi

BWS_STATUS=unavailable
BWS_PROJECT_NAMES='[]'
if command -v bws >/dev/null 2>&1; then
  bws_raw=$(bws project list --output json 2>/dev/null || true)
  if printf '%s' "$bws_raw" | jq -e 'type == "array"' >/dev/null 2>&1; then
    BWS_STATUS=available
    BWS_PROJECT_NAMES=$(printf '%s' "$bws_raw" | jq '[.[] | .name]')
  else
    add_blocker bws-inventory-unavailable 'BWS project registration names could not be inventoried.'
  fi
else
  add_blocker bws-inventory-unavailable 'BWS CLI is unavailable.'
fi

for repo in guildhall bursar conductor hindsight warden chezmoi-base chezmoi-personal; do
  root="$WORKTREE_ROOT/$repo"
  [ -d "$root/.git" ] || [ -f "$root/.git" ] || continue
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    add_candidate "$repo" "$rel"
  done < <(python3 - "$MANIFEST" "$repo" "$root" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text())
repo = sys.argv[2]
root = Path(sys.argv[3])
allowlisted = {
    item["path"] for item in manifest["historical_allowlist"]
    if item["repo"] == repo
}
controls = {
    item["path"] for item in manifest["classification_control_paths"]
    if item["repo"] == repo
}
values_by_path = {}
for item in manifest["historical_value_allowlist"]:
    if item["repo"] == repo:
        values_by_path.setdefault(item["path"], []).append(item["literal"])
tokens = re.compile(r"(conductor|bursar|hindsight|warden)", re.IGNORECASE)
tracked = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard", "-z"]
).split(b"\0")
for raw_path in tracked:
    if not raw_path:
        continue
    rel = raw_path.decode("utf-8", "surrogateescape")
    if rel in allowlisted or rel in controls:
        continue
    path = root / rel
    if not path.is_file():
        continue
    try:
        data = path.read_bytes()
    except OSError:
        print(rel)
        continue
    if b"\0" in data:
        continue
    text = data.decode("utf-8", "replace")
    scanned_rel = rel
    for value in sorted(values_by_path.get(rel, []), key=len, reverse=True):
        text = text.replace(value, "")
        scanned_rel = scanned_rel.replace(value, "")
    if tokens.search(scanned_rel) or tokens.search(text):
        print(rel)
PY
  )
done

CANDIDATES_JSON=$(printf '%s' "$CANDIDATES" | jq -s 'unique_by(.repo,.path)')
CANDIDATE_COUNT=$(printf '%s' "$CANDIDATES_JSON" | jq 'length')
CANDIDATES_BY_OWNER=$(printf '%s' "$CANDIDATES_JSON" | jq 'group_by(.repo) | map({key:.[0].repo,value:length}) | from_entries')
DECLARED_COUNT=$(jq -r '.historical_classification.candidate_count // -1' "$MANIFEST")
DECLARED_COMPLETE=$(jq -r '.historical_classification.complete' "$MANIFEST")
CLASSIFICATION_COMPLETE=false
if [ "$CANDIDATE_COUNT" -eq 0 ] && [ "$DECLARED_COUNT" -eq 0 ] && [ "$DECLARED_COMPLETE" = true ]; then
  CLASSIFICATION_COMPLETE=true
else
  add_blocker historical-classification-incomplete \
    'Stale-name classification is incomplete; current candidates must be removed or added as exact hashed files.' \
    "$(jq -cn --argjson count "$CANDIDATE_COUNT" '{candidate_count:$count}')"
fi

BLOCKERS_JSON=$(printf '%s' "$BLOCKERS" | jq -s '.')
READY=false
if [ "$(printf '%s' "$BLOCKERS_JSON" | jq 'length')" -eq 0 ]; then
  READY=true
fi

resolve_inventory_path() {
  case "$1" in
    '~/'*) printf '%s/%s\n' "$HOME_ROOT" "${1#\~/}" ;;
    /Users/tfinklea/git/*) printf '%s/%s\n' "$GIT_ROOT" "${1#/Users/tfinklea/git/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

ROOT_LINES=''
while IFS=$'\t' read -r product identity kind configured; do
  [ "$configured" != null ] || continue
  resolved=$(resolve_inventory_path "$configured")
  exists=false
  [ ! -e "$resolved" ] || exists=true
  ROOT_LINES="${ROOT_LINES}$(jq -cn --arg product "$product" --arg identity "$identity" \
    --arg kind "$kind" --arg path "$resolved" --argjson exists "$exists" \
    '{product:$product,identity:$identity,kind:$kind,path:$path,exists:$exists}')
"
done < <(jq -r '.products[] as $p | ["old","new"][] as $identity |
  ["checkout","config","state","report"][] as $kind |
  [$p.old,$identity,$kind,($p.paths[$kind][$identity] // "null")] | @tsv' "$MANIFEST")
active_roots=$(printf '%s' "$ROOT_LINES" | jq -s '.')

BINARY_LINES=''
while IFS= read -r name; do
  binary_path=$(command -v "$name" 2>/dev/null || true)
  installed=false
  [ -z "$binary_path" ] || installed=true
  BINARY_LINES="${BINARY_LINES}$(jq -cn --arg name "$name" --arg path "$binary_path" --argjson installed "$installed" \
    '{name:$name,installed:$installed,path:(if $path == "" then null else $path end)}')
"
done < <(jq -r '.products[] | .old,.new' "$MANIFEST")
binaries=$(printf '%s' "$BINARY_LINES" | jq -s '.')
launch_agents=$({ find "$HOME_ROOT/Library/LaunchAgents" -maxdepth 1 -type f -name '*.plist' -exec basename {} \; 2>/dev/null || true; } |
  jq -Rsc 'split("\n") | map(select(length > 0))')
brew_formulae='[]'
brew_taps='[]'
if command -v brew >/dev/null 2>&1; then
  brew_formulae=$({ brew list --formula 2>/dev/null || true; } | jq -Rsc 'split("\n") | map(select(length > 0))')
  brew_taps=$({ brew tap 2>/dev/null || true; } | jq -Rsc 'split("\n") | map(select(length > 0))')
fi

jq -n \
  --argjson ready "$READY" \
  --argjson blockers "$BLOCKERS_JSON" \
  --argjson mappings "$(jq '[.products[] | {old,new,repository,backlog,paths}]' "$MANIFEST")" \
  --argjson candidates "$CANDIDATES_JSON" \
  --argjson candidates_by_owner "$CANDIDATES_BY_OWNER" \
  --argjson candidate_count "$CANDIDATE_COUNT" \
  --argjson classification_complete "$CLASSIFICATION_COMPLETE" \
  --argjson gh_authenticated "$GH_AUTH" \
  --arg bws_status "$BWS_STATUS" \
  --argjson bws_projects "$BWS_PROJECT_NAMES" \
  --argjson binaries "$binaries" \
  --argjson launch_agents "$launch_agents" \
  --argjson brew_formulae "$brew_formulae" \
  --argjson brew_taps "$brew_taps" \
  --arg distribution_kind "$(jq -r '.distribution.kind' "$MANIFEST")" \
  --argjson active_roots "$active_roots" \
  '{
    schema:"four-tool-rename/preflight@1",
    ready:$ready,
    mappings:$mappings,
    blockers:$blockers,
    candidate_report:{classification_complete:$classification_complete,candidate_count:$candidate_count,by_owner:$candidates_by_owner,candidates:$candidates},
    inventory:{
      distribution:{kind:$distribution_kind},
      active_roots:$active_roots,
      github_authenticated:$gh_authenticated,
      bws:{status:$bws_status,project_names:$bws_projects},
      binaries:$binaries,
      launch_agents:$launch_agents,
      homebrew:{formulae:$brew_formulae,taps:$brew_taps}
    }
  }'
