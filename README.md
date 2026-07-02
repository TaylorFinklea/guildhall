# Guildhall

A craft guild whose members are models. This repo is the hall itself: charter,
registry, suite-wide invariants, and the two shared specifications every member
builds against. **No product code lives here** — narrative architecture over
code. If you are an agent working any member repo, read this first, then your
repo's spec.

## The metaphor → function map

| Guild term | System | Where it lives |
|---|---|---|
| The charter | Shared agent law: tiers, conventions, landmines | `~/AGENTS.md` |
| Ranks (apprentice/journeyman/master) | Junior / Senior / Lead tiers | `~/.claude/templates/tiers.md` |
| The register | Live roster + experience log, evidence-based | `~/.claude/model-scorecard.md` + `~/.claude/model-bench.jsonl` |
| **Conductor** — master of works | Cycle orchestrator: scan → triage → dispatch → verify → report | `~/git/harness-conductor` |
| **Foreman** — the works office | Spec-to-backlog compiler (interview → spec → bead DAG) | `~/git/foreman` |
| **Gauntlet** — masterpiece trials | Eval CI for the agent stack; rank evidence | `~/git/gauntlet` |
| **Hindsight** — the inquest | Fleet flight recorder over transcript substrate | `~/git/hindsight` |
| **Provenance** — hallmarks | Authorship/exposure audit: transcript ↔ git hunks | `~/git/provenance` |
| **Warden** — inspecting officer | Host-agnostic policy engine (generalizes pi guardian) | `~/git/warden` |
| **Bursar** — the treasury | Provider quota/window ledger | `~/git/bursar` |
| **Envoy** — the emissary | Agent-consult primitive ("wear the repo's shoes") | `~/git/envoy` |

Dispositions from the ideation thread (recorded so they stay dead/routed):
**Keeper** (photo culling) — killed, Lightroom covers it. **Steward** (home
agent) — folded into hermes; its fail-closed actuation policy survives as a
Warden design requirement (Warden's core must serve non-code hosts). **Sotto**
(Swift on-device agent framework) — separate effort, not a guild member.

## The substrate principle

**Artifacts on disk are the event bus.** Recon (2026-07-01) proved the fleet
already emits a correlatable record substrate with no broker: Claude Code
session JSONL (cwd+branch on every record), pi session + observability JSONL
(with a built-in `sessionFile` join key), Codex rollout JSONL (commit hash at
session start), guardian decision JSONL, agy per-invocation glog files,
harness-deck `report.json`/`responses.json`, beads `interactions.jsonl`, and
git itself. Guild members communicate by writing well-formed files where the
others already look — reports to harness-deck, events per the ingestion model,
envelopes per the Envoy spec. New IPC mechanisms require a charter amendment.

Corollary, learned in production the day this charter was written: **exit codes
are testimony; artifacts are evidence.** agy exits 0 on quota-exhausted no-ops.
Every dispatch verifier in the guild judges by artifact (new commit, file
present, log line) — never by exit code alone.

## Suite-wide invariants

1. **Closed roster.** Only standing pre-authorized models receive work
   (register + `~/AGENTS.md`); anything else escalates to the user. Every
   non-default-model run is logged to the register's Experience Log.
2. **`tier_floor` is a hard ownership gate.** Below-floor pickup stops and
   flags. Mis-triaging down is the expensive error — round up when unsure.
3. **Fail closed everywhere.** No Verify → no headless dispatch. Failed
   Verify → bead stays open with a note. Ambiguous → escalate. Unknown tool
   names in Warden → gated, not passed (fixes guardian's one fail-open hole).
4. **Never push. Never `chezmoi apply`.** Never operate on chezmoi-config.
   Never write into `~/.claude`, `~/.pi`, `~/.codex`, `~/.gemini` — anything
   destined there is produced as content in-repo plus a pending-human handoff
   item.
5. **One writer per repo at a time.** Cross-repo parallelism is fine.
6. **Shell landmines are law**: TUI CLIs get `< /dev/null`; agy gets
   `--add-dir "$PWD"`; `bd ready --claim` mutates; bd stealth init edits the
   tracked `.gitignore` — revert it (the mechanism is `.git/info/exclude`).
7. **Budgets ride with plans.** Every dispatch plan states caps (concurrent
   repos, beads/cycle, external-model quota); approval of the plan is approval
   of the caps. Bursar's ledger is the eventual source for "can we afford it."
8. **Coverage gaps are reported as gaps** — never papered over (ralph and
   orchestra emit no durable logs; pi lacks git fields; opencode-go quota is
   vendor-opaque; say so).
9. **Routing fields live in bd metadata** (`tier_floor`, `complexity`,
   `verify_cmd`), mirrored in notes-prose for cross-harness readers.

## Component registry & MVPs

Each member repo carries `.docs/ai/phases/<name>-v1-spec.md` + a seeded beads
backlog. One-line MVPs:

- **conductor** (pre-existing, 18+2 beads, cycle 1 mid-flight): one full
  scan→triage→approve→dispatch→verify cycle over the fleet.
- **warden**: guardian's policy core (77% already pure — classify/policy/state)
  extracted to a host-agnostic library + Claude Code PreToolUse adapter
  (content + handoff) + the agy interception verdict memo.
- **hindsight**: `hindsight recap --since <t>` over Claude Code + pi + Codex
  (+ guardian/agy logs) → harness-deck report. Owns the shared ingestion lib
  first. `hindsight why` is spec-only v2.
- **envoy**: the consult skill (content in-repo, installation handed off) +
  envelope conformance; live transport deferred (agent-bus is broken e2e).
- **bursar**: library + `bursar status` → JSON for Conductor. Anthropic OAuth
  usage endpoint + Codex rate_limits + agy log-grep detector; opencode-go
  reported "opaque" honestly. Deliberately the smallest member.
- **provenance**: `provenance annotate <repo>` correlating transcripts↔git
  hunks + the junior-unreviewed query. Consumes hindsight's ingestion lib —
  never forks parsers.
- **gauntlet**: 5–10 golden tasks from real transcripts, replayed in throwaway
  worktrees, Verify + fail-closed judge, A/B to harness-deck. First workload:
  evidence-backed `efficiency` ratings → **proposed patch to tiers.md handed
  to the user** (chezmoi-managed; never applied by the fleet).
- **foreman**: interview → recon greps → spec + bead-DAG script; refuses beads
  without Verify; emits "mirror X" instead of unverified prescriptions. Built
  LAST — Lead sessions do this job by hand until the pattern is proven.

## Build order

`warden core → hindsight recap → envoy skill → bursar status → provenance
annotate → gauntlet MVP → foreman` — Conductor's own backlog proceeds in
parallel throughout.

Rationale (recon-adjusted, 2026-07-01): warden first because the fleet is
dispatching *today* and its safety floor is compensating-controls-only until
warden ships (and the agy hooks question resolves). hindsight second because
every later member (provenance, gauntlet's golden-task harvest, bursar's
spend reconstruction) reads the substrate through its ingestion lib. bursar
stays fourth despite being smallest — it can float earlier any time a cycle
has spare senior capacity; nothing depends on it except Conductor's budget
refinement. foreman stays last: its product is the crystallization of what
the Lead-by-hand sessions (Conductor's, this one) prove out.

## Reading order for a fresh agent

1. `~/AGENTS.md` (the charter of law) → 2. this README → 3.
`.docs/ai/phases/ingestion-event-model.md` + `envoy-envelope.md` if your work
touches them → 4. your member repo's spec → 5. `bd prime && bd ready` there.
