# World Restoration — playable prototype

Open project.godot in Godot 4.7.2 and press F5. Emberhaven shows three region cards, local records, Highest Unlocked Region, Regions Restored, Echoes and 45 talents. Explore starts at the current frontier's local Wave 1 with permanent talents and an empty run build. Normal random cards, eight items and both bosses remain.

## Fast safe acceptance

1. In Emberhaven click **Restoration sandbox — separate test save**. The wallet must say SANDBOX. This switches to user://restoration_sandbox.json; normal progress.json is neither edited nor deleted. The sandbox persists across sessions.
2. Click 0%, 25%, 50% or 75% preview, then Explore to see the current region's stage. To return, finish the run (death) and Return to Town. Starting/restarting/closing an unfinished run gives no Restoration settlement.
3. In sandbox town, **Heal + overflow / +3000 test Echoes** completes the current frontier, gives the next one exactly 120 absolute points and adds isolated test Echoes. Its message confirms the operation. Click Explore to play the next frontier at local Wave 1; repeat to reach the marsh. This tool skips to town progress, whereas the real end-of-run transformation is exercised by tests/capture_world.gd --view=complete.
4. Open the skill tree, scroll down through all fifteen tiers per branch, buy connected nodes, inspect the next-run description, and start a run. Purchases activate on the next run. Free Reset all returns exact paid prices, without changing regions.
5. Close/reopen to check saved sandbox regions/talents. Click **Leave sandbox — return to normal save** in town to load normal progress again. Sandbox tools are hidden/rejected in release builds; no F1 values are written by these controls.

## First balance hypothesis

Restoration is not currency. At death or the wave-100 safety stop, n cleared waves grant **2*n*(n+1)** Restoration (n capped at 100): 1/5/10/12/20 cleared => 4/60/220/312/840 points. Zero cleared waves grants 2 points only after 30 active seconds, at least 3 defeats and 3 direct hits; instant exits and passive waiting grant zero. There is no separate record bonus. Two wave-12 clears restore the first region (624 points, 24 overflow); three wave-10 clears do as well. This is arithmetic, not a claim about human run pace.

Ashen Fields costs 600, Withered Grove 1400, Rotwater Marsh 2800. All are playable with the same combat geometry and local wave escalation. Their terrain is decorative: ash/grass, dead/returning trees, polluted/cleaner pools. Soil color changes continuously; clean patches, vegetation and flowers make milestones visible. Restored regions are not selectable for replay in this slice. No region-level enemy multiplier cancels permanent power. Regional enemy compositions, terrain collisions and bespoke region bosses remain future work.

Restoration settles together with Echoes, region records and a unique run ID in one atomic save. Overhang can restore several regions; excess after all three remains banked for future content. Technical bound: 1 billion banked points; writes exceeding it fail visibly instead of discarding rewards. Echoes and its existing cleared-wave curve are unchanged. Closed/crashed unfinished runs are not resumed or paid.

## Expanded tree

Existing 15 IDs, effects, prices (30/45/65/90/130), cross-links and exact refunds remain. Each branch now has fifteen tiers, with new cross-links at VII/XI. New tier VI–XV prices: 160,190,240,260,320,350,420,460,520,650. All 45 total **11790 Echoes**; no class lock or exclusive branches. Six new growth nodes per branch add 12% damage, 15% health or 4% interval reduction each. Full permanent flat bonuses: +88% damage, +110% health, 35% shorter interval; baseline damage/HP/interval settings stay unchanged.

| Branch | New special goals |
|---|---|
| Power | Cinder Memory: Kindling +25 percentage points. Giant Slayer: +25% direct boss damage. Convergence: +6% base damage per distinct Burst/Pierce/Overcharge card (up to 18%). Wildfire: Burst/Codex area damage +35%, no extra events. |
| Vitality | Bulwark: +0.2s hit protection. Living Spring: wave/Emberguard/Phoenix healing +25%. Warden Skin: 12% less incoming damage. Last Light: once per run survive a lethal hit at 1 HP with 2s protection; existing healing can follow. |
| Flow | Afterglow: Momentum +2s. Resonant Echo: Echo Scepter repeated shot +30% direct damage. Chain Current: Storm range +40%, damage +25%; same one-attempt rule. Unbound: 12% shorter cast interval while Momentum is active. |

No starter drafts or new spendable currency. Conditional powers require their existing talent/card/item to trigger; inspect descriptions before investing. Talent ownership is snapshotted at run start, as before; gear swaps cannot reset Last Light. Larger costs/powers are initial values, not approved long-term balance.

## Save compatibility and verification

Progress v3 reads v1 wallets and v2 purchases. Loading is read-only; the first successful write preserves a byte-identical .pre_world.json before migrating atomically. Old global best becomes Region 1 best; old Echoes and actual paid prices remain. Malformed/unknown saves are preserved and block writes. New fields: world.points[3], world.best[3], world.overflow, last_settlement. world_regions.gd owns rules/data, world_art.gd owns terrain, progress_store.gd owns validation/transactions, town_panel.gd owns the scrollable tree/overview, arena.gd integrates the existing run loop.

Godot 4.7.2: **1055 checks, zero failures, 15 suites** (95 new World Restoration checks, 30 extra node-layout checks). The 95 checks also passed in native D3D12. Covers real scene settlement, v1/v2 compatibility, byte-preserved migration, retry/reload idempotence, failed writes, overflow/multiple unlocks, fresh local waves/builds, all 45 purchases/reload/refunds, meaningful power growth, boss damage, actual Storm reach/damage, Phoenix healing, Kindling/Echo/Momentum and Last Light. Eleven native screenshots cover terrain stages, three biomes, town, expanded tree and controlled end-of-run completion. Tests use isolated APPDATA and -- --test-mode; none use normal saves.

Remaining: human multi-run pacing, late-wave density/performance, full natural acquisition variety, more organic biome art and distinct regional encounters. No new Windows export, video clip or GitHub push.
