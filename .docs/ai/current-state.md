# Current State

Branch: `main` — local/unpushed. **Suite-wide adversarial review DONE 2026-07-14** (Fable + 6
Sonnet + Sol/Terra ×5 + glm-5.2 ×3). 51 beads filed across all members. Direction retargeted:
**supervised autonomy, not unattended.** ADRs: decisions.md `[2026-07-14]` ×4.

## Plan (Phase A3 — breadth-first stabilization)

- [ ] **Breadth-stabilize sweep** — work each member's `bd -C ~/git/<member> ready`, P1/P2 first.
      Verify: each bead's `verify_cmd` (mostly `cargo test`).
- [ ] **Audit pipe must be correct** — `provenance-5fu` (P0 false-attrib) · `hindsight-d96`
      (P0 unwired sources) · `guildhall-y10` (P0 pipe envelope). Verify: cargo test in each.
- [ ] **Warden shadow mode** — `warden-4ke` (wire audit sink) → `warden-wyd` (shadow "would-have")
      → `warden-gqw` (install log-only handoff). Verify: cargo test + manual smoke.
- [ ] **Supervised-autonomy track (parallel, gated)** — `conductor-1i9` (P0 linchpin: identity-
      checked success + repo lease) → `conductor-vnu`/`9uk` (resumable loop). Verify: cargo test.

## Blockers / awaiting human

- **Anthropic OAuth token for bursar is EXPIRED** (live `HTTP 401`). `bursar check anthropic`
  correctly exits 3. Re-auth to restore the lane.
- **HUMAN decisions still open** from before this review: tiers.md efficiency patch;
  `conductor-xa5` scoping; roster-router chain.
- **Do not run parallel sessions on the same repo** — a prior concurrent Opus session `git reset`
  away a commit (charter invariant 5). This is also the real-world instance of `conductor-1i9`.

## Open questions

- Provenance retention only reaches 2026-07-12 (hindsight transcript window) — but part of the
  "uncorrelated" count may be `hindsight-d96` (3 sources never wired), not just retention. Re-measure
  after `hindsight-d96` + `provenance-5fu` land.
- Warden effectiveness is TBD by design — shadow-mode logs are the evidence to decide whether it
  becomes an enforced gate later (Sol's step 2).
- Scorecard experience-log entries for this session's Sol/Terra/glm-5.2 runs: pending (see
  `~/.claude/model-scorecard.md`).
