# Operations — State, ADRs, Backlog, and Handoffs

This page covers how Guildhall tracks state, records decisions, manages backlogs, and hands off work between sessions and models.

## Where state lives

All AI-facing state lives under `.docs/ai/` in the guildhall repo itself:

| File | Purpose | Update frequency |
|---|---|---|
| `.docs/ai/current-state.md` | Live snapshot: active branch, last session summary, build status, blockers, resume plan. Read this first. | End of every work session |
| `.docs/ai/roadmap.md` | Durable goals and milestones, organized as Now / Next / Later. | When scope changes (not every session) |
| `.docs/ai/decisions.md` | Architecture Decision Records (ADRs). Append-only, one entry per decision. | When a non-obvious design or product call is made |
| `.docs/ai/handoff-template.md` | Template for session-end handoff entries (session summary, files changed, test status, blockers, decisions, artifacts). | Per session (optional; current-state.md is primary) |
| `.docs/ai/spec-writer-briefing.md` | Instructions for writing a per-member v1 spec and seeding its beads backlog. | Reference (rarely changes) |
| `.docs/ai/opus-handoff-prompt.md` | The master prompt handed to Opus as month-long orchestrator. | Per month / major handoff |
| `.docs/ai/phases/*.md` | Phase specs and operational runbooks (see below). | As needed |

### Phase specs (`.docs/ai/phases/`)

These are the charter-level specs that every member builds against:

- **`ingestion-event-model.md`** — normalized event model for all transcript/observability sources (Claude Code, pi, Codex, agy, guardian, harness-deck, beads, model-bench). Defines the canonical JSON record shape, correlation keys, and coverage-gap ledger. First implementation lives in hindsight; provenance extracts, never forks.
- **`envoy-envelope.md`** — the `guildhall/envoy@1` message envelope for agent-to-agent consults (question/answer/notice). v1 transport is a file on disk + in-process dispatch; live transport deferred.
- **`guildhall-integration-v1-spec.md`** — the suite-level integration spec: how the members compose into one working system, the v1 vertical-slice proof, the cross-repo dependency graph (bd has no cross-repo primitive), and the definition of "v1 done."
- **`orchestration-runbook.md`** — the distilled per-bead operational loop (pick → claim → dispatch → verify → close → log → report), budget caps, provider-limit reality, human-verify tails, and bd-encoded sequencing gates.
- **`2026-07-autonomy-month-spec.md`** — the month plan: Phase A (close v1) → Phase B (autonomy ladder + shadow→cutover), routing rules, provider quota calendar, landmines, month-end definition of done.

## Architecture Decision Records (ADRs)

`.docs/ai/decisions.md` is append-only. Key ADRs a fresh agent must know:

| Date | Decision | Why it matters |
|---|---|---|
| 2026-07-01 | Substrate principle: artifacts on disk are the event bus | No broker/daemon. Members communicate via durable files in locations the others already read. New IPC requires a charter amendment. |
| 2026-07-01 | Ingestion lives in hindsight first; provenance extracts, never forks | Two divergent parsers would disagree about ground truth — fatal for an audit tool. |
| 2026-07-01 | Exit codes are testimony; artifacts are evidence | Every verifier judges by artifact (new commit, file present, log line), never by exit code alone. agy exits 0 on quota no-ops. |
| 2026-07-01 | Warden gates unknown tools (reverses guardian's pass-through) | Unknown tool names default to gated path; host adapters may register known-safe maps. |
| 2026-07-01 | Build order: warden → hindsight → envoy → bursar → provenance → gauntlet → foreman | Fleet dispatches today with compensating-controls-only safety → warden first; everything downstream reads the substrate → hindsight second. |
| 2026-07-02 | Warden live enforcement covers Claude Code only; pi/agy = compensating controls | Honest floor over pretended coverage. pi/agy inner tool loops can't be live-gated. |
| 2026-07-02 | conductor-review gates Conductor v1 | Tiered qualitative review (equal-or-higher-tier reviewer after mechanical verify) is mandatory, not optional, for v1. |
| 2026-07-03 | Month focus: autonomy ladder leads | v1 close → ratchet → triage-suggest → shadow → cutover. Measurement/enforcement/breadth explicitly out of scope for the month. |
| 2026-07-03 | Autonomy posture: junior/S config default, spec ceiling unchanged | Mechanism/policy split — build the general ratchet, start the policy narrow, let trust widen it via human config change. |
| 2026-07-03 | Cutover: shadow-first, evidence-gated | 3 consecutive matching sessions (conductor dry-run vs actual routing) before cutting over. Mismatches = bug backlog. |
| 2026-07-03 | Claude-spend: strict reserve + structurally-Claude carve-out | Claude = orchestration/verify (Opus), lead-floor beads (Sonnet), adversarial review, and structurally-Claude beads only. Fleet-eligible senior work waits for fleet resets. |
| 2026-07-07 | Queue hygiene as cutover precondition | The ready queue must encode the plan; mismatched or stale queues block the shadow protocol. |

See `decisions.md` for the full text and rationale of each ADR.

## Beads (bd) — AI-native issue tracking

Each guild member repo (and guildhall itself) uses [Beads](https://github.com/steveyegge/beads) (`bd`) for issue tracking. The `.beads/` directory in each repo is a Dolt-embedded database; `bd` is the CLI interface.

### Key commands and conventions

- `bd prime` — run at session start (re-run after context compaction).
- `bd -C ~/git/<member> ready` — view the ready queue (optionally `--json`).
- `bd -C <repo> --actor <model> update <id> --claim < /dev/null` — claim a bead. **Never run `bd ready --claim` speculatively** — it mutates.
- `bd -C <repo> close <id> --reason "<evidence>"` — close with evidence-dense reasons (commit hash + verify output).
- `bd -C <repo> update <id> --status open --assignee ""` — release a bead (after worker death/limit).
- `bd list --all` — `bd list` silently omits closed beads; use `--all`.
- `bd memories landmine` / `bd memories month` — tactical landmines and month-level memories stored in the guild bd.

### Routing metadata

Every bead carries routing metadata in BOTH bd metadata and notes-prose (for cross-harness readers):

- `tier_floor` — lead / senior / junior. Hard ownership gate (see [Architecture: Invariants](architecture.md#invariants)).
- `complexity` — S / M / L / XL.
- `verify_cmd` — a runnable shell command; no verify_cmd → no bead. Human-verify tails go in notes.
- `spec` — section reference (e.g. `§ M3`).

Cross-repo dependencies are prose-only (bd has no cross-repo primitive); the graph lives in `guildhall-integration-v1-spec.md`. Within-repo gates ARE encoded in bd (`bd dep add`).

### Bead creation recipe (spec-writer briefing)

See `.docs/ai/spec-writer-briefing.md` for the exact `bd create` recipe, including metadata JSON shape, acceptance criteria, and the 5–10 bead MVP guideline.

## Session handoff

At the end of every work session, update `.docs/ai/current-state.md`:

1. **Active branch** (every member repo; all local, nothing pushed).
2. **Last session summary** — date, what was done, build status, blockers.
3. **Resume plan** — numbered steps for the next session.

The handoff template (`.docs/ai/handoff-template.md`) provides a structured form. ADRs are appended to `decisions.md` when non-obvious design or product decisions are made. Roadmap checkboxes in `roadmap.md` are updated when scope changes.

## Pending-human handoffs

The fleet never pushes, never applies chezmoi, and never writes into `~/.claude`, `~/.pi`, `~/.codex`, `~/.gemini`, or chezmoi-config. Anything destined for those locations is produced as content in-repo plus a **pending-human handoff item**.

Historical pending-human snapshot from 2026-07-08, kept as an example of the
handoff shape. For the current list, read `.docs/ai/current-state.md`,
`.docs/ai/roadmap.md`, and beads:

- Guildhall-dogfood dashboard eyeball → human closes `conductor-guildhall-dogfood`.
- `conductor-m3b` live render.
- `hindsight-m3` eyeball.
- Bursar seven_day Keychain smoke.
- Rotate the plaintext claude.ai session-key in `~/.claude/fetch-claude-usage.swift`.
- Envoy/warden/gauntlet chezmoi installs + tiers.md efficiency patch.
- Drop 2 superseded stashes (provenance-m2, hindsight-m2 — classifier blocks agent stash-drop).
- Install warden-m4's adapter (see warden docs/HANDOFF-install.md).
- Confirm/deny `conductor-frv` (gpt-5.5 ceiling M→L — evidence: 2 verified L closes).
