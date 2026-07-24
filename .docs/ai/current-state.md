# Current State

Branch: `feat/four-tool-clean-rename` — local/unpushed.
Spec: `phases/four-tool-rename-spec.md`; Task 1 transaction harness is the active cutover gate.

## Plan

- [x] Closed job set is `work|review|consult|plan`; review keeps N-plus-one and plan is separate/bounded.
- [x] Created Conductor v2/role/plan Beads and open Bursar/Hindsight v2 chains; preserved closed v1 contracts and superseded comparison Beads.
- [x] Strict generator resume reconciliation, routing metadata, targeted lint, dependency cycles, and preflight checklist verified.
- [ ] Execute `bursar-roster-v2-contract` → v2 migrate/snapshot → Conductor run v2/role routing → native plan.

- [x] Establish seven stacked clean rename worktrees from the reviewed role-routing/main heads.
- [x] Add the canonical four-product/backlog manifest plus read-only typed preflight, snapshot, and rollback dry-run.
- [ ] Classify every stale-name candidate into an exact hashed historical file or update it before any rename mutation.
- [ ] Execute Tasks 2–12 in dependency order; no remote, HOME, state, install, or dispatch mutation before their gates.

## Blockers

- Anthropic Bursar lane remains HTTP 401 until human re-auth; no invented quota state.
- `chezmoi-personal` has unrelated dirty work; cutover stays a later targeted-reconcile tail.

## Open questions

- None architectural. Archive timing is evidence-gated by the eleven cutover checks in the spec.
