# Game Feel & Living World — local development

Source update only. The Alpha 0.2 ZIP remains unchanged; no new release export/upload.

## Quick check

1. F5 → Emberhaven → **Restoration sandbox — separate test save**. Confirm SANDBOX; normal progress stays separate.
2. Explore Ashen Fields. Kill enemies away from the player: gold Echo diamonds remain on the ground. Within 145 units they accelerate toward you. Watch RUN ECHOES and the saved wallet. Wave end vacuums every orb, even during the paused card choice.
3. Compare the existing 0/25/50/75% sandbox previews. Wave completion grows stems, leaves, flowers, bushes and green islands over 1.2 seconds; wind animates them without collision changes. Growth continues during paused choices.
4. Fast completion demo: fresh Ashen Fields sandbox at 0%, Explore, F1 → Test tools → jump to **17** (544/600 Restoration) → **Finish current wave** → close F1. Normal wave clear adds 68 points: Fields reach 100%, 12 overflow into Grove. LIFE RETURNS, a longer chord and 1.8 seconds of unobscured landscape precede the card choice. This uses debug progress, not a naturally earned run.
5. Complete wave 2 for new cards. Check hover, Tab/arrow focus and activation. All six existing effects, random offerings, repeatability and caps remain. Context hints highlight Echo/Pierce when relevant.
6. Die, return to town, buy a connected talent, restart and close/reopen. Pickups and purchases persist. Closing/restarting secures ground Echoes; startup recovers durable credits after an interrupted process. Leave sandbox in town to load normal progress.
7. Town cards distinguish LOCKED / YOUR NEXT EXPEDITION / LIFE RESTORED; healing and Best Wave stay separate. Lanterns, hills and planted terraces animate the backdrop. Sound On/Off lasts for this session.

## Economy and saves

Completed-wave cumulative totals remain **10, 30, 60, 100, 150, 210**; wave 7 adds 25 and later increments grow by 2. Each wave's increment is divided cumulatively over its configured enemy budget. Some kills create no separate orb. Wave clear adds any remaining difference; results pay only the unpaid balance.

**Authorized rule change:** kill rewards from an unfinished wave survive death/abort. There is no XP bar; card timing, Restoration totals, talent prices, item rolls and gameplay RNG are preserved.

Cumulative earnings are written before the orb appears. Pickup atomically advances both paid ledger and wallet. Repeated claims/settlement/recovery cannot duplicate rewards. Failed writes retain pending rewards and block normal close/restart until saved. A kill whose first disk write fails cannot survive forced termination while storage is unavailable.

Progress **v5** reads v1–v4 without modifying them on load. Before first migration a permanent `.pre_living.json` snapshot is retained, plus the existing `.pre_world.json` for older formats. Paid prices, world progress and save location remain intact. Wallet limits reserve pending credits. **Old Alpha 0.2 cannot read v5** and refuses it without overwriting. Keep the backup for a deliberate downgrade; new progress is not backwards compatible. Real user saves were not used in testing.

## Implementation and checks

At most **48 merged orbs / 60 sparks**, without individual orb nodes. Four reusable voices play five synthesized WAV cues with pickup rate limiting. No external art/audio dependency. Headless tests mute the dummy audio driver; native builds play normally.

`tests/living_world_test.gd`: migration/backup, capacity, write failure/retry, repeated claims, actual startup recovery, close/death/abort, magnet, paused vacuum, 1000-drop merge, monotonic growth, WAV data, focus, card activation and completion reveal. Run the suites with isolated APPDATA under `.godot/` and `--headless --path . --script res://tests/<name> -- --test-mode`.

`tests/capture_world.gd` adds cards/orbs/rebirth views. `tests/capture_living.gd` captures 32 real viewport frames around a controlled 48→100% completion. The gallery GIF is silent and retimed. Native rendering stress: 80 frozen enemies, 48 orbs, healed terrain; median **18.31 ms**, p95 **19.59 ms**, 150 frames including VSync on Radeon RX 7600S. This rendering sample excludes moving enemy AI and disk-write bursts.

German report, screenshots and GIF: separate chronicle Progress gallery. Open: human sound/loudness acceptance, complete-run feel, extended performance and lower-spec hardware. Release/PCK audits have not been rerun against a new package because this update has not been exported.
