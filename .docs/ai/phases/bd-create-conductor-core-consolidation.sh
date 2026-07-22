#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---dry-run}"
ROOT="${GUILDHALL_GIT_ROOT:-$HOME/git}"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SPEC="$ROOT/guildhall/.docs/ai/phases/conductor-core-consolidation-spec.md"
RECONCILE_FILTER="$SCRIPT_DIR/reconcile-active-bead.jq"

case "$MODE" in
  --dry-run|--apply|--resume) ;;
  *)
    echo "usage: $0 [--dry-run|--apply|--resume]" >&2
    exit 2
    ;;
esac

command -v bd >/dev/null || { echo "bd is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
[[ -f "$SPEC" ]] || { echo "missing spec: $SPEC" >&2; exit 1; }
[[ -f "$RECONCILE_FILTER" ]] || { echo "missing reconciliation filter: $RECONCILE_FILTER" >&2; exit 1; }

for repo in guildhall conductor bursar hindsight warden provenance gauntlet envoy foreman; do
  [[ -d "$ROOT/$repo/.beads" ]] || {
    echo "missing Beads repo: $ROOT/$repo" >&2
    exit 1
  }
done

PLANNED_IDS=()
HISTORICAL_CLOSED_IDS=(
  conductor/conductor-run-contract
  conductor/conductor-bursar-roster
  conductor/conductor-arena-loop
  conductor/conductor-eval-fold
  bursar/bursar-roster-contract
  bursar/bursar-roster-migrate
  bursar/bursar-roster-snapshot
  hindsight/hindsight-conductor-runs
  hindsight/hindsight-store
  hindsight/hindsight-ingest
  hindsight/hindsight-event-v2
  warden/warden-findings
  warden/warden-readonly-cutover
)

is_historical_closed() {
  local needle="$1" value
  for value in "${HISTORICAL_CLOSED_IDS[@]}"; do
    [[ "$value" == "$needle" ]] && return 0
  done
  return 1
}

preserve_closed_bead() {
  local repo="$1" id="$2" existing
  if [[ "$MODE" != "--resume" ]]; then
    return 0
  fi
  existing=$(bd -C "$ROOT/$repo" show "$id" --json 2>/dev/null) || {
    echo "missing listed historical Bead: $repo/$id" >&2
    exit 1
  }
  if ! is_historical_closed "$repo/$id" || ! jq -e \
    --arg id "$id" '.[0].id == $id and .[0].status == "closed"' \
    >/dev/null <<<"$existing"; then
    echo "listed historical Bead is not closed: $repo/$id" >&2
    exit 1
  fi
  echo "resume: listed closed Bead preserved as historical state: $repo/$id"
}

is_planned() {
  local needle="$1" value
  for value in "${PLANNED_IDS[@]}"; do
    [[ "$value" == "$needle" ]] && return 0
  done
  return 1
}

create_bead() {
  local repo="$1" id="$2" priority="$3" estimate="$4" tier="$5" complexity="$6"
  local verify="$7" title="$8" description="$9" acceptance="${10}" extra_notes="${11:-}"
  local notes metadata existing

  notes="tier_floor: $tier · complexity: $complexity · verify_cmd: $verify · spec: $SPEC"
  if [[ -n "$extra_notes" ]]; then
    notes="$notes · $extra_notes"
  fi
  metadata=$(printf '{"tier_floor":"%s","complexity":"%s","verify_cmd":"%s"}' \
    "$tier" "$complexity" "$verify")

  if existing=$(bd -C "$ROOT/$repo" show "$id" --json 2>/dev/null); then
    if [[ "$MODE" == "--resume" ]] && jq -e '.[0].status == "closed"' \
      >/dev/null <<<"$existing"; then
      if is_historical_closed "$repo/$id"; then
        PLANNED_IDS+=("$repo/$id")
        echo "resume: listed closed Bead preserved as historical state: $repo/$id"
        return
      fi
      echo "refusing non-open current definition: $repo/$id" >&2
      exit 1
    fi
    if [[ "$MODE" == "--resume" ]] && jq -e \
      --arg id "$id" \
      --arg title "$title" \
      --arg description "$description" \
      --arg acceptance "$acceptance" \
      --arg notes "$notes" \
      --argjson priority "$priority" \
      --arg issue_type task \
      --argjson estimate "$estimate" \
      --argjson metadata "$metadata" \
      -f "$RECONCILE_FILTER" \
      >/dev/null <<<"$existing"; then
      PLANNED_IDS+=("$repo/$id")
      echo "resume: existing open Bead contract matches: $repo/$id"
      return
    fi
    echo "refusing stale or non-open current definition: $repo/$id" >&2
    exit 1
  fi

  local create_args=(
    -C "$ROOT/$repo" create
    --id "$id"
    --type task
    --priority "$priority"
    --estimate "$estimate"
    --title "$title"
    --description "$description"
    --acceptance "$acceptance"
    --notes "$notes"
    --metadata "$metadata"
  )
  if [[ "$MODE" == "--dry-run" ]]; then
    create_args+=(--dry-run)
  fi

  bd "${create_args[@]}" < /dev/null
  PLANNED_IDS+=("$repo/$id")
}

add_dep() {
  local repo="$1" issue="$2" blocker="$3"
  if [[ "$MODE" == "--dry-run" ]]; then
    echo "dry-run dependency: $repo/$issue blocked-by $blocker"
    return 0
  fi
  if ! is_planned "$repo/$issue" && ! bd -C "$ROOT/$repo" show "$issue" --json >/dev/null 2>&1; then
    echo "dependency issue does not exist and is not planned: $repo/$issue" >&2
    exit 1
  fi
  if ! is_planned "$repo/$blocker" && ! bd -C "$ROOT/$repo" show "$blocker" --json >/dev/null 2>&1; then
    echo "dependency blocker does not exist and is not planned: $repo/$blocker" >&2
    exit 1
  fi
  if bd -C "$ROOT/$repo" show "$issue" --json | jq -e \
    --arg blocker "$blocker" '.[0].dependencies[]? | select(.id == $blocker)' \
    >/dev/null; then
    echo "dependency already present: $repo/$issue blocked-by $blocker"
    return
  fi
  bd -C "$ROOT/$repo" dep add "$issue" "$blocker" < /dev/null
}

preserve_closed_bead conductor conductor-run-contract
preserve_closed_bead conductor conductor-bursar-roster
preserve_closed_bead conductor conductor-arena-loop
preserve_closed_bead conductor conductor-eval-fold
preserve_closed_bead bursar bursar-roster-contract
preserve_closed_bead bursar bursar-roster-migrate
preserve_closed_bead bursar bursar-roster-snapshot
preserve_closed_bead hindsight hindsight-conductor-runs

# ---------------------------------------------------------------------------
# Conductor: one explicit verified job-loop kernel.
# ---------------------------------------------------------------------------


create_bead conductor conductor-run-v2 1 300 lead XL \
  'cargo test run && cargo test quarantine && cargo test bursar && cargo clippy --all-targets -- -D warnings' \
  'Cut Conductor to strict v2 roster and run contracts' \
  'Read the consolidation spec Stable process contracts and role-aware plan-routing sections first. Files: src/bursar.rs, src/run.rs, src/quarantine.rs, src/dispatch_cycle.rs, src/route.rs, and focused schema fixtures. Consume only bursar/roster@2, validate policy_sha256, copy and pin the exact snapshot bytes per prepared run, and write deny-unknown-fields conductor/run@2 plus conductor/event@2 artifacts under runs-v2. Make job/details, targets, constrained stage routes, and plan progress structural. Quiesce and drain v1 pending, implementing, or reclaimable state before activating the v2 scanner; never scan legacy runs or parse v1/Arena state.' \
  'Tests reject v1, Arena, unknown fields, duplicate or mismatched execution identities, invalid target/job/state combinations, altered roster snapshots, and mixed-schema scans. Reopen/resume preserves exact transition state, stage bindings, event sequence, and artifact hashes. Finished v1 runs remain inert; deployment preflight proves no actionable v1 state remains. Full focused tests and strict Clippy pass.' \
  'cross-repo-gate: bursar-roster-v2-snapshot (publishes bursar/roster-config@2 and bursar/roster@2); closed conductor-run-contract and conductor-bursar-roster remain historical evidence'

create_bead conductor conductor-role-routing 1 300 lead XL \
  'cargo test role_routing && cargo test scheduler && cargo test reservation && cargo clippy --all-targets -- -D warnings' \
  'Add durable generic role routing and smooth weighted rotation' \
  'Read the consolidation spec Role-aware plan routing section first. Files: src/config.rs, src/bursar.rs, src/route.rs, src/run.rs, conductor.toml, and focused scheduler/lock modules. Parse strict generic role/profile bindings with nonzero weights and a digest over canonical policy plus the pinned Bursar policy digest. Bind openai-codex--omp--gpt-5.6-sol--xhigh at 60, anthropic--omp--claude-opus-4-8--max at 20, and opencode-go--omp--kimi-k3--max at 20 for the initial plan pool. Implement deterministic smooth weighted round-robin in independent role/stage lanes under fs2 guards. Apply hard eligibility before scoring; persist checked scores, sequence, and irreversible PendingApproval/Committed/Canceled reservations linked to preallocated RunIds. Pin complete planner/peer/second-opinion candidate sets and relational constraints; do not read OMP personal role fallbacks or move policy into Bursar.' \
  'All-eligible 60/20/20 planner reservations yield exactly 12/4/4 over 20 preparations, including canceled turns. Tests cover deterministic ties, restart persistence, temporary ineligibility without credit accrual, checked arithmetic, policy-digest resets, cancel/commit irreversibility, concurrent preparation, orphan reconciliation, delayed constrained reviewer binding, and fail-closed semantic config. Every bound profile is enabled, eligible, exact-coordinate approved, and tagged with the required role in the pinned snapshot.' \
  'cross-repo-gate: bursar-roster-v2-snapshot with strict role capabilities and the three approved OMP plan profiles; depends-on: conductor-run-v2'

create_bead conductor conductor-job-registry 1 120 lead M \
  'cargo test job' \
  'Add the closed work review consult and plan job registry' \
  'Read the consolidation spec Conductor loop and job model section first. Files: src/cli.rs, src/config.rs, focused job modules, and templates. Add the closed JobKind set work, review, consult, and plan against strict v2 run details. Review retains the provider-diverse N-reviewer plus independent-judge contract. Plan is a distinct bounded job, not a hidden work stage or second loop engine. Config binds jobs to Bursar profile IDs, mutation posture, limits, verifier, approval, and the generic role-policy seam without adding a workflow language, plugin loader, compatibility parser, or fleet-scan behavior.' \
  'Exactly work, review, consult, and plan parse and validate against a pinned Bursar v2 snapshot; Arena and unknown jobs fail as usage/config errors. Job-tagged details cannot cross variants, read-only jobs cannot request write-capable execution, plan cannot mutate its target, and explain output shows pinned selection and fallback/constraint reasons. Existing review behavior remains N-plus-one and legacy CLI tests stay green.' \
  $'depends-on: conductor-run-v2\nThe validated review binding remains the operational source for the provider-diverse N-reviewer panel plus independent Lead judge. Generic plan role/profile weights and stage constraints belong to Conductor role policy; Bursar v2 supplies only exact identities, capabilities, and eligibility.'

create_bead conductor conductor-loop-kernel 1 180 lead L \
  'cargo test loop' \
  'Build the native fresh-context resumable explicit-target loop kernel' \
  'Read the consolidation spec Conductor loop and job model section and the current Ralph driver before editing. Files: src/run.rs, src/dispatch.rs, src/verify.rs, src/plan.rs, src/cli.rs, and focused new loop code. Build on strict v2 run/event state and implement one explicit repo plus Bead or artifact target, one fresh harness context per bounded iteration, durable state before and after every subprocess, resume and reclaim, identity-checked commit success, exclusive repo lease, bounded failure continuation, and verifier-gated terminal completion. Reuse existing Exec and verifier seams; do not shell out to Ralph as the steady-state engine.' \
  'Sandbox tests prove kill-and-resume, unrelated-commit rejection, concurrent-repo-lease rejection, claim release on pre-worker abort, continuation after one failed attempt, max-iteration stop, verifier failure feedback, and successful terminal completion against runs-v2; no test touches a live repo or Beads database. Legacy dispatch remains isolated compatibility behavior until cutover.' \
  'existing correctness gates: conductor-1i9 conductor-vnu conductor-9uk conductor-cwl conductor-wxx; depends-on: conductor-run-v2 conductor-job-registry'

create_bead conductor conductor-adversarial-job 1 120 senior M \
  'cargo test adversarial' \
  'Preserve adversarial review as the Conductor review job' \
  'Read the shipped adversarial-review spec and consolidation review-job rules first. Files: src/adversarial.rs, src/cli.rs, src/config.rs, src/deck.rs, src/ledger.rs or its run-event replacement, and review templates. Route the existing provider-diverse N-plus-one workflow through JobKind review without weakening artifact hashing, immutable approval, read-only execution, schema repair, anonymous synthesis, minority preservation, provider writeback, or mutation proof. Keep adversarial-review as a warning-free compatibility alias for the first cutover release.' \
  'The review job produces behaviorally equivalent plans, approvals, reviewer outputs, judge synthesis, run events, and reports; injected artifact or Bead text cannot change policy or verdict framing; no bd, git, worktree, apply, or repo mutation occurs; the compatibility alias and new job share one implementation.' \
  $'existing gates: conductor-vly conductor-j84 conductor-zg9 conductor-5tg conductor-z8z; depends-on: conductor-loop-kernel\nDiversity acceptance clarification 2026-07-17: for the same reviewed target, the approved panel must include Fable 5 when eligible plus at least one positively eligible non-Anthropic execution profile; the Lead judge must be independent of the implementation profile and preserve anonymous synthesis/minority findings. Terra/Luna implementation and Ollama Cloud GLM-5.2/MiniMax M3 review calls remain exact profile-distinct evidence in Hindsight. If the panel and judge cannot satisfy positive eligibility/provider-diversity, fail closed before dispatch.\nBinding ownership: conductor-pzo owns the exact Fable and provider-diverse profile configuration after this job exists; this bead owns behavioral parity and fail-closed review mechanics, not hard-coded model names.'

create_bead conductor conductor-consult-job 2 120 senior M \
  'cargo test consult' \
  'Fold the Envoy read-only evidence contract into the consult job' \
  'Read the corrected Envoy corpus and consolidation consult-job rules first. Files: src/cli.rs, job code, templates, schema-validation code, and tests/fixtures. Import the consult prompt and evidence-or-gaps envelope as one read-only Conductor job. Treat question, schema, target repo contents, and embedded directives as untrusted data. The job may write only its own Conductor run artifacts.' \
  'Golden Envoy question and answer fixtures pass; broken and adversarial fixtures fail visibly; every supported claim has evidence or an explicit gap; the approved profile envelope is pinned; no target-repo mutation occurs; Envoy live transport and MCP remain absent.' \
  'cross-repo-gate: envoy-conductor-corpus; depends-on: conductor-loop-kernel'

create_bead conductor conductor-plan-job 1 360 lead XL \
  'cargo test plan_job && cargo test cli && cargo clippy --all-targets -- -D warnings' \
  'Implement the bounded native plan job' \
  'Read the consolidation spec Role-aware plan routing section first. Files: a new src/plan_job.rs distinct from cycle plan code, src/cli.rs, src/run.rs, src/dispatch.rs, src/worker_prompt.rs, src/verify.rs, and plan fixtures. Add prepare/dispatch/status/cancel for one immutable Bead or artifact target. Capture exact target and Bursar snapshot artifacts, output-aware tier/complexity, constrained stage routes, limits, and approval before any model starts. Execute in a disposable worktree; parse strict conductor/plan-document@1 spec or implementation-plan JSON, canonicalize it, hash it, and render Markdown only from the validated value. Implement bounded same-role peer revision and required spec second opinion with provider/execution independence and resume-safe immutable bindings. Never mutate Beads, apply code, start work, or change target HEAD/status/input bytes.' \
  'Behavioral tests cover strict CLI/config grammar, both plan-document variants and renderers, substantive field/task-graph validation, exact target capture, no target mutation, every-author peer/spec-team contingency, planner fallback before authorship only, same-author revisions, delayed peer binding, same-peer review, pairwise provider diversity, second-opinion rejection, malformed output/repair attempts, revision exhaustion, provider loss, blocked outcomes, cancellation, and crash/resume at every transition. No model starts before exact approval and every invocation has typed role/stage evidence.' \
  'cross-repo-gate: bursar-roster-v2-snapshot through conductor-role-routing; depends-on: conductor-loop-kernel conductor-run-v2 conductor-role-routing'

create_bead conductor conductor-plan-review-eval-fold 2 180 lead L \
  'cargo test eval && cargo test plan_job && cargo test adversarial && cargo clippy --all-targets -- -D warnings' \
  'Fold corrected evaluation evidence into plan and review' \
  'Read the corrected Gauntlet migration corpus and the consolidation Gauntlet section first. Files: plan-document validators, plan peer/second-opinion rubrics, adversarial review fixtures, generic run-event evidence, and migrated corpus fixtures. Reuse corrected static lint, explicit base/reference discrimination, worktree-integrity, conjunctive verifier-plus-judge, replay, and A/B expectations to test plan and review behavior. Do not add a candidate runtime, winner/application workflow, Arena compatibility path, second executor, or Conductor-owned scorecard aggregation.' \
  'Every imported corpus case has deterministic plan/review expectations; empty or merely schema-shaped output cannot pass; base/reference discrimination remains explicit; target integrity is proven; review stays N-plus-one; plan gates preserve peer and spec second-opinion constraints; replay/A-B evidence is represented through generic job/role/stage attempts for Hindsight. No fresh metered dispatch is required and no legacy comparison command or config remains.' \
  'cross-repo-gate: gauntlet-conductor-corpus; depends-on: conductor-plan-job conductor-adversarial-job'

# ---------------------------------------------------------------------------
# Bursar: configured and currently eligible execution profiles.
# ---------------------------------------------------------------------------

create_bead bursar bursar-roster-v2-contract 1 120 lead M \
  'cargo test roster' \
  'Define the strict Bursar v2 provider and execution-profile roster' \
  'Read the consolidation spec Bursar roster snapshot section first. Files: focused roster modules, src/lib.rs, and roster.toml. Define strict bursar/roster-config@2 with opaque ProfileId, exact unique ExecutionKey, distinct ProviderId and AvailabilityKey, and private sorted duplicate-free RoleSet. Preserve tier, ceiling, efficiency, cost, data policy, enablement, and invocation coordinates. Require nonempty roles for enabled profiles, validate RoleId with the identifier grammar, and keep fallback, weights, review rules, and job policy outside Bursar.' \
  'Valid v2 config round-trips deterministically; duplicate IDs, duplicate execution coordinates, duplicate/invalid/empty enabled roles, dangling providers, incompatible effort, unknown keys, and empty invocation coordinates fail closed. Disabled profiles may have no roles. Role ordering is canonical, exact provider identity is preserved for diversity, and no execution coordinate or capability fact is inferred by parsing an opaque ProfileId.' \
  'owner-boundary: unordered capability facts only; no dispatch, weights, fallback, or scorecards; identity-boundary: ProfileId labels are never parsed; closed bursar-roster-contract remains immutable v1 evidence'

create_bead bursar bursar-roster-v2-migrate 1 120 senior M \
  'cargo test roster_migration' \
  'Migrate the immutable Bursar v1 identity set into the v2 roster' \
  'Keep the immutable historical migration fixture, prove its execution identities remain a subset of v2, and add separate v2 role fixtures. Add these enabled rows by asserting ProfileId separately from every field: openai-codex--omp--gpt-5.6-sol--xhigh => ExecutionKey(provider_id=openai-codex, model=gpt-5.6-sol, harness=omp, dispatch_id=openai-codex/gpt-5.6-sol, reasoning_effort=xhigh); anthropic--omp--claude-opus-4-8--max => ExecutionKey(provider_id=anthropic, model=claude-opus-4-8, harness=omp, dispatch_id=anthropic/claude-opus-4-8, reasoning_effort=max); opencode-go--omp--kimi-k3--max => ExecutionKey(provider_id=opencode-go, model=kimi-k3, harness=omp, dispatch_id=opencode-go/kimi-k3, reasoning_effort=max). Every row is tier=lead, ceiling=XL, efficiency=heavy, data_policy=standard, enabled=true, with the sorted roles advisor/default/designer/plan/slow/task/vision. Assert vision/designer only for these exact confirmed harness paths; never infer any fact from a base model name or opaque ProfileId.' \
  'The legacy fixture remains byte-unchanged and every historical execution identity appears exactly once in v2. Tests assert every ProfileId, ExecutionKey field, enabled Lead/XL envelope, heavy efficiency, standard data policy, and exact sorted advisor/default/designer/plan/slow/task/vision RoleSet for all three OMP rows without parsing their labels. All other enabled profiles have default/task plus tier-appropriate roles; omissions, substitutions, and duplicates fail; roster.toml contains no credentials or Conductor policy.' \
  'depends-on: bursar-roster-v2-contract; normative matrix: exact OMP execution/profile facts in the consolidation spec; ProfileId is opaque; closed bursar-roster-migrate remains immutable v1 evidence'

create_bead bursar bursar-roster-v2-snapshot 1 120 senior M \
  'cargo test roster_snapshot && cargo test status' \
  'Publish strict Bursar v2 roster list check and snapshot commands' \
  'Read the consolidation Bursar v2 snapshot contract first. Emit strict bursar/roster@2 with raw source artifact provenance, canonical nonvolatile policy_sha256, exact sorted role/provider/execution identities, and point-in-time availability. Keep RosterSourceArtifact, RosterPolicyDigest, and copied run-local RosterSnapshotArtifact distinct. Output data only on stdout and diagnostics on stderr; do not add job selection or fallback policy.' \
  'Snapshot output conforms to bursar/roster@2; equivalent role reordering changes the raw TOML hash but preserves policy_sha256; exact emitted bytes receive a separate digest when captured. The three mandated OMP rows retain their independently asserted exact ExecutionKeys, enabled Lead/XL envelope, heavy efficiency, standard data policy, and advisor/default/designer/plan/slow/task/vision roles; no field is inferred from ProfileId. Unreadable observations, invalid identities, or unknown/stale/exhausted state cannot yield eligibility. List/check are pure reads and malformed config or missing status fails closed.' \
  'existing gate: bursar-trz; depends-on: bursar-roster-v2-migrate; required OMP snapshot rows use the exact normative matrix in the consolidation spec; ProfileId is opaque; closed bursar-roster-snapshot remains immutable v1 evidence'

# ---------------------------------------------------------------------------
# Hindsight: canonical observations plus rebuildable evidence index.
# ---------------------------------------------------------------------------

create_bead hindsight hindsight-store 1 180 lead L \
  'cargo test store' \
  'Add the rebuildable Hindsight SQLite store and migrations' \
  'Read the consolidation spec Hindsight storage architecture section and current src/event.rs, src/recap.rs, and Cargo.toml first. Add a focused store module and numbered SQL migrations for source_files, events, runs, attempts, artifacts, observations, attributions, and coverage_gaps. Use rusqlite with bundled SQLite, rollback-journal mode, foreign keys, finite busy timeout, transactional migrations, application_id, user_version, integrity check, and db rebuild. Do not store raw prompts, file contents, environment dumps, or full tool input.' \
  'A temporary database migrates from empty to current schema atomically; unsupported newer schema fails closed; integrity_check reports corruption; db rebuild deletes only derived state and preserves the canonical observation journal; file permissions are owner-only; tests assert journal_mode is not WAL until a fixed SQLite version gate exists.' \
  'storage-boundary: SQLite derived; raw artifacts and observation journal canonical'

create_bead hindsight hindsight-ingest 1 180 senior L \
  'cargo test ingest' \
  'Implement incremental idempotent Hindsight ingestion' \
  'Read current source discovery/parsers and the consolidation Incremental ingestion section first. Files: src/recap.rs, src/sources, src/gaps.rs, the new store, and focused ingest code. Track source file identity, fingerprint, size, mtime, and cursor; append growth incrementally; invalidate and replay only a replaced or truncated file; deduplicate with stable event IDs. Parse per record so one malformed byte or line becomes a coverage gap instead of discarding the whole file or root.' \
  'Two identical ingests produce identical row counts; appended input adds only new rows; truncation/replacement removes stale derived rows for that source and replays it; unreadable entries and malformed records become isolated gaps; all wired sources including AGY, Beads, and harness-deck are exercised by fixtures; full current tests remain green.' \
  'existing gates: hindsight-d96 hindsight-byi hindsight-6h8 hindsight-976; depends-on: hindsight-store'

create_bead hindsight hindsight-event-v2 1 120 lead M \
  'cargo test event_stream' \
  'Publish hindsight/event@2 with source artifact identity' \
  'Read src/event.rs, src/cli.rs, the Guildhall stdout-layer ADR, and the consolidation Hindsight event stream section first. Emit one versioned envelope per line with stable event ID, normalized redacted event, and canonical raw source artifact path plus SHA-256. Surface coverage gaps on the events path. Keep a bounded explicit v1 compatibility flag until consumers migrate; unknown filters and schemas fail visibly; preserve SIGPIPE-safe writes.' \
  'Default output validates as hindsight/event@2; raw_ref remains exact path and line; artifact identifies the raw source rather than SQLite; unsafe tool input stays opt-in with warning; gaps are not discarded; unknown schema consumers can reject deterministically; pipe to head exits cleanly; v1 compatibility is separately tested and marked temporary.' \
  'existing gates: hindsight-3kn hindsight-vxd; depends-on: hindsight-ingest'

create_bead hindsight hindsight-conductor-runs-v2 1 120 senior M \
  'cargo test conductor_source' \
  'Ingest strict Conductor v2 run manifests and events into Hindsight' \
  'Read strict conductor/run@2 and conductor/event@2 from the consolidation spec plus the existing Hindsight source-module pattern. Add a separate active-v2 Conductor source parser that validates schema, sequence, copied roster snapshot and policy digest, artifact hashes, exact profile/execution/provider identity, job, role, typed stage, target, attempts, verifier/reviewer results, usage, and terminal outcome. Store run and attempt rows without importing raw stdout or prompts; reject v1/Arena rows in the active v2 source. Preserve hindsight-conductor-runs as immutable closed v1 evidence.' \
  'Complete, interrupted, resumed, blocked, rejected, failed, and schema-invalid v2 fixtures produce expected run, stage, attempt, artifact, and coverage-gap rows. Duplicate ingestion is idempotent; sequence gaps and hash mismatches fail visibly; every plan/review call remains distinct; planned and executed identities, role, stage, and job survive scorecard queries. Focused v1 fixtures continue proving the closed historical parser contract without satisfying v2 acceptance.' \
  'cross-repo-gate: conductor-run-v2; depends-on: hindsight-store hindsight-ingest; closed hindsight-conductor-runs remains immutable v1 evidence'

create_bead hindsight hindsight-observations 1 180 senior L \
  'cargo test observations && cargo test legacy_scorecard' \
  'Add canonical observations and import legacy scorecard evidence' \
  'Read the consolidation Scorecards section, current model-scorecard and model-bench formats, and Bursar append-only observation precedent first. Add hindsight/observation@1, a bounded single-write append CLI, corrections by reference rather than mutation, and a one-time idempotent importer for model-bench JSONL plus Experience Log entries. Store canonical records in ~/.local/state/hindsight/observations.jsonl and derived rows in SQLite.' \
  'Observation records have stable IDs, timestamps, subject profile or run, kind, source, rating fields, sanitized note, and optional supersedes reference; duplicate import does not duplicate rows; malformed legacy lines become gaps; imported records retain raw path/line; export reproduces the canonical journal; no SQLite file is treated as backup truth.' \
  'depends-on: hindsight-store hindsight-ingest'

create_bead hindsight hindsight-scorecards 1 180 lead L \
  'cargo test scorecard' \
  'Derive model harness profile and job scorecards in Hindsight' \
  'Read the consolidation Scorecards section and current Node digest tests first. Build views and CLI output stratified by execution profile, job, tier, and complexity. Include verifier and accepted-change rates, review outcome, no-op/retry/timeout/infra failures, wall time, tokens, provider-reported cost, cost and time per accepted change, sample count, project/task coverage, and missing-data counts. Do not infer prices or merge unlike task strata into one global winner.' \
  'Model, harness, profile, and job queries are deterministic in table and JSON modes; sparse rows remain visible and n below five is provisional; promotion recommendations require at least five verified comparable attempts across two tasks; missing cost/tokens stay unknown; legacy fixture aggregates match the old reports within documented field mappings.' \
  $'depends-on: hindsight-conductor-runs-v2 hindsight-observations\nUser comparison requirement 2026-07-17: retain exact execution profiles so Fable 5 review, Terra/Luna implementation, Ollama Cloud GLM-5.2, Ollama Cloud MiniMax M3, and same-base models on other providers remain separately comparable by job and task stratum. Every launched Conductor call, including repairs and judges, counts as an attempt; do not collapse a multi-call Bead into one opaque row.'

create_bead hindsight hindsight-scorecard-publish 2 120 senior M \
  'cargo test scorecard_publish' \
  'Publish Hindsight scorecards and evidence-pinned roster recommendations' \
  'Read src/deck.rs, harness-deck report@1, the old generator outputs, and the consolidation feedback-loop rules first. Add hindsight scorecard publish for evergreen model and harness reports and hindsight roster recommend for a versioned JSON proposal. The recommendation pins query window, evidence hash, affected Bursar profile IDs, before/after values, metrics, sample warnings, and coverage gaps. It never edits Bursar config.' \
  'Generated model and harness reports validate with the repo fixture validator; repeated generation is deterministic; real-only cost rules remain; recommendations below evidence floors are withheld with reasons; no Bursar or Conductor file changes; publisher failure does not corrupt the store.' \
  $'depends-on: hindsight-scorecards\nCompatibility-removal gate: this published Hindsight report replaces the legacy chezmoi scorecard digest only after parity is pinned. Its evidence is required by conductor-7rs before Conductor stops model-bench dual writes; Bursar recommendations remain proposal-only.'

create_bead hindsight hindsight-attribution 1 180 lead L \
  'cargo test attribution' \
  'Fold corrected Provenance attribution and queries into Hindsight' \
  'Read the corrected Provenance migration corpus, src/correlate.rs, src/confidence.rs, src/query.rs, and the consolidation Provenance section first. Port correlation strategies, confidence, surviving-hunk attribution, coverage accounting, and unreviewed-junior query into the Hindsight store and CLI. Use stored event/raw artifact evidence; false attribution remains worse than no attribution. Import existing sidecars only as migration input.' \
  'The full corrected corpus matches strategy, confidence, attribution, and gap outcomes; empty messages never match; cross-repo window-only matches are impossible; canonicalized cwd and exact hash paths work; query exit/JSON distinguish clean, flagged, and could-not-evaluate; live sample parity is documented before the Provenance shim is enabled.' \
  'cross-repo-gate: provenance-hindsight-corpus; existing gates: hindsight-pov hindsight-w5w; depends-on: hindsight-event-v2'

# ---------------------------------------------------------------------------
# Warden: a stateless advisory filter.
# ---------------------------------------------------------------------------

create_bead warden warden-findings 1 120 lead M \
  'cargo test findings' \
  'Consume Hindsight events and emit read-only Warden findings' \
  'Read core/src/classify.rs, core/src/policy.rs, core/src/audit.rs, and the consolidation Warden findings contract first. Add a small warden CLI workspace member with inspect --stdin. Validate hindsight/event@2, apply a bounded set of high-signal existing rules, and emit warden/finding@1 JSONL with input event IDs, rule, severity, claim, evidence, and gaps. Keep the operation stateless and read-only.' \
  'Golden benign, suspicious, malformed, unknown-schema, and coverage-gap streams produce deterministic findings and exit codes; valid findings exit zero, incomplete coverage exits one, usage/schema failure exits two; stdout contains JSONL only; no repo, hook config, Hindsight store, or external state is written.' \
  'cross-repo-gate: hindsight-event-v2'

create_bead warden warden-readonly-cutover 2 60 senior S \
  'cargo test --workspace && cargo run -p warden -- inspect --help' \
  'Make read-only batch advice the supported Warden product' \
  'Read AGENTS.md, README and handoff docs, adapter docs, and the consolidation Warden decision first. Document hindsight events piped to warden inspect as the supported path. Mark the Claude PreToolUse adapter experimental and uninstalled, remove pending installation instructions from active roadmap/current state, and preserve its code only as historical compatibility until archive review. Do not add enforcement.' \
  'Help and docs state exact input/output/exit semantics and no-write posture; no active handoff asks the user to install a blocking or shadow hook; workspace tests pass; a fixture pipe runs without modifying the repo or HOME.' \
  'depends-on: warden-findings'

# ---------------------------------------------------------------------------
# Corrected parity corpora from the retiring satellites.
# ---------------------------------------------------------------------------

create_bead provenance provenance-hindsight-corpus 1 120 lead M \
  'cargo test correlation_corpus' \
  'Freeze corrected Provenance attribution behavior for Hindsight migration' \
  'Finish the named correctness blockers, then read src/correlate.rs, src/confidence.rs, src/query.rs, src/store.rs, and existing fixtures. Add a compact golden corpus covering exact hash, message plus cwd plus window, competing evidence, concurrent sessions, symlink cwd, empty message, cross-repo window, unknown tier, flagged and could-not-evaluate query outcomes. Add a machine-readable expected-results fixture and a migration inventory of state/CLI behavior.' \
  'Every former P0/P1 reproducer is in the corpus and passes only with corrected behavior; expected results include strategy, confidence, evidence IDs, gaps, and query exit class; corpus uses no live HOME data; a Hindsight implementation can consume it without importing Provenance Rust types.' \
  'existing gates: provenance-5fu provenance-a2g provenance-f7d provenance-srt'

create_bead gauntlet gauntlet-conductor-corpus 1 120 lead M \
  'cargo test migration_corpus && cargo run -- lint golden-tasks' \
  'Freeze corrected Gauntlet evaluation behavior for Conductor migration' \
  'Finish the named correctness blockers, then read src/golden.rs, src/lint.rs, src/worktree.rs, src/judge.rs, src/replay.rs, src/ab.rs, src/budget.rs, and golden-tasks. Add a migration corpus and inventory that pins static lint, explicit discrimination smoke, empty-output failure, worktree integrity, conjunctive Verify plus judge, replay, and A-B results. Separate scorecard/cost aggregation as Hindsight-owned.' \
  'All golden tasks fail at base and pass at reference; empty dispatch output fails; lint makes no worktree mutation; smoke mutation is explicit; expected run and A-B outputs are machine-readable; no fresh metered dispatch is required; cost-parser behavior is identified for Hindsight rather than copied into Conductor.' \
  'existing gates: gauntlet-lj5 gauntlet-289 gauntlet-be9'

create_bead envoy envoy-conductor-corpus 1 60 senior S \
  'bash scripts/check-consult-prompt.sh && bash scripts/test-fixtures.sh' \
  'Freeze the corrected Envoy consult contract for Conductor migration' \
  'Finish the three validator defects, then read skill/consult-prompt.md, skill/envelope.schema.json, scripts/validate-envelope.sh, and fixtures. Add an automated fixture runner and adversarial fixtures that pin read-only boolean typing, evidence and gaps array typing, evidence-or-gaps, untrusted question/schema text, and cited answer behavior. Add a concise migration map from Envoy files to the Conductor consult job.' \
  'Golden question and answer pass; broken, wrong-type, empty-evidence-and-gaps, and injected fixtures fail with stable reasons; the runner is noninteractive and read-only; no live transport or MCP is added.' \
  'existing gates: envoy-6p5 envoy-ct9 envoy-4yr'

create_bead foreman foreman-skill 1 120 lead M \
  'python3 /Users/tfinklea/.codex/skills/.system/skill-creator/scripts/quick_validate.py skill/foreman && bash skill/foreman/scripts/test-render.sh' \
  'Replace the planned Foreman binary with a validated skill package' \
  'Read the Foreman v1 spec, decisions, standard skill-creator instructions, and consolidation Foreman section first. Create skill/foreman/SKILL.md with only the essential workflow, references for the exact spec and Bead contracts, and one deterministic script that renders but never executes a reviewable bd-create shell script. Preserve no-Verify refusal, exact spec facts, grep evidence for codebase prescriptions, dual routing metadata, and no silent drops. Do not build Rust code.' \
  'The standard skill validator passes; a fixture interview and recon render the expected spec plus Bead script byte-for-byte; a missing Verify bead is reported and omitted; an uncited code prescription is downgraded to a mirror marker; the script never invokes bd; the six deferred binary Beads remain untouched until canonical chezmoi installation succeeds.' \
  'migration-tail: install from canonical chezmoi source before closing foreman-m0 through foreman-m4'

# ---------------------------------------------------------------------------
# Guildhall retirement is last and proves the four-tool pipe.
# ---------------------------------------------------------------------------

create_bead guildhall guildhall-retire 2 120 lead M \
  'bash demo/run.sh --build && bash demo/run.sh all' \
  'Prove the four-tool pipeline and prepare Guildhall for archive' \
  'Read the consolidation cutover gates, current README, USAGE, demo, roadmap, and decisions first. Replace the eight-member runtime demo with a no-metered Bursar to Conductor to Hindsight to Warden vertical slice that verifies schema and artifact hashes. Publish the final ownership and compatibility-shim map, preserve ADR/spec history, remove active claims that retired binaries are products, and prepare an archive handoff without deleting repos or pushing.' \
  'All eleven cutover gates are checked with artifact evidence; the demo performs no metered dispatch and passes from a clean shell; README and USAGE name only the four surviving products and the temporary shims; roadmap has no active Guildhall product work; history remains accessible; archive action is left for the human.' \
  'cross-repo-gate: all consolidation Beads plus chezmoi and private-state tails; local gates: guildhall-y10 guildhall-6mc'

# ---------------------------------------------------------------------------
# Local dependency graph. Cross-repo gates are carried in notes and the plan.
# ---------------------------------------------------------------------------

add_dep conductor conductor-run-v2 conductor-ldq
add_dep conductor conductor-run-v2 conductor-z90
add_dep conductor conductor-run-v2 conductor-ldz
add_dep conductor conductor-run-v2 conductor-0ma
add_dep conductor conductor-run-v2 conductor-1br
add_dep conductor conductor-role-routing conductor-run-v2
add_dep conductor conductor-job-registry conductor-run-v2
add_dep conductor conductor-loop-kernel conductor-run-v2
add_dep conductor conductor-loop-kernel conductor-job-registry
add_dep conductor conductor-loop-kernel conductor-1i9
add_dep conductor conductor-loop-kernel conductor-vnu
add_dep conductor conductor-loop-kernel conductor-9uk
add_dep conductor conductor-loop-kernel conductor-cwl
add_dep conductor conductor-loop-kernel conductor-wxx
add_dep conductor conductor-adversarial-job conductor-loop-kernel
add_dep conductor conductor-adversarial-job conductor-vly
add_dep conductor conductor-adversarial-job conductor-j84
add_dep conductor conductor-adversarial-job conductor-zg9
add_dep conductor conductor-adversarial-job conductor-5tg
add_dep conductor conductor-adversarial-job conductor-z8z
add_dep conductor conductor-consult-job conductor-loop-kernel
add_dep conductor conductor-plan-job conductor-loop-kernel
add_dep conductor conductor-plan-job conductor-run-v2
add_dep conductor conductor-plan-job conductor-role-routing
add_dep conductor conductor-plan-review-eval-fold conductor-plan-job
add_dep conductor conductor-plan-review-eval-fold conductor-adversarial-job

add_dep bursar bursar-roster-v2-migrate bursar-roster-v2-contract
add_dep bursar bursar-roster-v2-snapshot bursar-roster-v2-migrate
add_dep bursar bursar-roster-v2-snapshot bursar-trz

add_dep hindsight hindsight-ingest hindsight-store
add_dep hindsight hindsight-ingest hindsight-d96
add_dep hindsight hindsight-ingest hindsight-byi
add_dep hindsight hindsight-ingest hindsight-6h8
add_dep hindsight hindsight-ingest hindsight-976
add_dep hindsight hindsight-event-v2 hindsight-ingest
add_dep hindsight hindsight-event-v2 hindsight-3kn
add_dep hindsight hindsight-event-v2 hindsight-vxd
add_dep hindsight hindsight-conductor-runs-v2 hindsight-store
add_dep hindsight hindsight-conductor-runs-v2 hindsight-ingest
add_dep hindsight hindsight-observations hindsight-store
add_dep hindsight hindsight-observations hindsight-ingest
add_dep hindsight hindsight-scorecards hindsight-conductor-runs-v2
add_dep hindsight hindsight-scorecards hindsight-observations
add_dep hindsight hindsight-scorecard-publish hindsight-scorecards
add_dep hindsight hindsight-attribution hindsight-event-v2
add_dep hindsight hindsight-attribution hindsight-pov
add_dep hindsight hindsight-attribution hindsight-w5w

add_dep warden warden-readonly-cutover warden-findings

add_dep provenance provenance-hindsight-corpus provenance-5fu
add_dep provenance provenance-hindsight-corpus provenance-a2g
add_dep provenance provenance-hindsight-corpus provenance-f7d
add_dep provenance provenance-hindsight-corpus provenance-srt

add_dep gauntlet gauntlet-conductor-corpus gauntlet-lj5
add_dep gauntlet gauntlet-conductor-corpus gauntlet-289
add_dep gauntlet gauntlet-conductor-corpus gauntlet-be9

add_dep envoy envoy-conductor-corpus envoy-6p5
add_dep envoy envoy-conductor-corpus envoy-ct9
add_dep envoy envoy-conductor-corpus envoy-4yr

add_dep guildhall guildhall-retire guildhall-y10
add_dep guildhall guildhall-retire guildhall-6mc

if [[ "$MODE" == "--dry-run" ]]; then
  echo "dry run complete: no Beads or dependencies were written"
else
  echo "Bead creation complete. Run bd lint and bd dep cycles in every affected repo before dispatch."
fi
