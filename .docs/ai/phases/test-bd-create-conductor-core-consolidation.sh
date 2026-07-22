#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
FILTER="$HERE/reconcile-active-bead.jq"
FIXTURE="$HERE/fixtures/bead-reconciliation/open-current.json"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

JQ_ARGS=(
  --arg id 'fixture-current-v2'
  --arg title 'Fixture current v2 contract'
  --arg description 'Canonical generated description'
  --arg acceptance 'Canonical generated acceptance'
  --arg notes 'tier_floor: lead · complexity: M · verify_cmd: cargo test fixture'
  --argjson priority 1
  --arg issue_type task
  --argjson estimate 120
  --argjson metadata '{"tier_floor":"lead","complexity":"M","verify_cmd":"cargo test fixture"}'
)

expect_match() {
  local label="$1" input="$2"
  if ! jq -e "${JQ_ARGS[@]}" -f "$FILTER" "$input" >/dev/null; then
    echo "expected reconciliation match: $label" >&2
    exit 1
  fi
}

expect_mismatch() {
  local label="$1" input="$2"
  if jq -e "${JQ_ARGS[@]}" -f "$FILTER" "$input" >/dev/null; then
    echo "expected reconciliation mismatch: $label" >&2
    exit 1
  fi
}

expect_match canonical "$FIXTURE"

for field in description acceptance_criteria notes; do
  jq --arg field "$field" '.[0][$field] = "stale"' "$FIXTURE" >"$TMP/stale-$field.json"
  expect_mismatch "stale $field" "$TMP/stale-$field.json"
done

for status in in_progress blocked closed; do
  jq --arg status "$status" '.[0].status = $status' "$FIXTURE" >"$TMP/status-$status.json"
  expect_mismatch "status $status" "$TMP/status-$status.json"
done

jq '.[0].priority = 2' "$FIXTURE" >"$TMP/stale-priority.json"
expect_mismatch 'stale priority' "$TMP/stale-priority.json"
jq '.[0].issue_type = "feature"' "$FIXTURE" >"$TMP/stale-type.json"
expect_mismatch 'stale type' "$TMP/stale-type.json"
jq '.[0].estimated_minutes = 60' "$FIXTURE" >"$TMP/stale-estimate.json"
expect_mismatch 'stale estimate' "$TMP/stale-estimate.json"
jq '.[0].metadata.verify_cmd = "cargo test stale"' "$FIXTURE" >"$TMP/stale-metadata.json"
expect_mismatch 'stale metadata' "$TMP/stale-metadata.json"

FAKE_ROOT="$TMP/root"
FAKE_BIN="$TMP/bin"
mkdir -p "$FAKE_BIN" "$FAKE_ROOT/guildhall/.docs/ai/phases"
for repo in guildhall conductor bursar hindsight warden provenance gauntlet envoy foreman; do
  mkdir -p "$FAKE_ROOT/$repo/.beads"
done
: >"$FAKE_ROOT/guildhall/.docs/ai/phases/conductor-core-consolidation-spec.md"
cat >"$FAKE_BIN/bd" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == "-C" && "$3" == "show" ]] || exit 2
id="$4"
case "$id" in
  conductor-run-contract|conductor-bursar-roster|conductor-arena-loop|conductor-eval-fold|\
  bursar-roster-contract|bursar-roster-migrate|bursar-roster-snapshot|\
  hindsight-conductor-runs|conductor-run-v2)
    printf '[{"id":"%s","status":"closed"}]\n' "$id"
    ;;
  *)
    exit 1
    ;;
esac
EOF
chmod +x "$FAKE_BIN/bd"

if GUILDHALL_GIT_ROOT="$FAKE_ROOT" PATH="$FAKE_BIN:$PATH" \
  "$HERE/bd-create-conductor-core-consolidation.sh" --resume \
  >"$TMP/non-open-current.out" 2>&1; then
  echo 'expected generator to reject an unlisted closed current definition' >&2
  exit 1
fi
NON_OPEN_OUTPUT=$(<"$TMP/non-open-current.out")
if [[ "$NON_OPEN_OUTPUT" != *'refusing non-open current definition: conductor/conductor-run-v2'* ]]; then
  echo 'generator did not distinguish listed history from a non-open current definition' >&2
  exit 1
fi

echo 'reconciliation fixture: canonical match and stale contract/status rejection passed'
