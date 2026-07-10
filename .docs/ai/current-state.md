# Current State

Branch: `main` — local/unpushed. OpenWiki is reference-only; user OpenWiki WIP stays untouched.

Previous (2026-07-09 → 07-10):
- OpenWiki adopted (`c4b38bf`); demo shipped (`3fec3aa`): `demo/run.sh [all|<member>]`, 8 members, no metered dispatch.
- `gauntlet-m5` (`8c37580`), `gauntlet-nfx` (`7521a9f`, gates discriminate, lint `defective=0`), **`gauntlet-m6`** closed — gauntlet v1 complete (m3→m4→m5→m6).
- **`gauntlet-90e` closed** (`9bd1b91` minimax-m3 + `aa48729` Opus hardening): replay now captures real token cost from the pi log substrate and **fails closed** (`TokenCost::Unknown`, never `0.0`) on lanes that don't report cost. **Gauntlet backlog is empty.**

Blockers / awaiting human:
- **AWAITING HUMAN**: approve/reject `gauntlet/out/tiers-efficiency-patch.diff` (report `gauntlet/m6-efficiency-20260709`, block `tiers-efficiency-patch`). Sharp edge: gpt-5.5 `std`→`heavy` steers `L` Senior work to **Sonnet, which is unmeasured** (n=6, runs natively not via pi).
- User's uncommitted `openwiki/{_plan,operations,workflows}.md`: do not touch.
- `conductor-xa5` + shadow streak 0/3 gate cutover; roster-router/`conductor-m5` un-defer 07-10. Foreman deferred to 2026-08.

Notes:
- A controlled same-task A/B efficiency study (m6's stated method) is now mechanically possible — 90e removed the blocker. `opencode-go`/`ollama-cloud` still report `cost:0` (correctly surfaced as unknown), so minimax's own rating stays `lean (cost unconfirmed)`.

Build: gauntlet `aa48729` 138/0 + clippy; conductor `e4aeda9` 236+1 + clippy.

Resume:
1. `bd prime`. Gauntlet backlog empty. Human tail: tiers.md patch approval.
2. Roster-router chain + `conductor-m5` un-defer 07-10; `conductor-xa5` remains Lead.
3. Run `demo/run.sh` (or `demo/run.sh <member>`).
