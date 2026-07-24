# Undertake Core Consolidation Implementation Plan

> **For the fresh orchestration session:** the user selected direct `/loops`
> execution, one claimed Bead at a time, with the fresh Lead session retaining
> queue ownership and final verification. Do not fan out two writers into one
> repo. The implementation workers never mutate Beads.

**Goal:** Replace the Guildhall runtime suite with a focused Undertake loop
kernel, Musterroll roster service, Afterfact evidence/scorecard store, and read-only
Cautionlight filter while preserving the capabilities that have earned their keep.

**Architecture:** Four versioned CLI/file contracts; strict Musterroll roster v2
role capabilities; strict Undertake run/event v2 state; explicit-target runs;
SQLite only as Afterfact's rebuildable index; all model/harness feedback
remains human-gated before Musterroll roster changes. Satellite binaries freeze
parity corpora before becoming shims/history.

**Tech stack:** Rust 2024 CLIs, TOML, JSON/JSONL, SQLite via `rusqlite`, shell
compatibility shims, harness-deck reports, Beads metadata.

**Design:** `.docs/ai/phases/undertake-core-consolidation-spec.md`

**Bead generator:**
`.docs/ai/phases/bd-create-undertake-core-consolidation.sh`

## Global constraints

- Finish and merge the clean active Undertake adversarial-review worktree
  before touching Undertake main.
- Never run two writer loops in the same repo.
- Every Bead retains runnable `tier_floor`, `complexity`, and `verify_cmd`
  metadata; `verify_cmd` is never sourced from notes.
- The fresh orchestrator claims/closes Beads; loop workers never call `bd`.
- Existing P0/P1 correctness work is preserved unless this plan explicitly
  names a replacement.
- Cross-repo gates are prose because Beads cannot encode them; the fresh
  orchestrator enforces the wave table.
- No push and no `chezmoi apply`.
- Compatibility shims receive no new features.

## Deliverable map

| Repo | Files expected to move or appear | Responsibility |
|---|---|---|
| `musterroll` | `roster.toml`, strict v2 role/identity validation and snapshot modules, CLI tests | Operational profile capabilities and availability |
| `undertake` | strict v2 run/event module, role scheduler, job registry, native loop, plan/review assets | Explicit verified job loops |
| `afterfact` | store/migration/ingest modules, observation journal, scorecard and attribution modules | Evidence index, scorecards, provenance |
| `cautionlight` | read-only CLI package plus finding schema/rules | Event-stream advice |
| `provenance` | corrected correlation corpus and compatibility handoff | Attribution parity source |
| `gauntlet` | corrected eval corpus and migration inventory | Plan/review evaluation evidence |
| `envoy` | corrected consult corpus | Consult-job parity source |
| `foreman` | validated skill package and fixture renderer | Skill handoff, no binary |
| `guildhall` | four-tool demo, retirement map, archived charter/history | Migration proof only |
| `chezmoi-personal` | Ralph/skills/scorecard-launcher cutover, targeted apply handoff | Non-Beads operator tail |
| `model-scorecard-state` | legacy import retention and Afterfact observation backup | Non-Beads private-state tail |

## Generated Bead set

The generator declares 26 current definitions and an explicit allowlist of
historical closed IDs. In `--resume` mode it creates only missing definitions,
requires every current definition to be `open`, and compares ID, title,
priority, type, estimate, description, acceptance, notes, and routing metadata
before reconciling dependency edges. Only the named historical IDs may bypass
that active-contract comparison.

### Undertake — eight Beads

| ID | Purpose | tier_floor / complexity | Local blockers |
|---|---|---|---|
| `undertake-run-v2` | Strict `undertake/run@2` and `undertake/event@2`, copied Musterroll v2 snapshot, structural plan state, and `runs-v2/` scanner | lead / XL | existing run/recovery gates; cross: `musterroll-roster-v2-snapshot` |
| `undertake-role-routing` | Generic role/profile policy plus durable smooth-WRR stage reservations | lead / XL | run v2; cross: `musterroll-roster-v2-snapshot` role capabilities |
| `undertake-job-registry` | Closed `work|review|consult|plan` registry | lead / M | run v2 |
| `undertake-loop-kernel` | Native fresh-context, resumable, identity-checked explicit-target loop | lead / L | run v2, jobs, `undertake-1i9`, `vnu`, `9uk`, `cwl`, `wxx` |
| `undertake-adversarial-job` | Preserve N-reviewer plus independent-judge behavior as `review` | senior / M | loop kernel, `vly`, `j84`, `zg9`, `5tg`, `z8z` |
| `undertake-consult-job` | Import Envoy's read-only evidence-or-gaps contract | senior / M | loop kernel; cross: Envoy corpus |
| `undertake-plan-job` | Bounded strict spec/implementation-plan authoring with peer and optional second-opinion gates | lead / XL | loop kernel, run v2, role routing |
| `undertake-plan-review-eval-fold` | Fold corrected Gauntlet evidence into plan/review validation without another runtime | lead / L | plan job, adversarial review; cross: Gauntlet corpus |

### Musterroll — three Beads

| ID | Purpose | tier_floor / complexity | Local blockers |
|---|---|---|---|
| `musterroll-roster-v2-contract` | Strict v2 provider/execution identities and unordered role capabilities | lead / M | none; closed `bursar-roster-contract` is v1 history |
| `musterroll-roster-v2-migrate` | Preserve the immutable v1 identity subset and add exact OMP role-capable profiles | senior / M | `musterroll-roster-v2-contract`; closed `bursar-roster-migrate` is v1 history |
| `musterroll-roster-v2-snapshot` | Strict v2 list/check/snapshot with source, policy, and exact snapshot digests | senior / M | `musterroll-roster-v2-migrate`, `musterroll-trz`; closed `bursar-roster-snapshot` is v1 history |

`musterroll-roster-v2-migrate` must add the following enabled rows and assert each
field directly; the opaque `profile_id` is never a source from which another
field is inferred:

| `profile_id` | exact `ExecutionKey` (`provider_id`, `model`, `harness`, `dispatch_id`, `reasoning_effort`) | tier / ceiling | efficiency / data policy | sorted required roles |
|---|---|---|---|---|
| `openai-codex--omp--gpt-5.6-sol--xhigh` | (`openai-codex`, `gpt-5.6-sol`, `omp`, `openai-codex/gpt-5.6-sol`, `xhigh`) | `lead` / `XL` | `heavy` / `standard` | `advisor`, `default`, `designer`, `plan`, `slow`, `task`, `vision` |
| `anthropic--omp--claude-opus-4-8--max` | (`anthropic`, `claude-opus-4-8`, `omp`, `anthropic/claude-opus-4-8`, `max`) | `lead` / `XL` | `heavy` / `standard` | `advisor`, `default`, `designer`, `plan`, `slow`, `task`, `vision` |
| `opencode-go--omp--kimi-k3--max` | (`opencode-go`, `kimi-k3`, `omp`, `opencode-go/kimi-k3`, `max`) | `lead` / `XL` | `heavy` / `standard` | `advisor`, `default`, `designer`, `plan`, `slow`, `task`, `vision` |

### Afterfact — eight Beads

| ID | Purpose | tier_floor / complexity | Local blockers |
|---|---|---|---|
| `afterfact-store` | Rebuildable SQLite store, migrations, integrity/rebuild commands | lead / L | none |
| `afterfact-ingest` | Incremental, idempotent ingestion with per-file cursors and isolated gaps | senior / L | store, `d96`, `byi`, `6h8`, `976` |
| `afterfact-event-v2` | Versioned event envelope with raw artifact path/hash and gap output | lead / M | ingest, `3kn`, `vxd` |
| `afterfact-undertake-runs-v2` | Ingest strict Undertake v2 manifests/events into run, stage, and attempt rows | senior / M | store + ingest; cross: `undertake-run-v2`; closed `hindsight-conductor-runs` is v1 history |
| `afterfact-observations` | Append-only observation journal plus legacy scorecard/bench import | senior / L | store + ingest |
| `afterfact-scorecards` | Model, harness, profile, and job-stratified evidence views | lead / L | `afterfact-undertake-runs-v2` + observations |
| `afterfact-scorecard-publish` | Harness-deck publishing and evidence-pinned roster recommendations | senior / M | scorecards |
| `afterfact-attribution` | Fold corrected Provenance correlation/query/store into Afterfact | lead / L | event v2, `pov`, `w5w`; cross: Provenance corpus |

### Cautionlight — two Beads

| ID | Purpose | tier_floor / complexity | Local blockers |
|---|---|---|---|
| `cautionlight-findings` | Stateless `afterfact/event@2` consumer and `cautionlight/finding@1` emitter | lead / M | cross: Afterfact event v2 |
| `cautionlight-readonly-cutover` | Make batch advice the supported CLI; deprecate uninstalled hook enforcement | senior / S | Cautionlight findings |

### Capability handoffs — four Beads

| Repo / ID | Purpose | tier_floor / complexity | Blockers |
|---|---|---|---|
| `provenance-afterfact-corpus` | Correct and freeze correlation/query parity corpus | lead / M | `5fu`, `a2g`, `f7d`, `srt` |
| `gauntlet-undertake-corpus` | Correct and freeze golden/eval parity corpus and migration inventory | lead / M | `lj5`, `289`, `be9` |
| `envoy-undertake-corpus` | Correct and freeze consult envelope/prompt corpus | senior / S | `6p5`, `ct9`, `4yr` |
| `foreman-skill` | Produce a validated skill and reviewable Bead-script renderer | lead / M | existing binary Beads stay deferred |

### Guildhall — one Bead

| ID | Purpose | tier_floor / complexity | Blockers |
|---|---|---|---|
| `guildhall-retire` | Four-tool no-spend smoke, final ownership map, archive handoff | lead / M | `guildhall-y10`, `guildhall-6mc`; every cross-repo cutover gate |

## Existing-Bead disposition

The fresh Lead session performs these queue edits only after the replacement
Beads are created and after verifying there is no active writer for the
affected repo.

### Finish or preserve

- Undertake: finish active `undertake-vly` and `undertake-j84`; preserve
  `undertake-1i9`, `vnu`, `9uk`, `cwl`, `wxx`, `zg9`, `5tg`, `z8z`, `ldz`,
  `0ma`, `1br`, and `eua` because their correctness properties survive.
- Musterroll: finish `musterroll-trz`; `musterroll-ejf` remains a useful independent
  provider-detector improvement but is not a consolidation blocker.
- Afterfact: finish `d96`, `3kn`, `byi`, `6h8`, `976`, `vxd`, `pov`, and
  `w5w` before their source/behavior is admitted to the store.
- Provenance: finish `5fu`, `a2g`, `f7d`, and `srt` before freezing the corpus.
- Gauntlet: finish `lj5`, `289`, and `be9` before freezing the corpus.
- Envoy: finish `6p5`, `ct9`, and `4yr` before freezing the corpus.
- Guildhall: retain `y10` as the event-envelope gate and `6mc` as the live-seam
  definition-of-done gate.

- Closed `conductor-run-contract` and `conductor-bursar-roster` remain immutable
  historical evidence. `undertake-run-v2` is the canonical strict consumer and
  run/state replacement; no v1 compatibility parser is added.
- Closed `bursar-roster-contract`, `bursar-roster-migrate`, and
  `bursar-roster-snapshot` retain their original v1 descriptions, acceptance,
  close reasons, and review evidence. The new `musterroll-roster-v2-*` chain is the
  only executable v2 prerequisite, ending at `musterroll-roster-v2-snapshot`.
- Closed `hindsight-conductor-runs` retains its original v1 ingestion contract
  and findings. `afterfact-undertake-runs-v2` is the only active strict-v2
  ingestion item, and downstream scorecards depend on it.

### Replace; do not execute separately

- Undertake roster TUI: `pp0`, `68z`, `c4x` → Musterroll roster contract/migration/snapshot.
- Undertake provider/roster router: `d5j`, `r6p`, `xm9`, `3u3`, and `o5k` →
  strict run v2 plus role routing and Musterroll v2 list/check.
- Supersede open `conductor-arena-loop` with `undertake-plan-job`.
- Supersede open `conductor-eval-fold` with
  `undertake-plan-review-eval-fold`.
- Afterfact `3fl` full-scan optimization → `afterfact-ingest`.
- Afterfact `n79` kind filter → `afterfact-event-v2`.
- Provenance `y7f` exit/coverage semantics → `afterfact-attribution`.
- Gauntlet `goy` and `5ci` cost-stream work → Afterfact scorecards/ingest.
- Cautionlight `4ke`, `wyd`, `gqw`, `a3x`, `zxj`, `xpf`, `ffv`, `qsd`, `rkw`,
  and deferred `44n` target hook/enforcement behavior and do not enter the
  read-only batch product.

### Retire as goals

- `undertake-jx2`, `undertake-ilv`, and deferred `undertake-m5`: no unattended
  ratchet/cutover or automatic triage-backfill goal in the focused product.
- Foreman `m0`, `m1`, `prompt`, `m2`, `m3`, `m4`: keep deferred until
  `foreman-skill` validates and is installed; then close as replaced.
- Defer `undertake-2d4` native Codex app-server work until the generic native
  loop kernel proves stable. It is an optimization, not a foundation.

Use `bd close <id> --reason "replaced by <new-id> per undertake-core-consolidation-spec"`
for cross-repo replacements because Beads cannot encode cross-database
dependencies. Use `bd supersede <old> --with=<new>` for same-repo replacements,
including the two Undertake replacements above.

## Execution waves

### Task 0: Recover and freeze the starting point

- [x] Read this plan, the spec, every affected repo's `current-state.md`, and
      run `bd prime` after any context clear.
- [x] Verify all repo statuses and `git worktree list`; do not touch unrelated
      dirty chezmoi work.
- [x] Finish and merge the Undertake adversarial worktree through `vly` and
      `j84`; run its full test/clippy gate.
- [x] Run the generator in `--resume` for this applied program; inspect all 26
      current definitions, listed historical IDs, and dependencies.
- [x] Reconcile the active job-registry/BNC contracts, create the four
      Undertake v2/role/plan Beads plus the new Musterroll/Afterfact v2 Beads,
      supersede the two open legacy comparison Beads, and update dependency
      edges before implementation.
- [x] Run focused `bd lint`, `bd dep cycles`, and `bd preflight` checks for
      touched queues.

Verify a fresh empty set:

```bash
bash -n .docs/ai/phases/bd-create-undertake-core-consolidation.sh
.docs/ai/phases/bd-create-undertake-core-consolidation.sh --dry-run
```

Verify this repository's already-applied durable queues:

```bash
bash .docs/ai/phases/test-bd-create-undertake-core-consolidation.sh
GUILDHALL_GIT_ROOT=/Users/tfinklea/git \
  .docs/ai/phases/bd-create-undertake-core-consolidation.sh --resume
```

### Task 1: Close correctness prerequisites

- [ ] Work the preserved P0/P1 Beads repo by repo.
- [ ] For each selected Bead, the fresh orchestrator claims it, expands that
      one Bead into the repo's `current-state.md` Plan, launches `/loops`,
      verifies the resulting commit, then closes the Bead.
- [ ] Do not start a migration corpus until all of its named correctness
      blockers are closed.

Verify: each Bead's metadata `verify_cmd`, plus `cargo test` for the affected
Rust repo when the narrower command does not cover the integration seam.

### Task 2: Establish Musterroll and Afterfact foundations

- [ ] Execute `musterroll-roster-v2-contract` → `musterroll-roster-v2-migrate` →
      `musterroll-roster-v2-snapshot`.
- [ ] Execute Afterfact store → ingestion → event v2 foundations; preserve
      their closed evidence while strict Undertake ingestion remains the new
      `afterfact-undertake-runs-v2` work.
- [ ] Close `guildhall-y10` only after v2 producer and compatibility consumers
      reject unknown schemas and verify artifact identity.

Verify:

```bash
cargo test --manifest-path /Users/tfinklea/git/musterroll/Cargo.toml
cargo test --manifest-path /Users/tfinklea/git/afterfact/Cargo.toml
```

### Task 3: Build the focused Undertake kernel

- [ ] Execute strict run v2 → role routing and job registry → loop kernel.
- [ ] Do not start `undertake-run-v2`, `undertake-role-routing`, or the bounded
      plan job until the exact cross-repo terminal gate
      `musterroll-roster-v2-snapshot` is closed with v2 verification evidence.
- [ ] Prove interruption/resume, unrelated-commit rejection, exclusive repo
      lease, bounded failure continuation, and verifier-gated success in a
      sandbox repo.
- [ ] Keep legacy `scan`/`cycle` functional but add no new product behavior to it.

Verify:

```bash
cargo test --manifest-path /Users/tfinklea/git/undertake/Cargo.toml
cargo clippy --manifest-path /Users/tfinklea/git/undertake/Cargo.toml --all-targets -- -D warnings
```

### Task 4: Move evidence and scorecards into Afterfact

- [ ] Execute `afterfact-undertake-runs-v2` after `undertake-run-v2`; never use
      the closed v1 `hindsight-conductor-runs` close proof as this gate.
- [ ] Add canonical observations and import legacy model-bench/Experience Log.
- [ ] Build model/harness/profile/job views and publish both scorecard reports.
- [ ] Validate rebuild parity from canonical inputs before turning off the old
      Node generator or Undertake ledger dual-write.
- [ ] Update the private state-backup workflow to back up the Afterfact
      observation journal; keep legacy files until parity is signed off.

Verify: Afterfact Bead commands plus `hdeck validate` on both generated reports.

### Task 5: Fold earned capabilities

- [ ] Freeze Provenance, Gauntlet, and Envoy corpora.
- [ ] Execute Afterfact attribution, Undertake review/consult/plan, the
      plan/review evaluation fold, and Cautionlight findings/cutover Beads in
      dependency order.
- [ ] Validate each new surface against the old corrected corpus before adding
      a warning shim.
- [ ] Build and validate the Foreman skill; only then retire the deferred binary plan.

Verify: every corpus and destination Bead command; no source repo archives yet.

### Task 6: Dotfile and compatibility cutover

This is the deliberate non-Beads tail because `chezmoi-personal` is the repo's
documented Beads exception and currently has unrelated dirty work.

- [ ] Add one self-contained `.docs/ai/roadmap.md` item in `chezmoi-personal`
      covering: Ralph shim to Undertake; `/loops`; `dispatch-to-pi`; native
      `plan` and surviving `review` routing; retire obsolete comparison skills;
      install Foreman skill; remove scorecard seed/bench-create ownership; and
      replace the Node digest LaunchAgent target with
      `afterfact scorecard publish`.
- [ ] Edit managed sources only; perform path-targeted apply only when the user
      chooses, after a chezmoi reconciliation pass.
- [ ] Update `model-scorecard-state` sync/restore scripts to preserve the
      canonical Afterfact observation journal and retain legacy files as a
      migration snapshot. Do not version the SQLite database.

Verify: repo-specific tests, `chezmoi diff` on exact targets, and no live apply
inside headless loops.

### Task 7: Prove and retire

- [ ] Run the four-tool no-metered vertical slice.
- [ ] Verify the eleven cutover gates in the spec.
- [ ] Execute `guildhall-retire`: update README/demo/roadmap, point to the four
      owners, preserve ADR/spec history, and prepare archive handoff.
- [ ] Remove compatibility shims only after at least one real project has run
      each new job successfully; otherwise leave them warning-only.

Verify:

```bash
bash demo/run.sh --build
bash demo/run.sh all
```

## Fresh-session loop protocol

For each implementation Bead:

1. `bd ready` and `bd show <id>` in the target repo.
2. Confirm the current model tier meets `tier_floor`.
3. `bd update <id> --claim` from the fresh orchestrator.
4. Expand only that Bead into the repo's `.docs/ai/current-state.md` Plan with
   one runnable Verify per phase.
5. Launch `/loops` or Ralph for that repo. The worker never runs `bd`.
6. Inspect commit identity and diff, run the Bead Verify plus the integration
   gate required by its wave.
7. `bd close <id> --reason "..."`; update handoff docs and commit once.
8. Clear context before the next independent Bead.

Stop rather than widening scope when a cross-repo gate is not ready. The
fresh session owns the dependency graph; no binary silently skips it.
