# Undertake core consolidation — approved architecture

**Status**: direction approved by the user 2026-07-14. This spec replaces the
Guildhall-as-product model after the current correctness gates land. The tracked
Bead generator and execution plan beside this file are the implementation handoff.

## Mission

Reduce the suite to one explicit execution kernel and three small cooperating
tools:

- **Undertake** runs an explicitly selected, verified job loop.
- **Musterroll** answers which execution profiles exist and whether they are usable.
- **Afterfact** records and indexes evidence, attributes work, and derives model
  and harness scorecards.
- **Cautionlight** reads Afterfact events and emits advisory findings.

Provenance, Gauntlet, Envoy, and Foreman contribute their proven capability to
those four surfaces and then stop being standalone binaries. Guildhall remains
only as the migration/history repository until the cutover is proven, then is
archived. The design follows a Unix boundary: versioned files and JSONL on
stdout, diagnostics on stderr, no shared daemon, no hidden control plane, and no
tool silently editing another tool's state.

## Locked decisions

| Decision | Locked value |
|---|---|
| Undertake's one job | Run one explicit target under one named job until a verifier-backed terminal state. |
| Fleet discovery | Not core. `scan`/`cycle` remain compatibility surfaces during migration; new runs require an explicit repo plus Bead, plan, or artifact. |
| Loop engine | Native Undertake state machine. Ralph becomes a temporary compatibility shim only after parity; Undertake does not wrap Ralph as a second state machine. |
| Jobs in the first release | Closed set: `work`, `review`, `consult`, `plan`. Configuration binds jobs and roles to Musterroll profile IDs and limits; no general workflow DSL. |
| Adversarial review | Survives intact as the `review` job: N provider-diverse reviewers plus an independent Lead judge. The existing `adversarial-review` command remains a compatibility alias during cutover. |
| Planning | `plan` is a separate bounded job for producing a strict spec or implementation plan. It is not a hidden `work` stage or a second loop engine. |
| Roster owner | Musterroll owns providers, exact execution profiles, unordered role capabilities, and availability facts. |
| Routing policy | Undertake owns enabled role pools, weights, selection, fallback order, stopping rules, verification, and approval. Musterroll never dispatches or chooses a job. |
| Scorecard owner | Afterfact owns empirical model, harness, execution-profile, and job/profile scorecards. Musterroll stores only the human-approved operational roster. |
| Feedback loop | Afterfact may emit an evidence-pinned roster recommendation. It never writes Musterroll config. Human approval is mandatory. |
| Afterfact database | SQLite is a disposable materialized index. Raw harness artifacts, Git, Undertake run artifacts, and Afterfact's append-only observation journal are canonical. |
| Provenance | Correlation, attribution, and unreviewed-change queries move into Afterfact after the existing false-attribution defects are corrected and frozen as a parity corpus. |
| Gauntlet | Its corrected corpus remains evaluation evidence for Undertake `plan`/`review`; it does not survive as another executor. Cost and scorecard aggregation move to Afterfact. |
| Envoy | Its read-only evidence envelope and prompt become Undertake's `consult` job. |
| Foreman | Becomes a concise skill that creates a spec and reviewable Bead script; the planned Rust binary is retired. |
| Cautionlight | Read-only and advisory. It consumes Afterfact's event stream and emits findings; it does not install a blocking hook, mutate repos, or write Afterfact state. |
| Guildhall | No runtime umbrella, broker, or ninth tool. Archive after the four-tool vertical slice and compatibility cutover pass. |

## Why this is not another abstraction layer

Each surviving process has one independently useful question:

| Tool | Question | Owns | Explicitly does not own |
|---|---|---|---|
| Undertake | How do I run this explicit job safely to completion? | Loop state, job policy, approval, verification, run artifacts | Roster facts, performance history, global fleet discovery |
| Musterroll | Which execution profiles are configured and currently eligible? | Versioned roster config, provider/profile availability | Job choice, fallback policy, scorecards, dispatch |
| Afterfact | What happened, who did it, and how did each execution profile perform? | Canonical observation journal, derived index, attribution, scorecards | Execution, provider enablement, roster mutation |
| Cautionlight | What suspicious or policy-relevant patterns appear in this event stream? | Stateless rules and finding records | Enforcement, hooks, storage, execution |

If a proposed feature cannot be answered by one of those questions, it does
not enter this program. There is no generic plugin framework, broker, scheduler,
workflow language, or shared service.

## System shape

```mermaid
flowchart LR
    Human["Human or fresh orchestrator"] -->|explicit target + job| C["Undertake\nverified loop kernel"]
    B["Musterroll\nroster + availability"] -->|musterroll/roster@2 snapshot| C
    C -->|undertake/run@2 + undertake/event@2| Raw["Durable runs-v2 artifacts"]
    Logs["Harness logs + Git + legacy ledgers"] --> H["Afterfact\nSQLite derived index"]
    Raw --> H
    Obs["Append-only human observations"] --> H
    H -->|afterfact/event@2 JSONL| W["Cautionlight\nread-only findings"]
    H -->|scorecards + evidence-pinned proposal| Human
    Human -->|approved edit| B
    W -->|cautionlight/finding@1 JSONL| Human
```

The only feedback path passes through the human. No scorecard can promote a
model or enable a provider by itself.

## Stable process contracts

All machine output uses one JSON object per line or one atomic JSON artifact.
Every schema is versioned. Unknown schema families or versions fail visibly.
Diagnostics never share stdout with data.

### Musterroll roster snapshot

The canonical version-controlled roster lives in `musterroll/roster.toml`. Static
config uses strict `musterroll/roster-config@2`; the read-only snapshot command
emits strict `musterroll/roster@2`.

An execution profile is the operational unit. `ProfileId` is an opaque stable
roster label. `ExecutionKey` is the exact provider, model, harness, dispatch
ID, and reasoning-effort coordinate; both identities are unique. Provider
diversity compares exact `ProviderId`, while `AvailabilityKey` is only a health
lookup key and may not collapse diversity.

Required profile fields:

- `profile_id`, `provider_id`, `model`, `harness`, `dispatch_id`
- optional `reasoning_effort`
- approved `tier`, `ceiling`, `efficiency`, `cost`, and `data_policy`
- `enabled`
- a sorted, duplicate-free role array

Roles are unordered capability facts validated with Musterroll's identifier
grammar. Every enabled profile has `default` and `task`; Junior adds `smol`,
`tiny`, and `commit`; Senior and Lead add `advisor`; Lead adds `slow` and
`plan`. Exact confirmed image-capable execution paths add `vision`, and only a
Lead with confirmed vision adds `designer`. This is the complete initial
taxonomy. Fallback order, weights, review constraints, and job policy do
**not** belong in Musterroll.

The v2 migration **must** add these three enabled profiles with every field
asserted independently. `ProfileId` remains opaque: neither Musterroll nor its tests
may parse a profile label to derive any execution coordinate or capability fact.

| `profile_id` | `provider_id` | `model` | `harness` | `dispatch_id` | `reasoning_effort` | `tier` | `ceiling` | `efficiency` | `data_policy` | sorted required roles |
|---|---|---|---|---|---|---|---|---|---|---|
| `openai-codex--omp--gpt-5.6-sol--xhigh` | `openai-codex` | `gpt-5.6-sol` | `omp` | `openai-codex/gpt-5.6-sol` | `xhigh` | `lead` | `XL` | `heavy` | `standard` | `advisor`, `default`, `designer`, `plan`, `slow`, `task`, `vision` |
| `anthropic--omp--claude-opus-4-8--max` | `anthropic` | `claude-opus-4-8` | `omp` | `anthropic/claude-opus-4-8` | `max` | `lead` | `XL` | `heavy` | `standard` | `advisor`, `default`, `designer`, `plan`, `slow`, `task`, `vision` |
| `opencode-go--omp--kimi-k3--max` | `opencode-go` | `kimi-k3` | `omp` | `opencode-go/kimi-k3` | `max` | `lead` | `XL` | `heavy` | `standard` | `advisor`, `default`, `designer`, `plan`, `slow`, `task`, `vision` |

The executable Musterroll v2 backlog is the new open chain
`musterroll-roster-v2-contract` → `musterroll-roster-v2-migrate` →
`musterroll-roster-v2-snapshot`. The closed `bursar-roster-contract`,
`bursar-roster-migrate`, and `bursar-roster-snapshot` Beads remain immutable v1
implementation evidence and cannot satisfy any v2 gate. Both
`undertake-run-v2` and `undertake-role-routing` are cross-repo gated on the
terminal `musterroll-roster-v2-snapshot` Bead; `undertake-plan-job` inherits that
gate through role routing.

`musterroll roster snapshot --config <path> --json` emits:

```json
{
  "schema": "musterroll/roster@2",
  "generated_at": "RFC3339",
  "source_artifact": {"path": "/absolute/path/roster.toml", "sha256": "64-hex"},
  "policy_sha256": "64-hex",
  "providers": [],
  "profiles": []
}
```

The source hash preserves raw provenance. `policy_sha256` hashes the canonical
nonvolatile provider/profile/capability projection. A prepared Undertake run
copies the exact emitted snapshot bytes into a run-local artifact and pins that
copy's path, size, and SHA-256; authorization and resume never authenticate
eligibility by rereading only the live roster path.

Each provider/profile entry includes resolved enablement and point-in-time
availability with evidence timestamps. Missing config, duplicate execution
coordinates, invalid roles, unknown/stale availability, or an unreadable
observation ledger cannot become eligible. Musterroll offers `check`, `list`, and
`snapshot`; its optional roster/availability TUI remains human-confirmed and
uses the same validation and append-only observation paths. Undertake does not
own roster editing.

### Undertake run artifacts

Every v2 invocation creates:

```text
~/.local/state/undertake/runs-v2/<run-id>/
  manifest.json       # undertake/run@2, atomic replacement
  events.jsonl        # undertake/event@2, append-only
  approval.json       # immutable approved envelope when required
  roster.json         # copied exact musterroll/roster@2 snapshot
  attempts/           # stdout, stderr, verifier, and reviewer artifacts
  artifacts/          # target, prompt, plan, and hash-pinned evidence
```

The v2 binary scans only `runs-v2/`; finished v1 `runs/` and legacy state remain
inert historical data. Before deployment, cycle/dispatch is quiesced and every
v1 run that recovery classifies as pending, implementing, or reclaimable is
resolved. There is no mixed-schema parser.

`undertake/run@2` uses strict job-tagged details so `work`, `review`, `consult`,
and `plan` cannot carry one another's state. It pins the copied roster snapshot,
roster-policy digest, exact target artifacts, approved constrained stage routes,
limits, lifecycle, and final outcome. Plan progress is a tagged transition
system with immutable author/reviewer bindings and bounded attempts/revisions.
Every event carries at least:

```json
{
  "schema": "undertake/event@2",
  "event_id": "stable-id",
  "run_id": "run-id",
  "seq": 1,
  "ts": "RFC3339",
  "kind": "run_started|attempt_started|attempt_finished|verify_finished|review_finished|run_finished|coverage_gap",
  "job": "work|review|consult|plan",
  "role": "optional-role-id",
  "stage": "optional-snake-case-stage",
  "profile_id": "optional-profile-id",
  "target": {"repo": "/canonical/absolute/path", "artifact": "optional-run-local-ref"},
  "artifact_refs": [{"path": "/absolute/run-local/path", "sha256": "64-hex"}],
  "outcome": "optional-stable-outcome"
}
```

Undertake emits one generic attempt lifecycle for every backend invocation,
including plan authoring, peer review, revision, second opinion, adversarial
reviewers, and judges. It emits evidence, not scorecards.

### Afterfact event stream

`afterfact events` advances from the current bare event to
`afterfact/event@2`. Each line contains the normalized event plus the schema
and the canonical source artifact identity required by the existing Guildhall
stdout-layer ADR:

```json
{
  "schema": "afterfact/event@2",
  "event_id": "stable-content-id",
  "event": {},
  "artifact": {"path": "/absolute/raw/source", "sha256": "64-hex"}
}
```

`raw_ref.path` and `raw_ref.line` remain exact record pointers. `artifact`
identifies the containing canonical file and is not the SQLite database. A
compatibility flag may emit v1 during consumer migration, but v2 becomes the
only default after Provenance and Gauntlet stop consuming v1.

### Cautionlight findings

`afterfact events ... | cautionlight inspect --stdin` emits
`cautionlight/finding@1` JSONL. Each finding names its input event IDs, rule ID,
severity, claim, evidence references, and gaps. Valid input with findings exits
0; incomplete coverage exits 1; usage/schema failure exits 2. Finding presence
alone never becomes an enforcement gate.

## Undertake loop and job model

Undertake's native loop preserves Ralph's earned behavior:

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
| `review` | Read-only | Approved provider-diverse N-reviewer panel plus independent Lead judge | Complete schema-valid panel and synthesis |
| `consult` | Read-only | Explicit ordered profile IDs | Evidence-or-gaps answer envelope |
| `plan` | Disposable isolated worktree; no target mutation | Role-compatible weighted planner, peer, and optional second opinion | Strict plan artifact passes every required bounded gate |

`review` retains the shipped N-plus-one adversarial contract: immutable
approval, anonymous provider-diverse reviewers, schema repair, minority
preservation, and an independent synthesis judge. `plan` is separate. It takes
one immutable Bead or local-artifact target and produces either a strict spec or
an implementation plan; it never applies code, mutates Beads, or starts work.

Configuration validates every profile against the pinned Musterroll v2 snapshot.
An unknown job, profile, role, or execution coordinate is a usage/config
failure. Skills and migration notes defer to validated job and role bindings
instead of duplicating model-name policy.

### Role-aware plan routing

Undertake owns generic role/profile bindings. The initial `plan` pool is:

- `openai-codex--omp--gpt-5.6-sol--xhigh` at weight 60
- `anthropic--omp--claude-opus-4-8--max` at weight 20
- `opencode-go--omp--kimi-k3--max` at weight 20

Weights are relative and need not sum to 100. Smooth
weighted round-robin is deterministic and durable, with independent lanes keyed
by roster-policy digest, role, and snake-case plan stage. Hard eligibility is
applied before weights. A serialized reservation is irreversible at creation;
cancellation releases capacity but does not rewind rotation.

Authorization pins the complete planner pool and each constrained
`planner`, `peer_review`, and `second_opinion` route. Planner candidates must
have legal peer contingencies before approval; spec candidates must have a
legal pairwise-provider-distinct three-way team. The actual peer and second
opinion bind only when their stage becomes legal, never from live config.

Specs require peer review and a final distinct second opinion. Implementation
plans require peer review by default. Peer review returns strict
`approve|revise`; revision stays on the same author, a valid reviewer verdict
pins that reviewer, and the revision cap is at most three. A spec second
opinion returns distinct `accept|reject` and opens no new revision loop. Loss of
a required legal candidate ends `blocked`, never degraded success.

Plan output is validated into canonical `undertake/plan-document@1` JSON before
Markdown rendering. Specs require substantive goals, constraints,
requirements, acceptance, and verification; unresolved open questions end
`needs_input`. Implementation plans require a deterministic task graph with
unique IDs, valid dependencies, exact file/symbol targets, changes,
acceptance, and verify commands. Only validated run-local artifacts leave the
disposable worktree.

`scan`, fleet-wide `cycle`, automatic triage backfill, and the unattended
ratchet are legacy compatibility surfaces. They receive correctness fixes while
still used, but they do not define the new core and are removed only after the
explicit-target loop proves parity.

## Afterfact storage architecture

### Canonical versus derived state

Canonical evidence:

- raw Claude Code, Codex, Pi, AGY, harness-deck, and Beads artifacts
- Git commits and repository state
- Undertake run manifests/events/artifacts
- `~/.local/state/afterfact/observations.jsonl`

Derived state:

- `~/.local/share/afterfact/afterfact.sqlite3`
- generated scorecard reports
- cached attribution and aggregate views

Deleting the SQLite file and running `afterfact db rebuild` must reproduce all
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
- `runs` and `attempts` — Undertake lifecycle, job, profile, outcome, verifier
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
the file. Existing Afterfact P0/P1 parser, discovery, redaction, and gap defects
must land before their source is admitted to the index.

The closed `hindsight-conductor-runs` Bead and its review findings remain the
v1 `undertake/run@1` and `undertake/event@1` ingestion evidence. Strict v2
ingestion is separate open work in `afterfact-undertake-runs-v2`, cross-repo
gated on `undertake-run-v2` and locally blocked by the completed store and
ingest foundations. `afterfact-scorecards` depends on that new v2 ingestion
Bead; v1 close evidence cannot satisfy scorecard parity for plan/review
role-stage attempts.

## Scorecards in Afterfact

The primary observed unit is the **execution profile**, not a model in
isolation:

`model + provider + harness + reasoning effort + job + task tier/complexity`.

Every attempt also records harness/model version when available, but versions
do not rewrite the stable Musterroll profile ID. The model scorecard and harness
scorecard are views over the same attempt evidence. Planned and actually
executed post-fallback profile IDs are separate fields. The interaction fixture
matrix covers work candidates and fallbacks, qualitative review and repair,
model-based verification judges, adversarial reviewers and synthesis judges,
consult calls, plan authors and revisions, peer reviewers, and second-opinion
reviewers; a multi-call job is never collapsed into one opaque attempt.

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
Undertake may dual-write the legacy ledger only until Afterfact import,
scorecard, and published-report parity are pinned. The parity gate then removes
the legacy writer and obsolete scorecard-driven roster-drift path without
deleting historical inputs.

Afterfact provides:

```text
afterfact scorecard model|harness|profile [--job <name>] [--json]
afterfact scorecard publish
afterfact roster recommend --window <duration> --json
afterfact observe ...
```

`roster recommend` emits an evidence-window hash, affected profile IDs,
before/after proposal, metrics, sample/coverage warnings, and gaps. It never
edits `musterroll/roster.toml`.

## Capability migrations

### Provenance into Afterfact

Fix `provenance-5fu`, `provenance-a2g`, `provenance-f7d`, and
`provenance-srt` first. Freeze their corrected behavior as a checked-in
correlation corpus. Port the correlation/confidence/query behavior into
Afterfact's `attributions` store and `afterfact attribution` CLI. Only after
fixture and live-sample parity does the `provenance` command become a warning
shim and the repo archive.

### Gauntlet corpus into plan/review evaluation

Fix the false-PASS and discrimination P1s first. Preserve golden tasks, static
lint, explicit discrimination smoke, worktree integrity, conjunctive verifier
plus judge, replay, and A/B expectations as a corrected corpus. Fold that
evidence into plan-document validation, plan peer/second-opinion gates, and the
surviving adversarial `review` contract. Do not preserve a candidate runtime,
winner workflow, or second execution engine. Cost and scorecard aggregation
move to Afterfact.

### Envoy into the consult job

Fix its three envelope-validator defects and freeze golden/broken fixtures.
Move the prompt, schema, evidence-or-gaps rule, and validation into Undertake's
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
4. Raw evidence is canonical; Afterfact SQLite is rebuildable.
5. Scorecards cannot mutate the roster.
6. Undertake emits attempts and outcomes; it does not aggregate its own reputation.
7. Musterroll reports facts and approved profile policy; it does not choose work.
8. Cautionlight reports findings; it never enforces or mutates in this phase.
9. No new daemon, network service, shared Cargo crate, or generic plugin framework.
10. Every compatibility shim has a removal gate and may not accumulate new features.
11. Every migration preserves a golden/parity corpus before the old binary retires.
12. No push and no automated `chezmoi apply`.

## Cutover gates

Guildhall may be archived only when all are true:

1. The active Undertake adversarial-review worktree is completed, reviewed, and merged.
2. Existing audit false-attribution and unwired-source P0s are closed.
3. `musterroll roster snapshot` reproduces every enabled current Undertake profile and provider state.
4. Undertake runs `work`, `review`, `consult`, and `plan` through one native kernel with resumable state and identity-checked verification.
5. Afterfact rebuilds from canonical inputs and reproduces legacy model/harness scorecards within documented parity tolerances.
6. Afterfact attribution matches the corrected Provenance corpus.
7. Cautionlight consumes Afterfact v2 events and emits findings without writes.
8. Undertake plan/review evaluation matches the corrected Gauntlet corpus without another runtime.
9. Ralph, role-routing guidance, scorecard generator, orchestration skills, and state-backup scripts have reviewed compatibility migrations in chezmoi/state repos.
10. An installed-binary, no-metered-dispatch vertical smoke runs Musterroll → Undertake → Afterfact → Cautionlight in isolated state roots and verifies every artifact hash/schema boundary.
11. A supervised readiness check proves the configured Fable-plus-non-Anthropic review panel and independent Lead judge are positively eligible, or records an explicit blocking/degraded result that cannot be reported as product-ready.

## Non-goals

- A distributed scheduler, always-on service, web UI, or remote database.
- Automatic model promotion, auto-enable, or scorecard-driven routing changes.
- A general workflow DSL or user-authored plugin runtime.
- Preserving fleet-wide unattended `cycle`/ratchet behavior as the product goal.
- A Undertake-owned roster editor or any automatic scorecard-to-roster change.
- Migrating raw transcripts into SQLite.
- Deleting historical repos before parity and rollback artifacts exist.

## Grounded sources

- Current Ralph driver: `~/git/chezmoi-personal/private_dot_local/bin/executable_ralph`
- Current loop policy: `~/git/chezmoi-personal/dot_claude/skills/loops/SKILL.md`
- Musterroll roster and execution profiles: `~/git/musterroll/roster.toml`
- Undertake job and fallback policy: `~/git/undertake/undertake.toml`
- Musterroll roster-TUI backlog: `musterroll-vsv` in `~/git/musterroll/.beads/`
- Undertake adversarial-review spec and active worktree state:
  `~/git/undertake/.docs/ai/phases/adversarial-design-review-spec.md` and
  `~/git/.worktrees/undertake-provider-trust-p1/.docs/ai/current-state.md`
- Afterfact normalized event model and full-scan seam:
  `~/git/afterfact/src/event.rs`, `src/recap.rs`, and `src/cli.rs`
- Musterroll provider availability and append-only observations:
  `~/git/musterroll/src/status.rs` and `src/observations.rs`
- Provenance correlation: `~/git/provenance/src/correlate.rs`
- Gauntlet execution/eval components: `~/git/gauntlet/src/`
- Envoy contract: `~/git/envoy/skill/` and `scripts/validate-envelope.sh`
- Foreman design: `~/git/foreman/.docs/ai/phases/foreman-v1-spec.md`
