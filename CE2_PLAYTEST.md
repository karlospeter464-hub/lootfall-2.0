# CE2 — Ascent & Boss Milestones: manual playtest

This is a test guide, not a record of completed human playtests. The target is roughly 15–20 minutes per typical run, not a countdown. Strong builds may survive longer. Start each normal attempt at wave 1.

## Launch and baseline

Open `C:/Users/elias/Lootfall 2.0/lootfall-2.0/project.godot` in Godot and press F5. For isolated progress and debug wave jumps, launch instead:

```powershell
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path 'C:/Users/elias/Lootfall 2.0/lootfall-2.0' -- --test-mode
```

F1 → Reset defaults restores the new ascent settings; old profiles keep their saved wave cap and interruption threshold. Do not use invulnerability, test kills or wave jumps when assessing real difficulty. Use them only for the focused checks below. They reset on run restart. Profiles v7 accept v1–v6 without rewriting their files. A saved six-wave limit is now a safety stop, not a victory.

## Natural run, waves 1–20

| Waves | What to observe |
| --- | --- |
| 1–4 | Learn the existing items, take cards at 2 and 4. Seer interruption defaults to three direct hits; splash does not count. |
| 5 | Two-second Rune Champion announcement, gold health bar, capped escort. Defeat everyone to receive a boss card. Boss death alone must not finish the wave. |
| 6–9 | Wave 6 continues rather than winning. Recovery after the boss, then rising pressure; normal cards at 7 and 9. |
| 10 | Ash Prophet with a larger readable warning. Interrupt one cast, then dodge the next STEADY CAST. Defeat the entire encounter for the boss card. |
| 11–14 | Brief recovery at 11, then another climb. Normal cards at 12 and 14. Notice role composition and spawn pace rather than just longer queues. |
| 15 | Rune Champion returns at higher strength; boss card afterward. |
| 16–19 | Recovery at 16; cards at 17 and 19. Check saturated card labels rather than spending a choice on a capped effect. |
| 20+ | Ash Prophet returns; boss card at 20 and continued ascent afterward. There is no regular victory. |

On death inspect the result and **F1 → Metrics before Return to Town**. Wall time includes card choices, inventory, Escape pause and F1; active time excludes pauses. Wave combat time excludes announcements and breaks. The last five completed waves show combat seconds, HP lost and C/S/G/B composition. Wave records are temporary and reset with the run. If F1 was open for a long time, record that when assessing duration.

Default payouts for 6/10/15/20 cleared waves: **210 / 322 / 507 / 742 Echoes**. Merely reaching a wave pays nothing. No extra boss currency, guaranteed boss loot or salvage reward. Return to Emberhaven, invest in existing talents, then Start Run and check that cards/equipment reset and wave 1 begins again. The existing full tree costs 1080 Echoes, so its completion pace against longer runs needs a human balance review.

## Focused isolated checks

- F1 → Rewards & tools → Jump to wave (isolated): test 5, 10, 15 and 20. This deliberately resets the test run; it does not grant the cards or Echoes of skipped waves. Use existing item drops, healing or invulnerability for inspection. Close F1 to advance the announcement.
- During an announcement and a boss fight, try Escape, I and F1. Warning, spawning and combat clocks must stop; closing should restore the previous state.
- Set the total enemy cap to 1: the boss must spawn, escorts must wait without being lost, and the encounter must remain completable. Role caps configure escorts; a required boss still spawns even if its normal role cap is zero.
- Set the safety cap to 6 and complete wave 6: expect PROTOTYPE LIMIT REACHED and normal one-time settlement, never a victory. Restore defaults afterward.
- Use the CE1 build selector against a normal seer, with thresholds 3, 4 and 5; restart each arrangement after changing the threshold so new enemies receive it. Keep other tuning and aim consistent.

The controlled projectile test found Rapid, Heavy and Area all interrupted at 3 and 4; at 5 only Rapid did. Four is timing-sensitive and not a promised cutoff in natural play. Three therefore weakens the original soft-counter distinction. The boss's alternating protected cast prevents indefinite interruption regardless of rate. No new player stat was added to compensate.

## Initial tuning and safety limits

- Normal budget: `min(28, ceil((8 + 4*(wave-1)) * recovery))`, at least one enemy. Recovery is 0.8 on waves 6/11/16/etc.
- HP: `(28 + 3*(min(wave,6)-1)) * 1.14^max(0,wave-6) * recovery`. Guardian and seer keep their 6x HP multipliers.
- Damage: `14 * 1.04^(wave-1) * recovery`. Speed grows from 85 by 5/wave, capped at 200.
- Spawn interval: `max(0.18, 0.65 * 0.97^(wave-1) / recovery)`.
- Role candidates become more frequent each ten-wave block; recovery waves space them out. Existing role caps and the global cap 12 remain.
- Boss budget: boss + four escorts. Champion adds 6x role HP; Prophet adds 9x. Boss damage is 1.5x normal wave-scaled damage. After a boss, the break is doubled.
- Prototype safety cap 100; HP at most 1,000,000 and damage at most 200. No overflow or unbounded enemy queue.
- Effective casting interval at least 0.08 seconds, at most nine projectiles per cast and 256 live projectiles. Cards at their limit are disabled; Power remains selectable. These are technical safety bounds, not final progression design.
- F1 has 71 values. New fields: HP scale, damage growth, normal budget ceiling, spawn decay, boss HP multiplier, boss escort count and the two late-wave Echoes parameters.

## Record each real attempt

| Build / talents | Wall minutes (note long pauses) | Reached / cleared | Hardest wave and roles | Normal / boss combat seconds | Death cause | Echoes | New decision or mostly extra HP? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | |

The next design decision depends on these observations. Automated survival, test kills and staged screenshots do not establish duration, fairness, performance under long human play, or fun.
