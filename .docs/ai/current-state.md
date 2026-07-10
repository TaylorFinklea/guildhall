# Current State

Branch: `main` — local/unpushed. OpenWiki is reference-only; user OpenWiki WIP stays untouched.

Previous (2026-07-09):
- OpenWiki adopted (`c4b38bf`); `gauntlet-m5` closed (`8c37580`, 118/0 + clippy).
- Read-only demo shipped (`3fec3aa`): `demo/run.sh [all|<member>]`, 8 members, no metered dispatch.
- `gauntlet-nfx` closed (`7521a9f`): all 6 golden-task gates now discriminate — lint `defective=0 failing=6 errored=0`, exit 0. Gates assert ≥1 passing test in a structural scope (not file existence; 3 of 4 base commits ship the deliverable as a stub). Verified at base+ref by worktree. ADR in gauntlet `decisions.md`. **`gauntlet-m6` unblocked.**

Blockers:
- User's uncommitted `openwiki/{_plan,operations,workflows}.md`: do not touch.
- `conductor-xa5` + shadow streak 0/3 gate cutover; roster-router/m5 re-defer 07-10. Foreman deferred to 2026-08.
- `gauntlet-m6` is lead-floor + L + an **expensive metered** A/B sweep; needs an explicit go-ahead on scope/spend.

Build: gauntlet `7521a9f` 118/0 + clippy; conductor `e4aeda9` 236+1 + clippy, installed config/drift clean.

Resume:
1. `bd prime`; `gauntlet-m6` is the only ready gauntlet item (decide sweep scope/spend first).
2. Roster-router chain + `conductor-m5` un-defer 07-10; `conductor-xa5` remains Lead.
3. Run `demo/run.sh` (or `demo/run.sh <member>`).
