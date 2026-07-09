# OpenWiki Plan — Guildhall

## Repository summary
Guildhall is the **charter repo** for a "craft guild whose members are models" — eight cooperating AI-coding-fleet tools (Conductor, Warden, Hindsight, Envoy, Bursar, Provenance, Gauntlet, Foreman). This repo contains **no product code** — it holds the charter (README.md), agent instructions (AGENTS.md), shared specifications (ingestion event model, envoy envelope, integration v1 spec, orchestration runbook, autonomy month spec), architecture decision records, and living state documents (current-state, roadmap, decisions). All actual member implementations live in sibling repos (`~/git/<member>`).

## Intended wiki pages

1. **openwiki/quickstart.md** — Entry point. High-level overview, what this repo is, how it's organized, reading order, links to all section pages.
   - Sources: README.md, AGENTS.md, .docs/ai/ tree

2. **openwiki/architecture.md** — The charter as architecture: metaphor→function map, suite-wide invariants, component registry/MVPs, build order, substrate principle, integration v1 spec (seams + v1-done clause), cross-repo dependency graph.
   - Sources: README.md, .docs/ai/phases/guildhall-integration-v1-spec.md, .docs/ai/phases/ingestion-event-model.md, .docs/ai/phases/envoy-envelope.md, .docs/ai/decisions.md

3. **openwiki/workflows.md** — How work happens: the orchestration runbook loop (per-bead cycle), autonomy month plan (Phase A/B), shadow→cutover protocol, provider quota rhythms, landmines.
   - Sources: .docs/ai/phases/orchestration-runbook.md, .docs/ai/phases/2026-07-autonomy-month-spec.md, .docs/ai/opus-handoff-prompt.md

4. **openwiki/operations.md** — Operating the repo itself: state documents (current-state, roadmap, decisions), beads backlog system, handoff template, spec-writer briefing, how to start a session.
   - Sources: .docs/ai/current-state.md, .docs/ai/roadmap.md, .docs/ai/handoff-template.md, .docs/ai/spec-writer-briefing.md, .beads/

## Notes
- Repository is small (~10 files of substance). Using quickstart + 3 supporting pages. No directories needed — each page is substantial enough to stand alone.
- No existing /AGENTS.md OpenWiki section — need to add one.
- No /CLAUDE.md exists.