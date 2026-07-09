# Guildhall — Quickstart

> Reference orientation. For live session state, read `.docs/ai/current-state.md`
> and run `bd prime` first; this page gives the structural mental model.

## What this repository is

**Guildhall** is the charter repo for a *craft guild whose members are models* — a
suite of eight cooperating AI-coding-fleet tools that route, gate, record, audit,
budget, evaluate, and compile the work of an AI coding fleet. This repo contains
**no product code**. It is narrative architecture: the charter, the component
registry, suite-wide invariants, and the shared specifications every member
repo builds against.

Think of it as the constitution and town square for a federation of tools that
manage an autonomous AI coding fleet.

## The eight members

| Member | Guild role | What it does | Lives at |
|---|---|---|---|
| Conductor | Master of works | Cycle orchestrator: scan → triage → dispatch → verify → report | `~/git/harness-conductor` |
| Foreman | The works office | Spec-to-backlog compiler (interview → spec → bead DAG) | `~/git/foreman` |
| Gauntlet | Masterpiece trials | Eval CI for the agent stack; produces rank evidence | `~/git/gauntlet` |
| Hindsight | The inquest | Fleet flight recorder over transcript substrate | `~/git/hindsight` |
| Provenance | Hallmarks | Authorship/exposure audit: transcript ↔ git hunks | `~/git/provenance` |
| Warden | Inspecting officer | Host-agnostic policy engine (gates tool use) | `~/git/warden` |
| Bursar | The treasury | Provider quota/window ledger | `~/git/bursar` |
| Envoy | The emissary | Agent-consult primitive ("wear the repo's shoes") | `~/git/envoy` |

Each member repo carries its own `.docs/ai/phases/<name>-v1-spec.md` and a seeded
beads backlog. Guildhall is the glue layer that defines how they compose.

## Repository layout

```
guildhall/
├── README.md                  ← Charter: metaphor map, invariants, component registry
├── AGENTS.md                  ← Agent instructions (beads workflow, state locations)
├── .gitignore
├── .beads/                    ← Beads issue tracker (Dolt-backed, git-native)
│   ├── interactions.jsonl     ← Field-change event log
│   └── config.yaml            ← no-git-ops: true
└── .docs/ai/                  ← All durable state lives here
    ├── current-state.md       ← Live state + resume plan (updated every session)
    ├── roadmap.md             ← Durable goals, Now/Next/Later
    ├── decisions.md           ← Architecture Decision Records (append-only)
    ├── opus-handoff-prompt.md ← Month-long orchestration handoff prompt
    ├── spec-writer-briefing.md ← How to write a member spec + seed beads
    ├── handoff-template.md    ← Session-end handoff template
    └── phases/                ← Shared + per-phase specifications
        ├── guildhall-integration-v1-spec.md   ← How members compose; v1-done definition
        ├── orchestration-runbook.md           ← Per-bead operational loop (the how-to)
        ├── ingestion-event-model.md           ← Shared transcript parsing spec
        ├── envoy-envelope.md                  ← Consult message envelope spec
        └── 2026-07-autonomy-month-spec.md     ← Current month plan (autonomy ladder)
```

## Key principles (the non-negotiables)

1. **Substrate principle**: Artifacts on disk *are* the event bus. Members
   communicate through durable files in locations the others already read. No
   brokers, no daemons, no new IPC without a charter amendment.
2. **Exit codes are testimony; artifacts are evidence.** Every verifier judges
   by artifact (new commit, file present, log line) — never by exit code alone.
3. **Fail closed everywhere.** No Verify → no dispatch. Failed verify → bead
   stays open. Ambiguous → escalate. Unknown tool names → gated, not passed.
4. **Never push. Never `chezmoi apply`.** Anything destined for `~/.claude`,
   `~/.pi`, `~/.codex`, `~/.gemini`, or chezmoi is produced as content in-repo
   plus a pending-human handoff item.
5. **One writer per repo at a time.** Cross-repo parallelism is fine.
6. **Closed roster.** Only pre-authorized models receive work; everything else
   escalates to the human.

The full nine invariants are in [Architecture](architecture.md).

## Reading order for a fresh agent

1. `~/AGENTS.md` (the charter of law — tier routing, backlog conventions, shell landmines)
2. `.docs/ai/current-state.md` + `.docs/ai/roadmap.md`, then `bd prime`
3. This page (quickstart) for structural orientation
4. [Architecture](architecture.md) — charter, metaphor→function map, invariants, build order, integration spec
5. [Workflows](workflows.md) — orchestration runbook, autonomy month plan, shadow→cutover protocol
6. [Operations](operations.md) — state management, ADRs, beads workflow, handoff discipline
7. Your member repo's spec, then `bd prime && bd ready` there

## Where to go next

- **Understanding the system as a whole** → [Architecture](architecture.md)
- **How work gets done (the dispatch loop)** → [Workflows](workflows.md)
- **How state is tracked and decisions are recorded** → [Operations](operations.md)
- **The current month's plan** → `.docs/ai/phases/2026-07-autonomy-month-spec.md`
- **How members integrate** → `.docs/ai/phases/guildhall-integration-v1-spec.md`
