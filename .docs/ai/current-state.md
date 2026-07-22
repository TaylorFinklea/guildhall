# Current State

Branch: `feat/omp-role-aware-routing` — local/unpushed.
Spec: `phases/conductor-core-consolidation-spec.md`; strict v2 role-aware contract/backlog cutover complete.

## Plan

- [x] Closed job set is `work|review|consult|plan`; review keeps N-plus-one and plan is separate/bounded.
- [x] Created run-v2, role-routing, plan-job, and plan/review-eval Beads; superseded legacy comparison Beads.
- [x] Generator resume reconciliation, routing metadata, targeted lint, dependency cycles, and preflight checklist verified.
- [ ] Execute Bursar v2 → Conductor run v2/role routing → native plan in dependency order.

## Blockers

- Anthropic Bursar lane remains HTTP 401 until human re-auth; no invented quota state.
- `chezmoi-personal` has unrelated dirty work; cutover stays a later targeted-reconcile tail.

## Open questions

- None architectural. Archive timing is evidence-gated by the eleven cutover checks in the spec.
