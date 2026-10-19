# CE3 follow-up — Combat polish & build overview

This follows the local CE3 build. Six cards, card timing, Seer balance, loot, Echoes, permanent talents and save formats remain unchanged. Human playtesting found CE3 fun; this package's new balance and readability still need acceptance.

## Ember Burst

Default radius **105** and damage **70% of the triggering projectile**, including Power, equipped damage bonuses and Overcharge. First Spark remains a direct-hit-only conditional bonus. F1 still exposes Burst radius and damage ratio. Existing saved v8 profiles keep their saved numbers; **Reset defaults** restores these new defaults. No profile migration or silent rewrite.

A short orange disk and strong rim immediately mark the full radius; nearby hit enemies use their existing damage flash/numbers. Indirect kills cannot trigger more Bursts, each direct victim triggers at most once, and the 512-effect visual ceiling still applies without dropping damage.

Try **F1 → Rewards & tools → Burst + Power + Ember → Start CE3 test** in an isolated `-- --test-mode` launch (see CE3_PLAYTEST.md). Aim at a low-health enemy near allies, then compare against a spread group. Check whether the larger area is useful and visually clear without washing out enemy warnings.

## Rune Champion

Only Champions at waves **5, 15, 25, ...** receive the ability; regular Guardians keep their original armor, chase and contact behavior. The ability becomes eligible when **all living escorts and pending escort spawns are gone**.

1. **Warning — 0.7 s:** stop, lock direction toward the player's current position, show the path and CHARGE label.
2. **Rush — up to 0.4 s:** move along that fixed path at **850 units/s** (maximum 340 units), stopping at the arena boundary with the scaled body inside it. No retargeting or sliding along a wall. Swept contact checks prevent skipped hits; at most one contact attempt per rush, using existing damage and player hit protection.
3. **Recovery — 0.8 s:** stationary and damageable, existing armor retained. No contact damage during warning/recovery.
4. **Walk — 3 s cooldown after recovery:** resume slow chase before another warning can begin.

Pause and freeze preserve timers and position; death prevents further processing. Five `charge_*` exports on `guardian_enemy.gd` expose the local timings/speed in Godot's Inspector, including the spawned Champion's Remote Inspector. They are not added to saved F1 profiles in this iteration. There is no new boss framework or phase reward.

Try a natural wave 5, or the existing isolated F1 wave jump. Kill escorts first, hold position until the warning, then sidestep and punish recovery. Also try running backward and fighting near corners. Check warning readability, whether solo kiting remains too easy, and whether 850 speed / 340 range feels useful and fair. The technical test proves the phase works and is avoidable, not that it is exciting.

## Inventory / build overview

Press **I**. The single paused window now has:

- **Left:** pinned Scepter/Book slots and eight bag fields; scrollable selected-item details and comparison; existing Equip/Unequip/Drop/Destroy actions in the footer.
- **Right:** actual direct damage, effective cast interval including current Second Wind, projectiles, current/max HP, and Codex splash damage/radius. READY additionally shows the next main shot's damage. No theoretical DPS is shown.
- **Below the stats:** scrollable selected cards with stack counts and current rules, followed by gear effects, Overcharge charge, temporary buffs and conditional talent triggers. Available talents are distinguished from triggered effects. First Spark is explicitly conditional on full-health targets.

Select **Cinder Codex** while **Focus Grimoire** is equipped: compare lower direct damage, splash OFF → ON, gained Codex effect and lost Focus effect. The comparison also previews Burst and charged-main-shot damage when those cards are selected. Cards/talents remain active through gear swaps. Calculations reuse `build_for`, the same charged/Burst helpers used by combat, and the player's actual haste calculation.

Scroll with the mouse wheel or focus either scroll area with Tab and use arrows. Equipment/bag and footer stay visible. Check all six cards, full bag, a key talent and an active Second Wind. Equip, unequip, drop, destroy, open F1, resume, die and start another run; confirm state, focus, cards, gear and currency behave as before. UI is checked at the existing 1280×800 logical resolution (native preview 1152×720); other resolutions remain a manual check.

## Technical checks and scope

Run `--headless --path . --script res://tests/combat_polish_test.gd -- --test-mode` alongside the existing nine suites. The 35 new checks cover Burst boundaries/feedback, pending/live escorts, locked rush, later Champions, pause/freeze, armor/recovery, swept single contact, arena edges, regular Guardians, actual overview values, stacks, effect comparisons, charge, temporary buffs, scrolling and reset. Updated CE3 tests retain non-recursion, synergy and stress checks under the new Burst defaults.

Save progression stays v2; F1 profiles stay v8 with 74 fields and legacy support. No new cards, items, enemies, classes, currencies, talent trees or slots. No Seer tuning, hit-based shields, loot or reward changes. Source/docs are committed locally; a GitHub push requires a separate explicit approval.
