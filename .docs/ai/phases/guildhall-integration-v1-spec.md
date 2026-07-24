# Guildhall integration — v1 spec

**Status**: architecture spec (Fable 5, 2026-07-02). Fills the gaps found reviewing the per-member specs, which were written in isolation. This is the document that says how the members compose into one working system and what "Guildhall v1 is done" means. Opus owns execution against it.

## Why this exists (the gap it closes)

Each member repo got a solid v1 spec + backlog. But no document described the **seams** — how the members talk to each other — or a suite-level **definition of done**. A reader could finish every member's backlog and still not know whether "Guildhall works." This spec is that missing layer.

## The v1 vertical slice (the integration proof)

Guildhall v1 is proven when this single flow runs end to end, mostly dry-run/read-only:

1. **Undertake** scans `~/git`, finds the beads-tracked repos (including the seven Guildhall members + itself), triages their ready beads using the real `tier_floor`/`complexity` metadata, and publishes a cycle plan to harness-deck. *(bead: `undertake-guildhall-dogfood`)*
2. **Musterroll** answers "can we afford it": `musterroll status --json` feeds Undertake's budgeting so near-exhausted/opaque provider windows defer external dispatch. *(bead: `undertake-musterroll` consumes `musterroll-m4-cli`)*
3. On approval, Undertake dispatches a bead. The spawned worker's safety floor is **compensating controls** (worktree isolation, verify-by-artifact, quota caps), because **Cautionlight cannot live-gate pi/agy inner tool loops** — Cautionlight's live enforcement covers the Claude Code surface only. *(beads: `cautionlight-m6-dispatch-surface-coverage`, `undertake-cautionlight`)*
4. **Afterfact** later reconstructs what happened from the transcript substrate (`afterfact recap --since`) and publishes a report; coverage gaps are reported as gaps.
5. **Provenance** annotates which model authored which surviving hunks, consuming Afterfact's ingestion lib (never forking parsers).
6. **Gauntlet** replays golden tasks to produce evidence-backed `efficiency` ratings — a proposed patch to `tiers.md`, handed to the human.
7. **Foreman** (built last) crystallizes the by-hand spec→backlog compilation this whole effort demonstrated.

**v1 "done" = steps 1–2 provably work end to end (the dry-run cycle + musterroll budget), Undertake's tiered qualitative-review stage ships and gates closes (`undertake-review` — user decision 2026-07-02, see decisions.md), and every member has reached its own spec's final milestone with verify passing.** Steps 3–7 are each member's own v1; the *integration* is proven by the Undertake dry-run over the real fleet (`undertake-guildhall-dogfood`).

## Cross-repo dependency graph (bd has no cross-repo deps — this is the map)

Within a repo, `bd` deps sequence the work. Across repos, these edges live only here in prose — Opus must honor them manually:

- `provenance` M4/M5 (correlate/annotate) ← **needs** `afterfact` ingestion lib extracted (parsers are pulled from Afterfact, never forked). `provenance-seam` is the negotiation bead; do it right after `afterfact` M2 parsers land.
- `undertake-musterroll` ← **needs** `musterroll-m4-cli` shipping `musterroll status --json` (the `musterroll/status@1` contract).
- `undertake-cautionlight` ← **needs** `cautionlight` core lib (m1/m2/m3) + `cautionlight-m6` coverage doc.
- `undertake-guildhall-dogfood` ← **needs** `undertake-m3b` (dry-run cycle) + the Guildhall repos having seeded backlogs (they do).
- `gauntlet-m3` (golden-task harvest) ← **benefits from** the rich real transcript data + `~/.claude/model-bench.jsonl` (~20 dispatch rows) this session generated. Point the harvester at `~/.claude/projects/` and the bench ledger.
- `cautionlight-m4` (Claude Code adapter) is **content + handoff** — installation into `~/.claude` is chezmoi territory (human applies).
- `envoy` skill installation + `gauntlet` tiers.md patch + `cautionlight` hook install are all **pending-human handoffs**, never applied by the fleet.

## Build order (unchanged, recon-confirmed)

`cautionlight → afterfact → envoy → musterroll → provenance → gauntlet → foreman`, Undertake's own M3–M6 in parallel. Musterroll floats earlier when a slot is free. Rationale in `decisions.md`.

## Gaps found + where each is addressed (Fable review 2026-07-02)

| Gap | Resolution |
|---|---|
| Afterfact `harness_deck.rs` + `beads.rs` sources specced but unbudgeted | bead `afterfact-m5-hd-beads-sources` (p3 — completeness, below recap) |
| Cautionlight gates only 1 of ~4 dispatch surfaces (pi/agy ungated) | bead `cautionlight-m6-dispatch-surface-coverage` + ADR below |
| No integration/vertical-slice proof | this spec + bead `undertake-guildhall-dogfood` |
| Cautionlight had no consumer wired | bead `undertake-cautionlight` (v1.5) + this spec |
| No suite-level "done" definition | the v1-done clause above |
| No cross-repo dependency map | the graph above |

## Non-goals (v1)

Live inter-member IPC beyond files (substrate principle); Envoy live transport; `afterfact why`; Cautionlight live-gating of pi/agy (compensating controls only — see ADR); a running Undertake daemon (manual `undertake cycle`).
