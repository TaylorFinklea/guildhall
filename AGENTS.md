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
