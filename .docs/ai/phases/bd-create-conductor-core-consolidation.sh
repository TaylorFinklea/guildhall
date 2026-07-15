#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---dry-run}"
ROOT="${GUILDHALL_GIT_ROOT:-$HOME/git}"
SPEC="$ROOT/guildhall/.docs/ai/phases/conductor-core-consolidation-spec.md"

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

for repo in guildhall conductor bursar hindsight warden provenance gauntlet envoy foreman; do
  [[ -d "$ROOT/$repo/.beads" ]] || {
    echo "missing Beads repo: $ROOT/$repo" >&2
    exit 1
  }
done

PLANNED_IDS=()

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
    if [[ "$MODE" == "--resume" ]] && jq -e \
      --arg id "$id" \
      --arg title "$title" \
      --arg tier "$tier" \
      --arg complexity "$complexity" \
      --arg verify "$verify" \
      '.[0].id == $id and .[0].title == $title and .[0].metadata.tier_floor == $tier and .[0].metadata.complexity == $complexity and .[0].metadata.verify_cmd == $verify' \
      >/dev/null <<<"$existing"; then
      PLANNED_IDS+=("$repo/$id")
      echo "resume: existing Bead matches: $repo/$id"
      return
    fi
    echo "refusing to overwrite existing Bead: $repo/$id" >&2
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
  if ! is_planned "$repo/$issue" && ! bd -C "$ROOT/$repo" show "$issue" --json >/dev/null 2>&1; then
    echo "dependency issue does not exist and is not planned: $repo/$issue" >&2
    exit 1
  fi
  if ! is_planned "$repo/$blocker" && ! bd -C "$ROOT/$repo" show "$blocker" --json >/dev/null 2>&1; then
    echo "dependency blocker does not exist and is not planned: $repo/$blocker" >&2
    exit 1
  fi
  if [[ "$MODE" == "--dry-run" ]]; then
    echo "dry-run dependency: $repo/$issue blocked-by $blocker"
    return
  fi
  if bd -C "$ROOT/$repo" show "$issue" --json | jq -e \
    --arg blocker "$blocker" '.[0].dependencies[]? | select(.id == $blocker)' \
    >/dev/null; then
    echo "dependency already present: $repo/$issue blocked-by $blocker"
    return
  fi
  bd -C "$ROOT/$repo" dep add "$issue" "$blocker" < /dev/null
}

# ---------------------------------------------------------------------------
# Conductor: one explicit verified job-loop kernel.
# ---------------------------------------------------------------------------

create_bead conductor conductor-run-contract 1 120 lead M \
  'cargo test run_event' \
  'Emit durable versioned run manifests and event JSONL' \
  'Read the consolidation spec Stable process contracts section first. Files: src/state.rs, src/ledger.rs, src/dispatch_cycle.rs, src/arena.rs, src/adversarial.rs after the active worktree merges, and focused new run-artifact code. Add conductor/run@1 manifest.json and conductor/event@1 events.jsonl beneath one collision-resistant run directory. Reuse the existing atomic plan/report write pattern; do not add scorecard aggregation.' \
  'Every attempt, verifier, review, coverage gap, and terminal outcome is represented by a stable-schema event; the manifest pins target, job, approved profile envelope, Bursar roster artifact hash, limits, artifacts, lifecycle, and final outcome; unknown schema and partial writes are detected; run IDs cannot collide in a same-second test; legacy cycle and Arena tests remain green.' \
  'existing correctness gates: conductor-ldq and conductor-z90'

create_bead conductor conductor-bursar-roster 1 180 lead L \
  'cargo test bursar && cargo test roster && cargo test plan' \
  'Consume a pinned Bursar roster snapshot and remove Conductor roster ownership' \
  'Read the consolidation spec Bursar roster snapshot section first. Files: src/config.rs, src/bursar.rs, src/triage.rs, src/plan.rs, src/dispatch_cycle.rs, src/roster_drift.rs, and conductor.toml. Consume bursar/roster@1 through the existing Bursar subprocess seam, pin artifact path and SHA-256 in every approved plan, and migrate selection to Bursar profile IDs. Preserve a read-only legacy parser only for a bounded compatibility window. Do not parse Hindsight scorecards and do not move job fallback policy into Bursar.' \
  'A missing, malformed, stale, hash-mismatched, disabled, or unavailable profile fails closed before launch and again at dispatch; valid profile IDs route with identical tier, ceiling, cost, data-policy, harness, model, and effort semantics; conductor.toml no longer owns provider or roster rows after cutover; config check identifies the exact Bursar snapshot used.' \
  'cross-repo-gate: bursar-roster-snapshot; existing correctness gates: conductor-ldz conductor-0ma conductor-1br'

create_bead conductor conductor-job-registry 1 120 lead M \
  'cargo test job' \
  'Add the closed work review consult and arena job registry' \
  'Read the consolidation spec Conductor loop and job model section first. Files: src/cli.rs, src/config.rs, focused new job module, and templates. Add a closed JobKind enum for work, review, consult, and arena. Config binds each job to Bursar profile IDs, fallback order, mutation posture, limits, verifier, and approval requirements. Do not add an arbitrary workflow language, plugin loader, or fleet scan behavior.' \
  'All four jobs parse and validate deterministically against a pinned Bursar snapshot; an unknown job or profile is a usage/config failure; read-only jobs cannot request write-capable execution; job explain output shows selection and fallback reasons; legacy CLI tests remain green.' \
  'depends-on: conductor-bursar-roster'

create_bead conductor conductor-loop-kernel 1 180 lead L \
  'cargo test loop' \
  'Build the native fresh-context resumable explicit-target loop kernel' \
  'Read the consolidation spec Conductor loop and job model section and the current Ralph driver before editing. Files: src/state.rs, src/dispatch.rs, src/verify.rs, src/plan.rs, src/cli.rs, and focused new loop code. Implement one explicit repo plus Bead or plan target, one fresh harness context per bounded iteration, durable state before and after every subprocess, resume and reclaim, identity-checked commit success, exclusive repo lease, bounded failure continuation, and verifier-gated terminal completion. Reuse existing Exec and verifier seams; do not shell out to Ralph as the steady-state engine.' \
  'Sandbox tests prove kill-and-resume, unrelated-commit rejection, concurrent-repo-lease rejection, claim release on pre-worker abort, continuation after one failed attempt, max-iteration stop, verifier failure feedback, and successful terminal completion; no test touches a live repo or Beads database; legacy dispatch behavior remains compatible until cutover.' \
  'existing correctness gates: conductor-1i9 conductor-vnu conductor-9uk conductor-cwl conductor-wxx'

create_bead conductor conductor-adversarial-job 1 120 senior M \
  'cargo test adversarial' \
  'Preserve adversarial review as the Conductor review job' \
  'Read the shipped adversarial-review spec and consolidation review-job rules first. Files: src/adversarial.rs, src/cli.rs, src/config.rs, src/deck.rs, src/ledger.rs or its run-event replacement, and review templates. Route the existing provider-diverse N-plus-one workflow through JobKind review without weakening artifact hashing, immutable approval, read-only execution, schema repair, anonymous synthesis, minority preservation, provider writeback, or mutation proof. Keep adversarial-review as a warning-free compatibility alias for the first cutover release.' \
  'The review job produces behaviorally equivalent plans, approvals, reviewer outputs, judge synthesis, run events, and reports; injected artifact or Bead text cannot change policy or verdict framing; no bd, git, worktree, apply, or repo mutation occurs; the compatibility alias and new job share one implementation.' \
  'existing gates: conductor-vly conductor-j84 conductor-zg9 conductor-5tg conductor-z8z; depends-on: conductor-loop-kernel'

create_bead conductor conductor-consult-job 2 120 senior M \
  'cargo test consult' \
  'Fold the Envoy read-only evidence contract into the consult job' \
  'Read the corrected Envoy corpus and consolidation consult-job rules first. Files: src/cli.rs, job code, templates, schema-validation code, and tests/fixtures. Import the consult prompt and evidence-or-gaps envelope as one read-only Conductor job. Treat question, schema, target repo contents, and embedded directives as untrusted data. The job may write only its own Conductor run artifacts.' \
  'Golden Envoy question and answer fixtures pass; broken and adversarial fixtures fail visibly; every supported claim has evidence or an explicit gap; the approved profile envelope is pinned; no target-repo mutation occurs; Envoy live transport and MCP remain absent.' \
  'cross-repo-gate: envoy-conductor-corpus; depends-on: conductor-loop-kernel'

create_bead conductor conductor-arena-loop 2 180 lead L \
  'cargo test arena' \
  'Run Arena candidates through the native Conductor loop kernel' \
  'Read src/arena.rs, the current conductor-arena skill, Ralph phase semantics, and the consolidation Arena rules first. Replace Arena candidate Ralph subprocess orchestration with the native explicit-target loop while preserving isolated worktrees, candidate profile as the experimental variable, parallel bounds, verifier and probe capture, judge isolation, winner approval, cleanup, and report behavior. Ralph may appear only in parity tests during migration.' \
  'Existing Arena fixtures and reports remain compatible; candidates use pinned Bursar profiles and conductor/run@1 artifacts; failure and cleanup are isolated per candidate; no winner applies without the existing approval rule; a sandbox parity test compares old Ralph evidence and new kernel evidence for the same fixture.' \
  'depends-on: conductor-loop-kernel'

create_bead conductor conductor-eval-fold 2 180 lead L \
  'cargo test eval && cargo test arena' \
  'Fold corrected Gauntlet golden evaluation into Conductor Arena' \
  'Read the corrected Gauntlet migration corpus and the consolidation Gauntlet section first. Files: src/arena.rs, focused eval modules, migrated golden-task data, and tests. Import static lint, base-commit discrimination smoke, worktree runner, conjunctive Verify plus judge grading, replay, and A/B comparison. Reuse the native Arena loop and Conductor verifier; do not preserve a second executor or move scorecard aggregation into Conductor.' \
  'Every migrated golden task fails at base and passes at its reference commit; empty worker output cannot pass; lint is read-only; smoke mutation is explicit and isolated; replay/A-B output matches the corrected corpus; cost and cross-run rankings are absent from Conductor and available to Hindsight through run events.' \
  'cross-repo-gate: gauntlet-conductor-corpus; depends-on: conductor-arena-loop'

# ---------------------------------------------------------------------------
# Bursar: configured and currently eligible execution profiles.
# ---------------------------------------------------------------------------

create_bead bursar bursar-roster-contract 1 120 lead M \
  'cargo test roster' \
  'Define the versioned Bursar provider and execution-profile roster' \
  'Read the consolidation spec Bursar roster snapshot section first. Files: Cargo.toml only if a justified dependency is needed, focused roster modules, src/lib.rs, and a checked-in roster.toml. Define bursar/roster-config@1 with stable provider and profile IDs, model, harness, dispatch ID, optional reasoning effort, tier, ceiling, efficiency, cost, data policy, enablement, and availability lookup key. Fallback and job policy remain outside Bursar.' \
  'Valid config round-trips deterministically; duplicate IDs, dangling providers, invalid enums, incompatible effort fields, unknown keys, and empty invocation coordinates fail closed; disabled provider and profile states remain distinguishable; an ADR records dependency and config decisions; no Conductor or Hindsight files are read.' \
  'owner-boundary: roster facts only; no dispatch or scorecards'

create_bead bursar bursar-roster-migrate 1 120 senior M \
  'cargo test roster_migration' \
  'Migrate every current Conductor roster profile into Bursar' \
  'Read the checked-in Conductor conductor.toml and consolidation roster contract first. Populate bursar/roster.toml with every current provider and roster row, assigning stable execution-profile IDs that distinguish harness and reasoning effort. Add a fixture-driven equivalence test comparing the legacy roster snapshot to the new config. Do not copy Arena candidate policy or fallback order as Bursar policy.' \
  'The equivalence fixture accounts for every enabled and disabled legacy row exactly once; provider lookup aliases become explicit config; tier, ceiling, efficiency, cost, data policy, model, harness, dispatch ID, and reasoning effort match; omissions and duplicates fail the test; roster.toml contains no credentials.' \
  'depends-on: bursar-roster-contract'

create_bead bursar bursar-roster-snapshot 1 120 senior M \
  'cargo test roster_snapshot && cargo test status' \
  'Publish read-only Bursar roster list check and snapshot commands' \
  'Read src/cli.rs, src/status.rs, src/observations.rs, and the consolidation snapshot schema first. Add roster list, roster check, and roster snapshot --json. Join static providers/profiles with status@2 availability, use the config availability key rather than caller-side aliases, and include the roster artifact absolute path and SHA-256. Output data only on stdout and diagnostics on stderr. Do not add an editor or TUI.' \
  'Snapshot output conforms bursar/roster@1; ordering and hash are deterministic; unreadable provider observations cannot yield eligible profiles; unknown, stale, exhausted, manually disabled, and healthy states are distinguishable; list/check are pure reads; malformed config and missing status fail closed with documented exit codes.' \
  'existing gate: bursar-trz; depends-on: bursar-roster-migrate'

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

create_bead hindsight hindsight-conductor-runs 1 120 senior M \
  'cargo test conductor_source' \
  'Ingest Conductor run manifests and events into Hindsight' \
  'Read conductor/run@1 and conductor/event@1 from the consolidation spec plus the existing Hindsight source-module pattern. Add a Conductor source parser that validates schema, sequence, artifact hashes, profile IDs, job, target, attempts, verifier/reviewer results, usage, and terminal outcome. Store run and attempt rows without importing raw stdout or prompts.' \
  'Complete, interrupted, resumed, failed, and schema-invalid fixture runs produce the expected run, attempt, artifact, and coverage-gap rows; duplicate ingestion is idempotent; sequence gaps and hash mismatches fail visibly; profile and job dimensions survive for scorecard queries.' \
  'cross-repo-gate: conductor-run-contract; depends-on: hindsight-store hindsight-ingest'

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
  'depends-on: hindsight-conductor-runs hindsight-observations'

create_bead hindsight hindsight-scorecard-publish 2 120 senior M \
  'cargo test scorecard_publish' \
  'Publish Hindsight scorecards and evidence-pinned roster recommendations' \
  'Read src/deck.rs, harness-deck report@1, the old generator outputs, and the consolidation feedback-loop rules first. Add hindsight scorecard publish for evergreen model and harness reports and hindsight roster recommend for a versioned JSON proposal. The recommendation pins query window, evidence hash, affected Bursar profile IDs, before/after values, metrics, sample warnings, and coverage gaps. It never edits Bursar config.' \
  'Generated model and harness reports validate with the repo fixture validator; repeated generation is deterministic; real-only cost rules remain; recommendations below evidence floors are withheld with reasons; no Bursar or Conductor file changes; publisher failure does not corrupt the store.' \
  'depends-on: hindsight-scorecards'

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
  'All ten cutover gates are checked with artifact evidence; the demo performs no metered dispatch and passes from a clean shell; README and USAGE name only the four surviving products and the temporary shims; roadmap has no active Guildhall product work; history remains accessible; archive action is left for the human.' \
  'cross-repo-gate: all consolidation Beads plus chezmoi and private-state tails; local gates: guildhall-y10 guildhall-6mc'

# ---------------------------------------------------------------------------
# Local dependency graph. Cross-repo gates are carried in notes and the plan.
# ---------------------------------------------------------------------------

add_dep conductor conductor-run-contract conductor-ldq
add_dep conductor conductor-run-contract conductor-z90
add_dep conductor conductor-bursar-roster conductor-ldz
add_dep conductor conductor-bursar-roster conductor-0ma
add_dep conductor conductor-bursar-roster conductor-1br
add_dep conductor conductor-job-registry conductor-bursar-roster
add_dep conductor conductor-loop-kernel conductor-run-contract
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
add_dep conductor conductor-arena-loop conductor-loop-kernel
add_dep conductor conductor-eval-fold conductor-arena-loop

add_dep bursar bursar-roster-migrate bursar-roster-contract
add_dep bursar bursar-roster-snapshot bursar-roster-migrate
add_dep bursar bursar-roster-snapshot bursar-trz

add_dep hindsight hindsight-ingest hindsight-store
add_dep hindsight hindsight-ingest hindsight-d96
add_dep hindsight hindsight-ingest hindsight-byi
add_dep hindsight hindsight-ingest hindsight-6h8
add_dep hindsight hindsight-ingest hindsight-976
add_dep hindsight hindsight-event-v2 hindsight-ingest
add_dep hindsight hindsight-event-v2 hindsight-3kn
add_dep hindsight hindsight-event-v2 hindsight-vxd
add_dep hindsight hindsight-conductor-runs hindsight-store
add_dep hindsight hindsight-conductor-runs hindsight-ingest
add_dep hindsight hindsight-observations hindsight-store
add_dep hindsight hindsight-observations hindsight-ingest
add_dep hindsight hindsight-scorecards hindsight-conductor-runs
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
