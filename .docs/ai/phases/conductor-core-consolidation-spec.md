# Conductor core consolidation — approved architecture

**Status**: direction approved by the user 2026-07-14. This spec replaces the
Guildhall-as-product model after the current correctness gates land. The tracked
Bead generator and execution plan beside this file are the implementation handoff.

## Mission

Reduce the suite to one explicit execution kernel and three small cooperating
tools:

- **Conductor** runs an explicitly selected, verified job loop.
- **Bursar** answers which execution profiles exist and whether they are usable.
- **Hindsight** records and indexes evidence, attributes work, and derives model
  and harness scorecards.
- **Warden** reads Hindsight events and emits advisory findings.

Provenance, Gauntlet, Envoy, and Foreman contribute their proven capability to
those four surfaces and then stop being standalone binaries. Guildhall remains
only as the migration/history repository until the cutover is proven, then is
archived. The design follows a Unix boundary: versioned files and JSONL on
stdout, diagnostics on stderr, no shared daemon, no hidden control plane, and no
tool silently editing another tool's state.

## Locked decisions

| Decision | Locked value |
|---|---|
| Conductor's one job | Run one explicit target under one named job until a verifier-backed terminal state. |
| Fleet discovery | Not core. `scan`/`cycle` remain compatibility surfaces during migration; new runs require an explicit repo plus Bead, plan, or artifact. |
| Loop engine | Native Conductor state machine. Ralph becomes a temporary compatibility shim only after parity; Conductor does not wrap Ralph as a second state machine. |
| Jobs in the first release | Closed set: `work`, `review`, `consult`, `arena`. Configuration binds these jobs to Bursar profile IDs and limits; no general workflow DSL. |
| Adversarial review | Survives intact and becomes the `review` job. The existing `adversarial-review` command remains a compatibility alias during cutover. |
| Roster owner | Bursar owns providers and execution profiles, including approved tier, ceiling, cost, data policy, enablement, and invocation coordinates. |
| Routing policy | Conductor owns job selection, fallback order, stopping rules, verification, and approval. Bursar never dispatches or chooses a job. |
| Scorecard owner | Hindsight owns empirical model, harness, execution-profile, and job/profile scorecards. Bursar stores only the human-approved operational roster. |
| Feedback loop | Hindsight may emit an evidence-pinned roster recommendation. It never writes Bursar config. Human approval is mandatory. |
| Hindsight database | SQLite is a disposable materialized index. Raw harness artifacts, Git, Conductor run artifacts, and Hindsight's append-only observation journal are canonical. |
| Provenance | Correlation, attribution, and unreviewed-change queries move into Hindsight after the existing false-attribution defects are corrected and frozen as a parity corpus. |
| Gauntlet | Golden tasks, discrimination, replay, and judging move into Conductor Arena/eval. Cost and scorecard aggregation move to Hindsight. |
| Envoy | Its read-only evidence envelope and prompt become Conductor's `consult` job. |
| Foreman | Becomes a concise skill that creates a spec and reviewable Bead script; the planned Rust binary is retired. |
| Warden | Read-only and advisory. It consumes Hindsight's event stream and emits findings; it does not install a blocking hook, mutate repos, or write Hindsight state. |
| Guildhall | No runtime umbrella, broker, or ninth tool. Archive after the four-tool vertical slice and compatibility cutover pass. |

## Why this is not another abstraction layer

Each surviving process has one independently useful question:

| Tool | Question | Owns | Explicitly does not own |
|---|---|---|---|
| Conductor | How do I run this explicit job safely to completion? | Loop state, job policy, approval, verification, run artifacts | Roster facts, performance history, global fleet discovery |
| Bursar | Which execution profiles are configured and currently eligible? | Versioned roster config, provider/profile availability | Job choice, fallback policy, scorecards, dispatch |
| Hindsight | What happened, who did it, and how did each execution profile perform? | Canonical observation journal, derived index, attribution, scorecards | Execution, provider enablement, roster mutation |
| Warden | What suspicious or policy-relevant patterns appear in this event stream? | Stateless rules and finding records | Enforcement, hooks, storage, execution |

If a proposed feature cannot be answered by one of those questions, it does
not enter this program. There is no generic plugin framework, broker, scheduler,
workflow language, or shared service.

## System shape

```mermaid
flowchart LR
    Human["Human or fresh orchestrator"] -->|explicit target + job| C["Conductor\nverified loop kernel"]
    B["Bursar\nroster + availability"] -->|bursar/roster@1 snapshot| C
    C -->|conductor/run@1 + conductor/event@1| Raw["Durable run artifacts"]
    Logs["Harness logs + Git + legacy ledgers"] --> H["Hindsight\nSQLite derived index"]
    Raw --> H
    Obs["Append-only human observations"] --> H
    H -->|hindsight/event@2 JSONL| W["Warden\nread-only findings"]
    H -->|scorecards + evidence-pinned proposal| Human
    Human -->|approved edit| B
    W -->|warden/finding@1 JSONL| Human
```

The only feedback path passes through the human. No scorecard can promote a
model or enable a provider by itself.

## Stable process contracts

All machine output uses one JSON object per line or one atomic JSON artifact.
Every schema is versioned. Unknown schema families or versions fail visibly.
Diagnostics never share stdout with data.

### Bursar roster snapshot

The canonical version-controlled roster moves from
`conductor/conductor.toml` to `bursar/roster.toml`. Static config uses
`bursar/roster-config@1`; the read-only snapshot command emits
`bursar/roster@1`.

An execution profile is the operational unit. It binds a model to the harness,
provider, invocation ID, and reasoning effort that actually run it. Profile IDs
are opaque, stable, and unique; changing a model/harness/effort combination
creates a new profile rather than rewriting historical identity.

Required profile fields:

- `profile_id`, `provider_id`, `model`, `harness`, `dispatch_id`
- optional `reasoning_effort`
- approved `tier`, `ceiling`, `efficiency`, `cost`, and `data_policy`
- `enabled`

Provider records carry `provider_id`, the Bursar availability lookup key, and
manual enablement. This removes Conductor's current hard-coded provider-name
rewrite. Fallback chains do **not** belong in Bursar; they are job policy.

`bursar roster snapshot --config <path> --json` emits:

```json
{
  "schema": "bursar/roster@1",
  "generated_at": "RFC3339",
  "artifact": {"path": "/absolute/path/roster.toml", "sha256": "64-hex"},
  "providers": [],
  "profiles": []
}
```

Each provider/profile entry includes resolved enablement and current
availability with evidence timestamps. Missing config, invalid profile
references, unknown/stale availability, or an unreadable observation ledger
cannot become eligible. Bursar offers `check`, `list`, and `snapshot`. After
those read-only surfaces shipped, explicit operator demand established the case
for an optional Bursar-owned roster and availability TUI (`bursar-vsv`). It is
human-confirmed, uses the same validation and append-only observation paths,
and never applies a Hindsight recommendation automatically. Conductor still
does not own roster editing.

### Conductor run artifacts

Every invocation creates:

```text
~/.local/state/conductor/runs/<run-id>/
  manifest.json       # conductor/run@1, atomic replacement
  events.jsonl        # conductor/event@1, append-only
  approval.json       # immutable approved envelope when required
  attempts/           # stdout, stderr, verifier, and reviewer artifacts
  artifacts/          # prompt/spec snapshots and hashes
```

Run IDs are collision-resistant, not second-granular. `manifest.json` pins the
target, job, Bursar roster artifact hash, approved profiles/fallback envelope,
limits, verifier, lifecycle state, and final outcome. Every event carries at
least:

```json
{
  "schema": "conductor/event@1",
  "event_id": "stable-id",
  "run_id": "run-id",
  "seq": 1,
  "ts": "RFC3339",
  "kind": "run_started|attempt_started|attempt_finished|verify_finished|review_finished|run_finished|coverage_gap",
  "job": "work|review|consult|arena",
  "profile_id": "optional-profile-id",
  "target": {"repo": "/absolute/path", "bead": "optional-id"},
  "artifact_refs": [{"path": "/absolute/path", "sha256": "64-hex"}],
  "outcome": "optional-stable-outcome"
}
```

Conductor emits evidence, not scorecards. During migration it may continue the
legacy `model-bench.jsonl` write for compatibility, but `conductor/event@1` is
the cutover source and dual-write ends once Hindsight parity is proven.

### Hindsight event stream

`hindsight events` advances from the current bare event to
`hindsight/event@2`. Each line contains the normalized event plus the schema
and the canonical source artifact identity required by the existing Guildhall
stdout-layer ADR:

```json
{
  "schema": "hindsight/event@2",
  "event_id": "stable-content-id",
  "event": {},
  "artifact": {"path": "/absolute/raw/source", "sha256": "64-hex"}
}
```

`raw_ref.path` and `raw_ref.line` remain exact record pointers. `artifact`
identifies the containing canonical file and is not the SQLite database. A
compatibility flag may emit v1 during consumer migration, but v2 becomes the
only default after Provenance and Gauntlet stop consuming v1.

### Warden findings

`hindsight events ... | warden inspect --stdin` emits
`warden/finding@1` JSONL. Each finding names its input event IDs, rule ID,
severity, claim, evidence references, and gaps. Valid input with findings exits
0; incomplete coverage exits 1; usage/schema failure exits 2. Finding presence
alone never becomes an enforcement gate.

## Conductor loop and job model

Conductor's native loop preserves Ralph's earned behavior:

1. One explicit repo and one explicit Bead/plan/artifact.
2. One fresh harness context per iteration.
3. One bounded unit of work per iteration.
4. A runnable verifier before work begins.
5. Durable state before and after every external process.
6. Resume/reclaim after interruption.
7. Worker identity plus exclusive repo lease; an unrelated commit cannot count
   as success.
8. Failure of one attempt is recorded and bounded; it does not corrupt or
   silently widen the approved run.
9. Verification and optional independent review decide terminal success.
10. No push and no `chezmoi apply`.

The first release uses a closed `JobKind` enum instead of a workflow DSL:

| Job | Mutation | Selection | Terminal rule |
|---|---|---|---|
| `work` | Repo writes allowed inside approved scope | Lowest capable eligible profile, then job-configured fallback | Verified commit and optional qualitative review |
| `review` | Read-only | Approved provider-diverse reviewer panel plus Lead judge | Complete schema-valid panel and synthesis |
| `consult` | Read-only | Explicit ordered profile IDs | Evidence-or-gaps answer envelope |
| `arena` | Isolated worktrees only | Explicit candidate profile IDs plus judge | All candidates graded; winner application remains separately approved |

Configuration binds jobs to Bursar profile IDs. For example, a review job may
bind two reviewer profiles corresponding to GPT-5.6 Sol and Claude Fable 5,
but config validation rejects any ID absent from the pinned Bursar snapshot.
The example does not predeclare either profile in the roster. The validated job
binding is the single operational source for reviewer and fallback order; skills
and migration notes defer to it instead of duplicating model-name policy. For
the requested first review binding, Fable 5 is the preferred reviewer when
positively eligible, the same target also receives a positively eligible
non-Anthropic review, and the Lead synthesis judge is independent of both the
implementation profile and reviewer attempts. A degraded panel is explicit and
cannot satisfy the product-readiness gate.

`scan`, fleet-wide `cycle`, automatic triage backfill, and the unattended
ratchet are legacy compatibility surfaces. They receive correctness fixes while
still used, but they do not define the new core and are removed only after the
explicit-target loop proves parity.

## Hindsight storage architecture

### Canonical versus derived state

Canonical evidence:

- raw Claude Code, Codex, Pi, AGY, harness-deck, and Beads artifacts
- Git commits and repository state
- Conductor run manifests/events/artifacts
- `~/.local/state/hindsight/observations.jsonl`

Derived state:

- `~/.local/share/hindsight/hindsight.sqlite3`
- generated scorecard reports
- cached attribution and aggregate views

Deleting the SQLite file and running `hindsight db rebuild` must reproduce all
mechanical rows from canonical inputs. Human observations survive because they
live in the append-only journal. The database never stores raw prompt, file
content, environment dumps, or complete tool input; it stores redacted event
fields plus `raw_ref` and hashes.

### SQLite posture

Use `rusqlite` with a bundled SQLite so behavior does not depend on the macOS
system library. Use rollback-journal mode initially, one bounded writer
transaction at a time, `foreign_keys=ON`, a finite busy timeout, migrations in
one transaction, `application_id`, `user_version`, and an exposed
`integrity_check` command.

Do **not** enable WAL initially. SQLite disclosed a rare multi-connection
WAL-reset corruption bug affecting releases through 3.51.2; fixed versions are
3.51.3, 3.50.7, and 3.44.6. The current local SQLite and the SQLite bundled by
the current `rusqlite` release inspected during design are below those fixed
versions. Rollback journal avoids that bug and is adequate for a CLI-scale,
single-writer index. WAL may be reconsidered only with a runtime/version gate
against a fixed SQLite. See the official
[SQLite WAL documentation](https://sqlite.org/wal.html) and
[rusqlite bundled-feature guidance](https://docs.rs/crate/rusqlite/latest).

Core tables are responsibility-shaped rather than source-shaped:

- `source_files` — source kind, path, fingerprint, size, mtime, cursor, status
- `events` — normalized redacted events, stable ID, raw reference, source hash
- `runs` and `attempts` — Conductor lifecycle, job, profile, outcome, verifier
- `artifacts` — path/hash/kind references
- `observations` — imported append-only human assessments
- `attributions` — Provenance correlations with confidence and evidence
- `coverage_gaps` — parse, source, join, and schema gaps

Views may aggregate these tables, but no duplicate model/harness scorecard
tables become independently mutable truth.

### Incremental ingestion

Each source file has a fingerprint and cursor. Append-only growth resumes from
the cursor. Truncation, replacement, or fingerprint mismatch invalidates only
that source file's derived rows and replays it. Event IDs deduplicate retries.
One malformed record produces a coverage gap and does not discard the rest of
the file. Existing Hindsight P0/P1 parser, discovery, redaction, and gap defects
must land before their source is admitted to the index.

## Scorecards in Hindsight

The primary observed unit is the **execution profile**, not a model in
isolation:

`model + provider + harness + reasoning effort + job + task tier/complexity`.

Every attempt also records harness/model version when available, but versions
do not rewrite the stable Bursar profile ID. The model scorecard and harness
scorecard are views over the same attempt evidence. Planned and actually
executed post-fallback profile IDs are separate fields. The interaction fixture
matrix covers work candidates and fallbacks, qualitative review and repair,
model-based verification judges, adversarial reviewers and synthesis judges,
consult calls, and Arena candidates and judges; a multi-call Bead is never
collapsed into one opaque attempt.

Required metrics:

- verifier pass and accepted-change rates
- independent-review outcome when present
- no-op, retry, timeout, and infrastructure-failure rates
- wall time, input/output tokens, and provider-reported cost
- cost and time per accepted change
- sample count, project/task coverage, and missing-data counts

Comparisons are stratified by job and complexity; unlike tasks are not blended
into one global winner. Every row exposes sample size and evidence window.
`n < 5` is labeled provisional by default. A roster promotion/demotion
recommendation requires at least five verified comparable attempts and evidence
from at least two distinct tasks; config may raise but not silently lower that
floor. Sparse evidence remains visible but cannot masquerade as certainty.

Human ratings are immutable observation records. A correction appends a new
record referencing the old one; it does not edit history. Legacy
`~/.claude/model-bench.jsonl` rows and `model-scorecard.md` Experience Log lines
are imported once with their original raw references and source labels.
Conductor may dual-write the legacy ledger only until Hindsight import,
scorecard, and published-report parity are pinned. The parity gate then removes
the legacy writer and obsolete scorecard-driven roster-drift path without
deleting historical inputs.

Hindsight provides:

```text
hindsight scorecard model|harness|profile [--job <name>] [--json]
hindsight scorecard publish
hindsight roster recommend --window <duration> --json
hindsight observe ...
```

`roster recommend` emits an evidence-window hash, affected profile IDs,
before/after proposal, metrics, sample/coverage warnings, and gaps. It never
edits `bursar/roster.toml`.

## Capability migrations

### Provenance into Hindsight

Fix `provenance-5fu`, `provenance-a2g`, `provenance-f7d`, and
`provenance-srt` first. Freeze their corrected behavior as a checked-in
correlation corpus. Port the correlation/confidence/query behavior into
Hindsight's `attributions` store and `hindsight attribution` CLI. Only after
fixture and live-sample parity does the `provenance` command become a warning
shim and the repo archive.

### Gauntlet into Conductor and Hindsight

Fix the false-PASS and discrimination P1s first. Move golden tasks,
static lint, smoke discrimination, worktree execution, conjunctive verifier
plus judge, replay, and A/B comparison into `conductor arena eval`. Arena
candidates run through the same native loop kernel. Move cost/scorecard
aggregation to Hindsight. Preserve golden tasks as data; do not preserve a
second execution engine.

### Envoy into the consult job

Fix its three envelope-validator defects and freeze golden/broken fixtures.
Move the prompt, schema, evidence-or-gaps rule, and validation into Conductor's
read-only `consult` job. The Envoy repo becomes historical after parity; there
is no Envoy daemon or transport.

### Foreman into a skill

Turn the existing design into a concise `foreman` skill with one deterministic
script that renders, but never executes, a reviewable Bead-creation script.
Keep the earned rules: no Bead without runnable Verify, spec facts copied
exactly, codebase prescriptions require grep evidence, routing metadata appears
in metadata and notes, and no silent drops. Validate the skill with the standard
skill validator and a fixture render. Retire the six deferred Rust-binary Beads
only after the skill is installed from the canonical chezmoi source.

## Invariants

1. One writer per repo; cross-repo parallelism never means two writers in one repo.
2. Every execution starts from an explicit target and immutable maximum scope.
3. Unknown roster, provider, schema, artifact hash, verifier, or approval state fails closed.
4. Raw evidence is canonical; Hindsight SQLite is rebuildable.
5. Scorecards cannot mutate the roster.
6. Conductor emits attempts and outcomes; it does not aggregate its own reputation.
7. Bursar reports facts and approved profile policy; it does not choose work.
8. Warden reports findings; it never enforces or mutates in this phase.
9. No new daemon, network service, shared Cargo crate, or generic plugin framework.
10. Every compatibility shim has a removal gate and may not accumulate new features.
11. Every migration preserves a golden/parity corpus before the old binary retires.
12. No push and no automated `chezmoi apply`.

## Cutover gates

Guildhall may be archived only when all are true:

1. The active Conductor adversarial-review worktree is completed, reviewed, and merged.
2. Existing audit false-attribution and unwired-source P0s are closed.
3. `bursar roster snapshot` reproduces every enabled current Conductor profile and provider state.
4. Conductor runs `work`, `review`, `consult`, and `arena` through one native kernel with resumable state and identity-checked verification.
5. Hindsight rebuilds from canonical inputs and reproduces legacy model/harness scorecards within documented parity tolerances.
6. Hindsight attribution matches the corrected Provenance corpus.
7. Warden consumes Hindsight v2 events and emits findings without writes.
8. Conductor Arena/eval matches the corrected Gauntlet corpus.
9. Ralph, scorecard generator, orchestration skills, and state-backup scripts have reviewed compatibility migrations in chezmoi/state repos.
10. An installed-binary, no-metered-dispatch vertical smoke runs Bursar → Conductor → Hindsight → Warden in isolated state roots and verifies every artifact hash/schema boundary.
11. A supervised readiness check proves the configured Fable-plus-non-Anthropic review panel and independent Lead judge are positively eligible, or records an explicit blocking/degraded result that cannot be reported as product-ready.

## Non-goals

- A distributed scheduler, always-on service, web UI, or remote database.
- Automatic model promotion, auto-enable, or scorecard-driven routing changes.
- A general workflow DSL or user-authored plugin runtime.
- Preserving fleet-wide unattended `cycle`/ratchet behavior as the product goal.
- A Conductor-owned roster editor or any automatic scorecard-to-roster change.
- Migrating raw transcripts into SQLite.
- Deleting historical repos before parity and rollback artifacts exist.

## Grounded sources

- Current Ralph driver: `~/git/chezmoi-personal/private_dot_local/bin/executable_ralph`
- Current loop policy: `~/git/chezmoi-personal/dot_claude/skills/loops/SKILL.md`
- Bursar roster and execution profiles: `~/git/bursar/roster.toml`
- Conductor job and fallback policy: `~/git/conductor/conductor.toml`
- Bursar roster-TUI backlog: `bursar-vsv` in `~/git/bursar/.beads/`
- Conductor adversarial-review spec and active worktree state:
  `~/git/conductor/.docs/ai/phases/adversarial-design-review-spec.md` and
  `~/git/.worktrees/conductor-provider-trust-p1/.docs/ai/current-state.md`
- Hindsight normalized event model and full-scan seam:
  `~/git/hindsight/src/event.rs`, `src/recap.rs`, and `src/cli.rs`
- Bursar provider availability and append-only observations:
  `~/git/bursar/src/status.rs` and `src/observations.rs`
- Provenance correlation: `~/git/provenance/src/correlate.rs`
- Gauntlet execution/eval components: `~/git/gauntlet/src/`
- Envoy contract: `~/git/envoy/skill/` and `scripts/validate-envelope.sh`
- Foreman design: `~/git/foreman/.docs/ai/phases/foreman-v1-spec.md`
