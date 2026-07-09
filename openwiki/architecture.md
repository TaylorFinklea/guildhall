# Architecture

> Guildhall is narrative architecture over code: a charter, a component
> registry, suite-wide invariants, two shared specifications, and the
> dependency graph that ties eight cooperating tools together. This page
> synthesizes the structural design; the source of truth is
> [`README.md`](../README.md) (the charter) and
> [`phases/guildhall-integration-v1-spec.md`](../.docs/ai/phases/guildhall-integration-v1-spec.md).

## The metaphor → function map

Guildhall frames an AI-coding-fleet orchestration suite as a craft guild.
Each tool is a guild member with a social role; the mapping is consistent
across all docs and bead IDs.

| Guild term | System role | Lives in |
|---|---|---|
| The charter | Shared agent law: tiers, conventions, landmines | `~/AGENTS.md` (referenced from this repo's `README.md`) |
| Ranks (apprentice/journeyman/master) | Junior / Senior / Lead model tiers | `~/.claude/templates/tiers.md` |
| The register | Live roster + experience log, evidence-based | `~/.claude/model-scorecard.md` + `~/.claude/model-bench.jsonl` |
| **Conductor** — master of works | Cycle orchestrator: scan → triage → dispatch → verify → report | `~/git/harness-conductor` |
| **Foreman** — the works office | Spec-to-backlog compiler (interview → spec → bead DAG) | `~/git/foreman` |
| **Gauntlet** — masterpiece trials | Eval CI for the agent stack; rank evidence | `~/git/gauntlet` |
| **Hindsight** — the inquest | Fleet flight recorder over transcript substrate | `~/git/hindsight` |
| **Provenance** — hallmarks | Authorship/exposure audit: transcript ↔ git hunks | `~/git/provenance` |
| **Warden** — inspecting officer | Host-agnostic policy engine (generalizes pi guardian) | `~/git/warden` |
| **Bursar** — the treasury | Provider quota/window ledger | `~/git/bursar` |
| **Envoy** — the emissary | Agent-consult primitive ("wear the repo's shoes") | `~/git/envoy` |

Discontinued members: **Keeper** (photo culling — killed, Lightroom covers it),
**Steward** (home agent — folded into hermes; its fail-closed actuation policy
survives as a Warden design requirement), **Sotto** (Swift on-device agent
framework — separate effort, not a guild member).

*Source: [`README.md`](../README.md) § "The metaphor → function map".*

## The substrate principle

> **Artifacts on disk are the event bus.**

Guild members communicate exclusively through durable files in locations the
others already read — harness-deck reports, transcript JSONL per the
[ingestion event model](#ingestion-event-model), Envoy envelope files, beads
(`bd`), and git itself. No broker, no daemon, no live IPC. New IPC mechanisms
require a charter amendment.

**Corollary: exit codes are testimony; artifacts are evidence.** agy exits 0
on quota-exhausted no-ops. Every dispatch verifier in the guild judges by
artifact (new commit, file present, log line) — never by exit code alone.
This was learned in production during Conductor cycle 1, where a 0-byte
"success" cost two dispatch attempts before diagnosis.

*Source: [`README.md`](../README.md) § "The substrate principle"; ADR
[2026-07-01] in [`decisions.md`](../.docs/ai/decisions.md).*

## Suite-wide invariants

These nine invariants are law for every guild member. Violations are bugs.

1. **Closed roster.** Only standing pre-authorized models receive work; anything
   else escalates to the user. Every non-default-model run is logged to the
   register's Experience Log.
2. **`tier_floor` is a hard ownership gate.** Below-floor pickup stops and
   flags. Mis-triaging down is the expensive error — round up when unsure.
3. **Fail closed everywhere.** No Verify → no headless dispatch. Failed Verify
   → bead stays open with a note. Ambiguous → escalate. Unknown tool names in
   Warden → gated, not passed.
4. **Never push. Never `chezmoi apply`.** Never operate on chezmoi-config.
   Never write into `~/.claude`, `~/.pi`, `~/.codex`, `~/.gemini` — anything
   destined there is produced as content in-repo plus a pending-human handoff.
5. **One writer per repo at a time.** Cross-repo parallelism is fine.
6. **Shell landmines are law**: TUI CLIs get `< /dev/null`; agy gets
   `--add-dir "$PWD"`; `bd ready --claim` mutates; `bd stealth init` edits the
   tracked `.gitignore` — revert it (the mechanism is `.git/info/exclude`).
7. **Budgets ride with plans.** Every dispatch plan states caps; approval of
   the plan is approval of the caps. Bursar's ledger is the eventual source for
   "can we afford it."
8. **Coverage gaps are reported as gaps** — never papered over (ralph and
   orchestra emit no durable logs; pi lacks git fields; opencode-go quota is
   vendor-opaque; say so).
9. **Routing fields live in bd metadata** (`tier_floor`, `complexity`,
   `verify_cmd`), mirrored in notes-prose for cross-harness readers.

*Source: [`README.md`](../README.md) § "Suite-wide invariants".*

## Component MVPs and build order

### Build order

```
warden → hindsight → envoy → bursar → provenance → gauntlet → foreman
```

Conductor's own M3–M6 milestones proceed in parallel throughout; Bursar can
float earlier whenever a cycle has spare senior capacity.

**Rationale**: Warden first because the fleet dispatches *today* and its
safety floor is compensating-controls-only until Warden ships. Hindsight second
because every later member (Provenance, Gauntlet's golden-task harvest, Bursar's
spend reconstruction) reads the transcript substrate through its ingestion lib.
Foreman stays last: its product is the crystallization of what the Lead-by-hand
spec sessions prove out — building it earlier bakes in guesses.

*Source: [`README.md`](../README.md) § "Build order"; ADR [2026-07-01] in
[`decisions.md`](../.docs/ai/decisions.md).*

### One-line MVPs

- **conductor** — one full scan→triage→approve→dispatch→verify cycle over the fleet.
- **warden** — guardian's policy core extracted to a host-agnostic library + Claude Code PreToolUse adapter + the agy interception verdict memo.
- **hindsight** — `hindsight recap --since <t>` over Claude Code + pi + Codex (+ guardian/agy logs) → harness-deck report. Owns the shared ingestion lib first.
- **envoy** — the consult skill (content in-repo, installation handed off) + envelope conformance; live transport deferred.
- **bursar** — library + `bursar status` → JSON for Conductor. Deliberately the smallest member.
- **provenance** — `provenance annotate <repo>` correlating transcripts↔git hunks + the junior-unreviewed query. Consumes Hindsight's ingestion lib — never forks parsers.
- **gauntlet** — 5–10 golden tasks from real transcripts, replayed in throwaway worktrees, Verify + fail-closed judge, A/B to harness-deck.
- **foreman** — interview → recon greps → spec + bead-DAG script; refuses beads without Verify; emits "mirror X" instead of unverified prescriptions. Built LAST.

*Source: [`README.md`](../README.md) § "Component registry & MVPs".*

## The v1 vertical slice (integration proof)

Guildhall v1 is proven when this single flow runs end to end, mostly
dry-run/read-only:

1. **Conductor** scans `~/git`, finds beads-tracked repos, triages ready beads
   using real `tier_floor`/`complexity` metadata, publishes a cycle plan to
   harness-deck.
2. **Bursar** answers "can we afford it" via `bursar status --json`, feeding
   Conductor's budgeting so near-exhausted/opaque windows defer external dispatch.
3. On approval, Conductor dispatches a bead. The worker's safety floor is
   **compensating controls** (worktree isolation, verify-by-artifact, quota caps)
   because **Warden cannot live-gate pi/agy inner tool loops** — Warden's live
   enforcement covers the Claude Code surface only.
4. **Hindsight** reconstructs what happened from the transcript substrate and
   publishes a report; coverage gaps are reported as gaps.
5. **Provenance** annotates which model authored which surviving hunks,
   consuming Hindsight's ingestion lib (never forking parsers).
6. **Gauntlet** replays golden tasks to produce evidence-backed `efficiency`
   ratings — a proposed patch to `tiers.md`, handed to the human.
7. **Foreman** (built last) crystallizes the by-hand spec→backlog compilation
   this whole effort demonstrated.

**v1 "done"** = steps 1–2 provably work end to end (the dry-run cycle + bursar
budget), Conductor's tiered qualitative-review stage ships and gates closes
(`conductor-review` — user decision 2026-07-02), and every member has reached
its own spec's final milestone with verify passing (foreman explicitly
excepted — built last, stays deferred).

### Cross-repo dependency graph

`bd` has no cross-repo dependency primitive, so these edges live only in prose
in the integration spec. The orchestrator must honor them manually:

- `provenance` M4/M5 ← **needs** `hindsight` ingestion lib extracted (parsers
  pulled from Hindsight, never forked).
- `conductor-bursar` ← **needs** `bursar-m4-cli` shipping `bursar status --json`
  (the `bursar/status@1` contract).
- `conductor-warden` ← **needs** `warden` core lib (m1/m2/m3) + `warden-m6`
  coverage doc.
- `conductor-guildhall-dogfood` ← **needs** `conductor-m3b` (dry-run cycle) +
  the Guildhall repos having seeded backlogs.
- `gauntlet-m3` (golden-task harvest) ← **benefits from** the rich real
  transcript data + `~/.claude/model-bench.jsonl`.

### Non-goals (v1)

Live inter-member IPC beyond files (substrate principle); Envoy live transport;
`hindsight why`; Warden live-gating of pi/agy (compensating controls only); a
running Conductor daemon (manual `conductor cycle`).

*Source:
[`phases/guildhall-integration-v1-spec.md`](../.docs/ai/phases/guildhall-integration-v1-spec.md).*

## Shared specifications

### Ingestion event model

The normalized event model for all transcript sources. First implementation
lives in Hindsight; extracted to a shared lib only when Provenance needs it.
**Do not fork parsers.**

**Sources** (all verified on disk 2026-07-01):

| Source | Path | Format | Key correlation |
|---|---|---|---|
| `claude-code` | `~/.claude/projects/<slug>/<sessionId>.jsonl` | JSONL typed records | `cwd` + `gitBranch` on every record |
| `pi-session` | `~/.pi/agent/sessions/<slug>/<ts>_<id>.jsonl` | JSONL | None — infer from bash command strings |
| `pi-observability` | `~/.pi/agent/logs/session-<id>.jsonl` | JSONL events | `session_start.sessionFile` → exact join to pi-session |
| `guardian` | same as pi-observability, `event:"guardian_decision"` | JSONL | policy audit trail |
| `codex` | `~/.codex/sessions/YYYY/MM/DD/rollout-<ts>-<uuid>.jsonl` | JSONL | Strongest: `session_meta.payload.git.{commit_hash,branch}` |
| `agy` | `~/.gemini/antigravity-cli/log/cli-<ts>.log` | glog text (not JSONL) | None; `RESOURCE_EXHAUSTED` grep = no-op detector |
| `harness-deck` | `~/.harness/reports/<project>/<run>/report.json` | JSON | `project` = repo basename |
| `beads` | `<repo>/.beads/interactions.jsonl` | JSONL `field_change` | `actor`; free-text `reason` names commit/model |

**Normalized event** (v1): one flat record per interesting moment; `raw_ref`
always points home; sparse — absent fields are absent, never invented.

```json
{
  "ts": "RFC3339",
  "source": "claude-code|pi-session|pi-observability|guardian|codex|agy|harness-deck|beads",
  "kind": "session_start|message|tool_call|tool_result|commit_evidence|decision|usage|quota|report|field_change",
  "session_id": "…", "parent_ref": "…",
  "agent": {"model": "…", "provider": "…", "harness": "…", "tier": "…?"},
  "repo": {"cwd": "…", "git_branch": "…?", "git_commit": "…?"},
  "tool": {"name": "…", "input_summary": "≤200 chars"},
  "usage": {"input_tokens": 0, "output_tokens": 0, "cost_usd": "…?"},
  "raw_ref": {"path": "…", "line": 0}
}
```

**Known coverage gaps** (report as gaps in every recap): ralph (zero durable
logs), orchestra verify/audit (stdout-only, no audit file), pi (no git fields),
codex sqlite stores (unexplored), unbounded retention everywhere, agy (glog
text only, conversation DBs unparsed in v1).

*Source:
[`phases/ingestion-event-model.md`](../.docs/ai/phases/ingestion-event-model.md).*

### Envoy envelope

The message format for agent-to-agent consults ("wear the repo's shoes").

```json
{
  "envelope": "guildhall/envoy@1",
  "id": "env-<ulid>",
  "ts": "RFC3339",
  "kind": "question | answer | notice",
  "from": {"hall": "conductor|hindsight|human|…", "agent": "model-or-person", "session_ref": "transcript path?"},
  "to":   {"repo": "/abs/path", "hall": "…?"},
  "reply_to": "env-… (answers/notices only)",
  "deadline": "RFC3339?",
  "constraints": {"read_only": true, "max_minutes": 15},
  "question": { "text": "…", "schema": { "…optional JSON Schema…" } },
  "answer": { "value": "…", "confidence": "high|medium|low",
              "evidence": [{"path": "file", "line": 0, "note": "…"}],
              "gaps": ["what could not be determined and why"] }
}
```

Key rules: `read_only: true` is the default and v1-only mode; consults never
mutate the target repo. Answers cite evidence (`path:line`) or declare gaps —
same fail-closed ethos. Envelopes are files in `<target-repo>/ai-scratch/envoy/`
while in flight (ai-scratch is globally gitignored). The consult agent is
primed as a native session would be (cwd = target repo, `bd prime`, the repo's
AGENTS.md/CLAUDE.md + `.docs/ai/`).

*Source: [`phases/envoy-envelope.md`](../.docs/ai/phases/envoy-envelope.md).*

## Key architectural decisions

All ADRs are in [`decisions.md`](../.docs/ai/decisions.md) — append-only, one
entry per decision. The most consequential:

- **[2026-07-01] Substrate principle**: artifacts on disk are the event bus; no
  broker/daemon. New IPC requires a charter amendment.
- **[2026-07-01] Ingestion lives in Hindsight first; Provenance extracts, never
  forks**: one parser implementation, one move to a shared lib.
- **[2026-07-01] Exit codes are testimony; artifacts are evidence**: every
  verifier judges by artifact, never exit code alone.
- **[2026-07-01] Warden gates unknown tools**: reverses guardian's
  pass-through; unknown tool names default to the gated path.
- **[2026-07-02] conductor-review gates v1**: tiered qualitative review after
  mechanical verify is mandatory for v1, not optional (user decision).
- **[2026-07-03] Autonomy posture**: the ratchet mechanism ships per spec
  (ceiling {senior,junior}/≤M), but month-1 config DEFAULT is junior-floor +
  S-complexity only. Widening is a human config change backed by ratchet
  evidence.
- **[2026-07-03] Cutover: shadow-first, evidence-gated**: 3 consecutive
  matching sessions (conductor dry-run vs actual routing) before cutover to
  `conductor dispatch`.