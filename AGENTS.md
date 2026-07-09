# guildhall — Agent Instructions

Member of the **Guildhall** suite (charter: `~/git/guildhall`). Shared agent
rules live in `~/AGENTS.md` (tier routing, backlog conventions, shell
landmines) — read them first.

## Handoff

State lives in `.docs/ai/` (roadmap.md, current-state.md, decisions.md).
The spec is `.docs/ai/phases/guildhall-v1-spec.md` — read the section a bead names
before working it.

## Backlog

beads (`bd`): run `bd prime` at session start, `bd ready` for the queue.
Routing fields (tier_floor/complexity/verify_cmd) are bd METADATA, mirrored in
notes. Never `bd ready --claim` speculatively (it mutates). Suite invariants
(never push, never chezmoi, fail closed) are in the guildhall charter.

## OpenWiki

This repository has generated reference documentation in `openwiki/`.

Use it for codebase orientation and architecture lookup after the normal session
start (`~/AGENTS.md`, `.docs/ai/current-state.md`, and `bd prime`). Start here
when you need reference context:
- [OpenWiki quickstart](openwiki/quickstart.md)

OpenWiki summarizes repository overview, architecture notes, workflows, and
operations. It is not the source of truth for live state or decisions.

Live state stays in `.docs/ai/current-state.md`; durable decisions stay in
`.docs/ai/decisions.md`; backlog state stays in beads (`bd`).
