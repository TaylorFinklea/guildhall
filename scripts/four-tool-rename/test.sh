#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST="$SCRIPT_DIR/manifest.json"
PREFLIGHT="$SCRIPT_DIR/preflight.sh"
SNAPSHOT="$SCRIPT_DIR/snapshot.sh"
ROLLBACK="$SCRIPT_DIR/rollback.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "missing $1"
}

assert_file "$MANIFEST"
assert_file "$PREFLIGHT"
assert_file "$SNAPSHOT"
assert_file "$ROLLBACK"
command -v jq >/dev/null 2>&1 || fail "jq is required"

resolve_worktree_repo() {
  jq -r --arg repo "$1" \
    '([.products[] | select(.old == $repo) | .new][0] // $repo)' "$MANIFEST"
}

jq -e '
  .schema == "four-tool-rename/manifest@1" and
  .owner == "TaylorFinklea" and
  .distribution.kind == "local-release-copy" and
  .dependency_order == ["musterroll", "undertake", "afterfact", "cautionlight"] and
  .rollback_order == ["cautionlight", "afterfact", "undertake", "musterroll"] and
  (.products | length) == 4 and
  [.products[] | [.old, .new]] == [
    ["bursar", "musterroll"],
    ["conductor", "undertake"],
    ["hindsight", "afterfact"],
    ["warden", "cautionlight"]
  ] and
  [.products[] | [.backlog.old, .backlog.new]] == [
    ["backlog-bursar", "backlog-musterroll"],
    ["backlog-conductor", "backlog-undertake"],
    ["backlog-hindsight", "backlog-afterfact"],
    ["backlog-warden", "backlog-cautionlight"]
  ] and
  all(.products[];
    .repository.old == ("TaylorFinklea/" + .old) and
    .repository.new == ("TaylorFinklea/" + .new) and
    .backlog.repository_old == ("TaylorFinklea/" + .backlog.old) and
    .backlog.repository_new == ("TaylorFinklea/" + .backlog.new) and
    .paths.checkout.old == ("/Users/tfinklea/git/" + .old) and
    .paths.checkout.new == ("/Users/tfinklea/git/" + .new) and
    (.paths | has("checkout") and has("config") and has("state") and has("report"))
  )
' "$MANIFEST" >/dev/null || fail "canonical mapping inventory is invalid"

jq -e '
  .historical_classification.complete == true and
  .historical_classification.candidate_count == 0 and
  .historical_classification.residual_by_owner == {} and
  .historical_classification.blocker_type == "historical-classification-incomplete" and
  ([
    ["bursar", "tests/fixtures/roster/legacy-conductor.toml"],
    ["bursar", ".docs/ai/phases/provider-availability-v2-report.md"],
    ["hindsight", "migrations/0003_conductor_reviewer.sql"],
    ["conductor", "docs/notes/agy-dispatch.md"],
    ["conductor", "docs/notes/bd-readonly.md"],
    ["conductor", "docs/notes/orchestrator-recon.md"],
    ["conductor", "docs/superpowers/plans/2026-07-13-adversarial-design-review.md"],
    ["conductor", "docs/superpowers/plans/2026-07-13-bounded-dispatch-approval.md"],
    ["conductor", "docs/superpowers/plans/2026-07-13-provider-trust-integration.md"],
    ["warden", "adapters/claude_pretooluse/Cargo.toml"],
    ["warden", "adapters/claude_pretooluse/src/lib.rs"],
    ["warden", "adapters/claude_pretooluse/src/main.rs"],
    ["warden", "adapters/claude_pretooluse/tests/adapter_claude.rs"],
    ["warden", "docs/HANDOFF-install.md"],
    ["warden", "docs/notes/agy-interception.md"],
    ["warden", "docs/notes/dispatch-surface-coverage.md"],
    ["warden", ".docs/ai/decisions.md"],
    ["warden", ".docs/ai/phases/warden-v1-spec.md"]
  ] - [.historical_allowlist[] | [.repo, .path]] | length) == 0 and
  (.historical_value_allowlist | type) == "array" and
  (.historical_value_allowlist | length) > 0 and
  ([.historical_value_allowlist[] | [.repo,.path,.literal]] | unique | length) ==
    (.historical_value_allowlist | length) and
  all(.historical_value_allowlist[];
    (.path | startswith("/") | not) and
    (.path | endswith("/") | not) and
    (.path | test("[*?\\[]") | not) and
    (.literal | length) > 0 and
    (.literal | test("[*?\\[]") | not) and
    (.sha256 | test("^[0-9a-f]{64}$")) and
    (.kind == "closed-bead-id" or .kind == "one-shot-migration" or .kind == "strict-legacy-assertion")
  ) and
  all(.historical_allowlist[];
    (.path | type) == "string" and
    (.path | startswith("/") | not) and
    (.path | endswith("/") | not) and
    (.path | test("[*?\\[]") | not) and
    (.sha256 | test("^[0-9a-f]{64}$"))
  )
' "$MANIFEST" >/dev/null || fail "historical allowlist must contain only exact hashed files"

REPO_ROOT=$(jq -r '.paths.repositories_root' "$MANIFEST")
WORKTREE_ROOT=$(jq -r '.paths.worktrees_root' "$MANIFEST")
while IFS=$'\t' read -r repo path expected; do
  file="$WORKTREE_ROOT/$(resolve_worktree_repo "$repo")/$path"
  [ -f "$file" ] || file="$REPO_ROOT/$repo/$path"
  [ -f "$file" ] || fail "allowlisted path is not a file: $repo/$path"
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  [ "$actual" = "$expected" ] || fail "allowlisted hash mismatch: $repo/$path"
done < <(jq -r '.historical_allowlist[] | [.repo, .path, .sha256] | @tsv' "$MANIFEST")
while IFS=$'\t' read -r repo path literal_b64 expected; do
  file="$WORKTREE_ROOT/$(resolve_worktree_repo "$repo")/$path"
  [ -f "$file" ] || file="$REPO_ROOT/$repo/$path"
  [ -f "$file" ] || fail "value exception path is not a file: $repo/$path"
  literal=$(printf '%s' "$literal_b64" | base64 --decode)
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  [ "$actual" = "$expected" ] || fail "value exception hash mismatch: $repo/$path"
  grep -F -- "$literal" "$file" >/dev/null || fail "value exception literal missing: $repo/$path"
done < <(jq -r '.historical_value_allowlist[] | [.repo,.path,(.literal | @base64),.sha256] | @tsv' "$MANIFEST")

TMP=$(mktemp -d "${TMPDIR:-/tmp}/four-tool-rename-test.XXXXXX")
BOUNDARY_FILE="$WORKTREE_ROOT/chezmoi-personal/.four-tool-bitwarden-boundary-test"
trap 'rm -rf "$TMP"; rm -f "$BOUNDARY_FILE"' EXIT
TEST_HOME="$TMP/home"
TEST_GIT="$TMP/git"
mkdir -p "$TEST_HOME/.local/state" "$TEST_HOME/.local/share" "$TEST_HOME/.harness/reports" "$TEST_GIT"
TEST_BIN="$TMP/bin"
mkdir -p "$TEST_BIN"
cat > "$TEST_BIN/bws-project" <<'EOF'
#!/bin/sh
set -eu
[ "${1:-}" = inventory ] || exit 2
printf '%s\n' '{"schema":"bws-project/inventory@1","projects":[{"id":"project-id","name":"Finklea Dev","secret":"SECRET_VALUE_MUST_NOT_LEAK"}]}'
EOF
chmod +x "$TEST_BIN/bws-project"
printf '%s\n' 'state evidence' > "$TEST_HOME/.local/state/conductor-ledger"
printf '%s\n' 'report evidence' > "$TEST_HOME/.harness/reports/conductor-report"

for run in finished-verified finished-accepted; do
  mkdir -p "$TEST_HOME/.local/state/conductor/runs/$run"
done
for run in finished-rejected finished-blocked running started malformed unknown; do
  mkdir -p "$TEST_HOME/.local/state/conductor/runs-v2/$run"
done
printf '%s\n' '{"lifecycle":"finished","outcome":"verified"}' > "$TEST_HOME/.local/state/conductor/runs/finished-verified/manifest.json"
printf '%s\n' '{"lifecycle":"finished","outcome":"accepted"}' > "$TEST_HOME/.local/state/conductor/runs/finished-accepted/manifest.json"
printf '%s\n' '{"lifecycle":"finished","outcome":"rejected"}' > "$TEST_HOME/.local/state/conductor/runs-v2/finished-rejected/manifest.json"
printf '%s\n' '{"lifecycle":"finished","outcome":"blocked"}' > "$TEST_HOME/.local/state/conductor/runs-v2/finished-blocked/manifest.json"
printf '%s\n' '{"lifecycle":"running"}' > "$TEST_HOME/.local/state/conductor/runs-v2/running/manifest.json"
printf '%s\n' '{"lifecycle":"started"}' > "$TEST_HOME/.local/state/conductor/runs-v2/started/manifest.json"
printf '%s\n' '{"lifecycle":' > "$TEST_HOME/.local/state/conductor/runs-v2/malformed/manifest.json"
printf '%s\n' '{"lifecycle":"paused"}' > "$TEST_HOME/.local/state/conductor/runs-v2/unknown/manifest.json"

SECRET='SECRET_VALUE_MUST_NOT_LEAK'
export GH_TOKEN="$SECRET" BWS_ACCESS_TOKEN="$SECRET" OPENAI_API_KEY="$SECRET"
printf '%s\n' 'Bitwarden is unrelated to the retired policy-tool identity.' > "$BOUNDARY_FILE"
preflight_json="$TMP/preflight.json"
PATH="$TEST_BIN:$PATH" \
FOUR_TOOL_RENAME_HOME="$TEST_HOME" \
FOUR_TOOL_RENAME_GIT_ROOT="$TEST_GIT" \
  "$PREFLIGHT" --json > "$preflight_json"
jq -e --slurpfile manifest "$MANIFEST" '
  (.ready | type) == "boolean" and
  (.blockers | type) == "array" and
  all(.blockers[]; (.type | type) == "string" and (.message | type) == "string") and
  (.mappings | length) == 4 and
  (.candidate_report | type) == "object" and
  .candidate_report.classification_complete == true and
  .candidate_report.candidate_count == 0 and
  .candidate_report.by_owner == {} and
  .candidate_report.candidates == [] and
  .inventory.distribution.kind == "local-release-copy" and
  (.inventory.active_roots | type) == "array" and
  (.inventory.active_roots | length) >= 8 and
  all(.inventory.active_roots[]; has("product") and has("kind") and has("path") and has("exists")) and
  .inventory.bws.status == "available" and
  .inventory.bws.project_names == ["Finklea Dev"] and
  (any(.blockers[]; .type == "bws-inventory-unavailable") | not) and
  (any(.blockers[]; .type == "historical-classification-incomplete") | not)
  and ([.blockers[] | select(.type == "active-runs-present") | .context.runs] == [2])
  and ([.blockers[] | select(.type == "run-state-unreadable") | .context.count] == [2])
' "$preflight_json" >/dev/null || fail "preflight did not emit typed blockers"
if grep -F "$SECRET" "$preflight_json" >/dev/null; then
  fail "preflight leaked a secret value"
fi

snapshot_dir="$TMP/snapshot"
FOUR_TOOL_RENAME_HOME="$TEST_HOME" \
FOUR_TOOL_RENAME_GIT_ROOT="$TEST_GIT" \
FOUR_TOOL_RENAME_WORKTREE_ROOT="$WORKTREE_ROOT" \
  "$SNAPSHOT" "$snapshot_dir"

snapshot_manifest="$snapshot_dir/snapshot.json"
jq -e '
  .schema == "four-tool-rename/snapshot@1" and
  .complete == true and
  (.created_at | type) == "string" and
  (.source_manifest_sha256 | test("^[0-9a-f]{64}$")) and
  .rollback_order == ["cautionlight", "afterfact", "undertake", "musterroll"] and
  (.repositories | length) == 4 and
  (.assets | type) == "array" and
  all(.assets[]; has("product") and has("kind") and has("source") and has("exists") and has("snapshot_path"))
' "$snapshot_manifest" >/dev/null || fail "snapshot manifest is invalid"
[ -f "$snapshot_dir/COMPLETE" ] || fail "snapshot completion marker missing"

before=$(find "$TEST_HOME" "$TEST_GIT" -type f -exec shasum -a 256 {} \; | sort)
dry_run=$(
  FOUR_TOOL_RENAME_HOME="$TEST_HOME" \
  FOUR_TOOL_RENAME_GIT_ROOT="$TEST_GIT" \
    "$ROLLBACK" --dry-run "$snapshot_dir"
)
after=$(find "$TEST_HOME" "$TEST_GIT" -type f -exec shasum -a 256 {} \; | sort)
[ "$before" = "$after" ] || fail "rollback dry-run mutated source paths"
order=$(printf '%s\n' "$dry_run" | awk '/^rollback / { print $2 }' | paste -sd ' ' -)
[ "$order" = 'cautionlight afterfact undertake musterroll' ] || fail "rollback order is wrong: $order"

incomplete="$TMP/incomplete"
mkdir -p "$incomplete"
printf '%s\n' '{"schema":"four-tool-rename/snapshot@1","complete":false}' > "$incomplete/snapshot.json"
if "$ROLLBACK" --dry-run "$incomplete" >"$TMP/incomplete.out" 2>"$TMP/incomplete.err"; then
  fail "rollback accepted an incomplete snapshot"
fi
grep -F 'incomplete-snapshot' "$TMP/incomplete.err" >/dev/null || fail "rollback refusal was not typed"

printf '%s\n' 'PASS: four-tool rename transaction harness'
