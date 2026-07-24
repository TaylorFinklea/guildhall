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
for repo in guildhall undertake musterroll afterfact cautionlight provenance gauntlet envoy foreman; do
  mkdir -p "$FAKE_ROOT/$repo/.beads"
done
: >"$FAKE_ROOT/guildhall/.docs/ai/phases/undertake-core-consolidation-spec.md"
cat >"$FAKE_BIN/bd" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == "-C" ]] || exit 2
repo="$2"
operation="$3"
scenario="${FAKE_BD_SCENARIO:-empty}"

case "$operation" in
  show)
    id="$4"
    if [[ "$scenario" == "collision" ]]; then
      case "$id" in
        conductor-run-contract|conductor-bursar-roster|conductor-arena-loop|conductor-eval-fold|\
        bursar-roster-contract|bursar-roster-migrate|bursar-roster-snapshot|\
        hindsight-conductor-runs|hindsight-store|hindsight-ingest|hindsight-event-v2|\
        warden-findings|warden-readonly-cutover|undertake-run-v2)
          printf '[{"id":"%s","status":"closed"}]\n' "$id"
          exit 0
          ;;
      esac
    fi
    state="$repo/.beads/fake-$id.json"
    if [[ -f "$state" ]]; then
      cat "$state"
      exit 0
    fi
    if [[ "$scenario" == "apply" ]]; then
      case "$id" in
        conductor-ldq|conductor-z90|conductor-ldz|conductor-0ma|conductor-1br|\
        conductor-1i9|conductor-vnu|conductor-9uk|conductor-cwl|conductor-wxx|\
        conductor-vly|conductor-j84|conductor-zg9|conductor-5tg|conductor-z8z|\
        bursar-trz|hindsight-d96|hindsight-byi|hindsight-6h8|hindsight-976|\
        hindsight-3kn|hindsight-vxd|hindsight-pov|hindsight-w5w|\
        provenance-5fu|provenance-a2g|provenance-f7d|provenance-srt|\
        gauntlet-lj5|gauntlet-289|gauntlet-be9|\
        envoy-6p5|envoy-ct9|envoy-4yr|guildhall-y10|guildhall-6mc)
          printf '[{"id":"%s","status":"open","dependencies":[]}]' "$id"
          exit 0
          ;;
      esac
    fi
    exit 1
    ;;
  create)
    shift 3
    id=
    dry_run=false
    while (($#)); do
      case "$1" in
        --id)
          id="$2"
          shift 2
          ;;
        --dry-run)
          dry_run=true
          shift
          ;;
        *)
          shift
          ;;
      esac
    done
    [[ -n "$id" ]] || exit 2
    mode=apply
    if [[ "$dry_run" == true ]]; then
      mode=dry-run
    else
      printf '[{"id":"%s","status":"open","dependencies":[]}]' "$id" \
        >"$repo/.beads/fake-$id.json"
    fi
    printf 'fake create: %s mode=%s\n' "$id" "$mode"
    ;;
  dep)
    [[ "$4" == "add" ]]
    printf 'fake dependency: %s blocked-by %s\n' "$5" "$6"
    ;;
  *)
    exit 2
    ;;
esac
EOF
chmod +x "$FAKE_BIN/bd"

if ! GUILDHALL_GIT_ROOT="$FAKE_ROOT" FAKE_BD_SCENARIO=empty PATH="$FAKE_BIN:$PATH" \
  "$HERE/bd-create-undertake-core-consolidation.sh" --dry-run \
  >"$TMP/dry-run.out" 2>&1; then
  cat "$TMP/dry-run.out" >&2
  echo 'expected fresh-database --dry-run to render the complete plan' >&2
  exit 1
fi
DRY_RUN_OUTPUT=$(<"$TMP/dry-run.out")
DRY_RUN_CREATE_COUNT=$(grep -c '^fake create:' <<<"$DRY_RUN_OUTPUT")
if [[ "$DRY_RUN_CREATE_COUNT" -ne 26 ]] \
  || [[ "$DRY_RUN_OUTPUT" != *'fake create: undertake-run-v2 mode=dry-run'* ]] \
  || [[ "$DRY_RUN_OUTPUT" != *'fake create: guildhall-retire mode=dry-run'* ]] \
  || [[ "$DRY_RUN_OUTPUT" != *'dry-run dependency: undertake/undertake-loop-kernel blocked-by conductor-1i9'* ]] \
  || [[ "$DRY_RUN_OUTPUT" != *'dry run complete: no Beads or dependencies were written'* ]]; then
  cat "$TMP/dry-run.out" >&2
  echo 'fresh-database --dry-run output did not contain the complete generated plan' >&2
  exit 1
fi

if ! GUILDHALL_GIT_ROOT="$FAKE_ROOT" FAKE_BD_SCENARIO=apply PATH="$FAKE_BIN:$PATH" \
  "$HERE/bd-create-undertake-core-consolidation.sh" --apply \
  >"$TMP/apply.out" 2>&1; then
  cat "$TMP/apply.out" >&2
  echo 'expected --apply to reach and complete definition processing' >&2
  exit 1
fi
APPLY_OUTPUT=$(<"$TMP/apply.out")
APPLY_CREATE_COUNT=$(grep -c '^fake create:' <<<"$APPLY_OUTPUT")
if [[ "$APPLY_CREATE_COUNT" -ne 26 ]] \
  || [[ "$APPLY_OUTPUT" != *'fake create: undertake-run-v2 mode=apply'* ]] \
  || [[ "$APPLY_OUTPUT" != *'fake create: guildhall-retire mode=apply'* ]] \
  || [[ "$APPLY_OUTPUT" != *'fake dependency: undertake-loop-kernel blocked-by conductor-1i9'* ]] \
  || [[ "$APPLY_OUTPUT" != *'Bead creation complete. Run bd lint and bd dep cycles in every affected repo before dispatch.'* ]]; then
  cat "$TMP/apply.out" >&2
  echo '--apply output did not contain the complete generated plan' >&2
  exit 1
fi

if GUILDHALL_GIT_ROOT="$FAKE_ROOT" FAKE_BD_SCENARIO=collision PATH="$FAKE_BIN:$PATH" \
  "$HERE/bd-create-undertake-core-consolidation.sh" --resume \
  >"$TMP/non-open-current.out" 2>&1; then
  echo 'expected generator to reject an unlisted closed current definition' >&2
  exit 1
fi
NON_OPEN_OUTPUT=$(<"$TMP/non-open-current.out")
if [[ "$NON_OPEN_OUTPUT" != *'refusing non-open current definition: undertake/undertake-run-v2'* ]]; then
  echo 'generator did not distinguish listed history from a non-open current definition' >&2
  exit 1
fi

DEMO="$HERE/../../../demo/run.sh"
DEMO_LOG="$TMP/demo.log"
cat >"$FAKE_BIN/suite-tool" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
name=$(basename "$0")
printf '%s %s\n' "$name" "$*" >>"$GUILDHALL_DEMO_LOG"
case "$name" in
  musterroll) printf '%s\n' '{"schema":"musterroll/status@2","providers":{}}' ;;
  afterfact) printf '%s\n' '{"schema":"afterfact/event@2","event_id":"demo","event":{},"artifact":{"path":"/tmp/demo","sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}}' ;;
  cautionlight) cat >/dev/null ;;
esac
EOF
chmod +x "$FAKE_BIN/suite-tool"
for binary in undertake musterroll afterfact cautionlight; do
  ln -s suite-tool "$FAKE_BIN/$binary"
done

help_output=$("$DEMO" --help)
for binary in undertake musterroll afterfact cautionlight; do
  [[ "$help_output" == *"$binary"* ]] || {
    echo "demo help omitted $binary" >&2
    exit 1
  }
done
GUILDHALL_BIN_DIR="$FAKE_BIN" \
GUILDHALL_GIT_ROOT="$FAKE_ROOT" \
GUILDHALL_DEMO_LOG="$DEMO_LOG" \
  "$DEMO" all >"$TMP/demo.out"
for binary in undertake musterroll afterfact cautionlight; do
  grep -q "^$binary " "$DEMO_LOG" || {
    echo "demo smoke omitted $binary" >&2
    exit 1
  }
done
while IFS= read -r retired; do
  ! grep -qi "$retired" "$DEMO_LOG" || {
    echo "demo smoke invoked a retired binary" >&2
    exit 1
  }
done < <(jq -r '.products[].old' "$HERE/../../../scripts/four-tool-rename/manifest.json")

echo 'generator modes: fresh dry-run, apply, and reconciliation rejection passed'
