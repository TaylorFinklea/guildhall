# Current State

Branch: `main` — local/unpushed. OpenWiki is reference-only; user OpenWiki WIP stays untouched.

Previous (2026-07-09):
- OpenWiki adopted (`c4b38bf`); demo shipped (`3fec3aa`): `demo/run.sh [all|<member>]`, 8 members, no metered dispatch.
- `gauntlet-m5` closed (`8c37580`); `gauntlet-nfx` closed (`7521a9f`) — all 6 golden-task gates discriminate, lint `defective=0`, exit 0.
- **`gauntlet-m6` closed — gauntlet v1 complete (m3→m4→m5→m6).** Efficiency ratings derived observationally from the pi agent-log substrate (702 runs), **zero metered dispatch**. Proposed patch `gauntlet/out/tiers-efficiency-patch.diff`; `tiers.md` never written (byte-identical). Report `gauntlet/m6-efficiency-20260709` has the approval block. ADRs in gauntlet `decisions.md`.

Blockers:
- **AWAITING HUMAN**: approve/reject the tiers.md efficiency patch. Sharp edge: gpt-5.5 `std`→`heavy` steers `L` Senior work to **Sonnet, which is unmeasured** (n=6, runs natively not via pi).
- User's uncommitted `openwiki/{_plan,operations,workflows}.md`: do not touch.
- `conductor-xa5` + shadow streak 0/3 gate cutover; roster-router/`conductor-m5` un-defer 07-10. Foreman deferred to 2026-08.
- `gauntlet-90e` (P2): replay never captures token cost (`from_replay` → `0.0`); `cost:0` lanes mean *unreported*, not free. Prereq for a controlled A/B efficiency study.

Build: gauntlet 118/0 + clippy; conductor `e4aeda9` 236+1 + clippy.

Resume:
1. `bd prime`. Gauntlet ready: `gauntlet-90e` only. Human tail: the tiers.md patch approval.
2. Roster-router chain + `conductor-m5` un-defer 07-10; `conductor-xa5` remains Lead.
3. Run `demo/run.sh` (or `demo/run.sh <member>`).
