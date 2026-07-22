# Current State

Branch: `feat/omp-role-aware-routing` — local/unpushed.
Spec: `phases/conductor-core-consolidation-spec.md`; strict v2 role-aware contract/backlog cutover complete.

## Plan

- [x] Closed job set is `work|review|consult|plan`; review keeps N-plus-one and plan is separate/bounded.
- [x] Created Conductor v2/role/plan Beads and open Bursar/Hindsight v2 chains; preserved closed v1 contracts and superseded comparison Beads.
- [x] Strict generator resume reconciliation, routing metadata, targeted lint, dependency cycles, and preflight checklist verified.
- [ ] Execute `bursar-roster-v2-contract` → v2 migrate/snapshot → Conductor run v2/role routing → native plan.

## Blockers

- Anthropic Bursar lane remains HTTP 401 until human re-auth; no invented quota state.
- `chezmoi-personal` has unrelated dirty work; cutover stays a later targeted-reconcile tail.

## Open questions

- None architectural. Archive timing is evidence-gated by the eleven cutover checks in the spec.
