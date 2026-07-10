# Current State

Branch: `main` — local/unpushed. OpenWiki is reference-only; user OpenWiki WIP stays untouched.

Previous (2026-07-09):
- OpenWiki adopted (`c4b38bf`); `gauntlet-m5` closed (`8c37580`, 118/0 + clippy).
- Read-only demo shipped (`3fec3aa`); `gauntlet-nfx` (P1/Lead) now repairs golden-task verify commands before m6.

Blockers:
- User's uncommitted `openwiki/{_plan,operations,workflows}.md`: do not touch.
- `conductor-xa5` + shadow streak 0/3 gate cutover; roster-router/m5 re-defer 07-10. Foreman deferred to 2026-08.

Build: gauntlet `8c37580` 118/0 + clippy; conductor `e4aeda9` 236+1 + clippy, installed config/drift clean.

Resume:
1. `bd prime`; take `gauntlet-nfx`, then m6.
2. Roster-router chain + `conductor-m5` un-defer 07-10; `conductor-xa5` remains Lead.
3. Run `demo/run.sh` (or `demo/run.sh <member>`).
