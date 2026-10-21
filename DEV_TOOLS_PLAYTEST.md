# Habitat sanity pass & developer testing

Debug/editor only. F1 → Test tools. English game UI; no gameplay balance or schema changes.

## Fast acceptance

1. For experiments without changing normal progress, enter Restoration sandbox in Emberhaven first. Alternatively use `-- --test-mode`. The F1 hint explicitly warns which save is edited; Metrics labels NORMAL / SANDBOX / ISOLATED TEST.
2. Set Echoes to 1000, buy a talent in town, then Zero Echoes. Talent ownership and refund price remain. Add 1000; restart the game to verify the selected wallet persists.
3. From town jump to 5: starts the Champion intro, credits 4 clears (100 default Echoes, 40 Restoration). Close F1 to continue the intro.
4. Equip items/select cards, then jump to 10. Build stays; cumulative credit is 291 Echoes / 180 Restoration at defaults, rather than paying both totals. Only forward jumps are accepted, bounded by the configured cap (100 maximum). Return from the result screen/start a fresh run to test earlier waves.
5. Zero wallet during the run, die: already prepaid rewards do not reappear. Actually cleared later waves still earn their new reward at death. Result text labels DEV prepayment separately. Closing an unfinished test run keeps immediate jump credits; no run resume exists.
6. Finish current wave removes live/pending enemies without simulated kills/drops; normal card choice and live Restoration still occur. Closing F1 preserves card pause. Skipped waves do not manufacture cards/items; use the existing any-item tool and normal choices to build the test loadout.
7. Check each biome at 0/75% via capture_world.gd or sandbox previews. Marsh has five separated basins, one outline each for water/bank, no overlapping shore bounds or artificial concentric depth shapes. Reeds occupy shore groups. Grove keeps an open fighting area, grouped crown lobes and quiet shadows. Fields have sparse grass and fewer edge stones.

## Automated coverage

`tests/dev_tools_test.gd` requires `-- --test-mode`: 190 checks cover basin/bank separation and in-bounds geometry, wallet limits/investment/failing writes, native scene jumps, boss intro, preserved build, exact cumulative credit/reload, rejected back/repeat/out-of-cap jumps, origin-region overflow, zero-wallet/dedupe, final payout, real Finish current wave button and pause/card resume. Full 17 suites: 1265 checks, no failures. New suite additionally native D3D12. All test APPDATA directories are isolated under ignored .godot; real saves untouched.

## Reference sanity checks

Viewed in the browser, not imported as game assets:
- US Fish & Wildlife Service aerial wetland image: https://www.fws.gov/program/national-wetlands-inventory/gis-tools-and-resources — distinct water surfaces bounded by vegetation; adapted into separated basins with irregular, shared bank outlines.
- Top-down meadow/forest edge: https://images.unsplash.com/photo-1653203217296-5f7e8094cd6b?auto=format&fit=crop&w=1400 (discovered via https://unsplash.com/s/photos/top-down-view) — clustered crowns framing open ground, fine grass texture; adapted while retaining Lootfall's stylized angled characters.

This is stylized, traversable scenery; no water physics, collision or new terrain mechanic. Human visual judgement and dense-run performance remain unverified. Existing Windows ZIP has not been rebuilt.

## Current HP follow-up

F1 → Test tools → Current HP → Set current HP. Set 25 HP, then 1 HP, restore health; invulnerability does not block edits. Capped at effective maximum (including talents); changing maximum health in the Player tab updates the input limit. Invalid/zero values and dead/finished runs rejected. No damage/health-loss talent simulation. 197 tool checks plus 54 console and 20 live checks re-run successfully (271 total); native console screenshot inspected. Full 17-suite run above belongs to the previous package, not this follow-up.
