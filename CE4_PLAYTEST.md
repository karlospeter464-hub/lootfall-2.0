# CE4 — Item Discovery & Synergy Expansion

Local CE3/follow-up remains the base. The player's discovery of **Fire Fan + Piercing Flame + Overcharge** motivates this expansion. Eight fixed items share the existing Scepter/Book slots and eight-field bag. Cards, Seers, Echoes, talent ownership and save progression are unchanged.

## New items and exact interactions

| Item | Rarity / slot | Default rule |
| --- | --- | --- |
| Echo Scepter | Magic / Scepter | Every fourth regular attack schedules one central echo after 0.15 s, for 60% normal shot damage |
| Hunter's Scepter | Rare / Scepter | Repeated direct hits on each target gain +8% per additional hit, maximum +40%, expire after 3 s without another direct hit |
| Storm Grimoire | Magic / Book | First successful direct hit of each attack attempts one lightning jump to the nearest other living enemy within 150; 45% shot damage |
| Phoenix Grimoire | Rare / Book | 10 direct hits outside cooldown heal 3% maximum HP; minimum 4 s between heal attempts |

**Echo:** Counts attacks, not fan projectiles. Echo starts at the player's position when it fires, in the original main-shot direction. Its damage snapshots the normal build damage when scheduled, excluding Overcharge. Only the central projectile repeats; piercing and actual direct-hit counting work normally. Echo never schedules another Echo or consumes an Overcharge charge, but its successful hits can charge the next main shot. It shares the original attack's Storm attempt. Swapping the scepter cancels a pending echo and resets its counter. The delay is bounded below the fastest possible four-attack cycle; there is at most one pending echo. A full projectile cap may reject the extra shot; there is no backlog or guaranteed shot beyond the cap.

**Hunter:** First hit has no bonus; subsequent hits get +8/16/24/32/40%, staying capped. Each enemy has a separate weakly referenced streak. Regular and fan direct hits, including pierced targets, use the same modifier. Echo and Hunter cannot be equipped together. Overcharge multiplies with an existing Hunter bonus on its direct target. Hunter's target-specific bonus, like First Spark's conditional full-health bonus, does not spread into Burst/Codex/Storm damage. Pauses stop expiry; ordinary intermissions count as elapsed gameplay. Scepter swaps clear streaks. No persistent debuff or status framework.

**Storm:** All fan and piercing projectiles plus the associated echo share one attack context. A missed projectile does not spend the attempt. The first actual direct hit spends it even if no other enemy is in range. Lightning is indirect, has no jump recursion, cannot interrupt Seers or count toward Overcharge/Phoenix/Hunter, and respects Guardian armor through the normal indirect damage call. The triggering projectile's damage includes Overcharge if that projectile is charged. A short blue connection identifies the jump.

**Phoenix:** Direct hits from every fan shot and each distinct piercing target count. Hits during cooldown are ignored, with no stored healing or delayed automatic heal. A full-health tenth hit still consumes the attempt/cooldown. Actual healing is capped at the current effective max HP and produces a green ring and HP number. It cannot revive a defeated player. Book swaps clear the partial hit count but preserve cooldown, preventing swap abuse. Cooldown continues during ordinary unpaused run time, including while unequipped; a new run clears all counters/cooldowns. Healing does not trigger Second Wind.

**Shared direct-hit rule:** Only a positive, actual projectile collision with a living enemy emits the existing impact event. A piercing projectile excludes its already-hit body, so it cannot count the same direct collision twice. Indirect area/bolt damage never emits that event. Gear-specific projectile contexts become invalid when their corresponding slot changes, including swapping away and back; in-flight shots retain ordinary card interactions but cannot activate removed/re-equipped item effects. Changing the other slot does not erase an unchanged item's state.

## Loot quantity and rarity

Item chance is now **5% per eligible kill**, independently followed by the unchanged conditional cascade **Legendary 2% → Rare 25% → Magic 50% → Normal remainder**. Pools are uniform within a rarity:

- Normal: Ember Scepter.
- Magic: Swift Scepter, Echo Scepter, Storm Grimoire.
- Rare: Focus Grimoire, Hunter's Scepter, Phoenix Grimoire.
- Legendary: Cinder Codex, still limited to one natural drop per run; exhausted Legendary falls through to Rare.

Before Codex exhaustion, rarity shares per item remain 2/24.5/36.75/36.75%; per eligible kill they are now **0.1/1.225/1.8375/1.8375%**. Individual new Magic items have 0.6125% per kill, individual Rare items about 0.4083%. No new guarantees, salvage, levels or auto-disposal.

The following uses **fully cleared default wave budgets**, including bosses and escorts. It is a probability model, not measured typical human runs; incomplete waves can contribute additional kills. Expected items are before ground-cap suppression (16) and collection/bag constraints. One-natural-Codex does not remove the item roll: a valid lower pool remains.

| Through cleared wave | Eligible kills | Expected items at 5% | Probability of zero items |
| --- | --- | --- | --- |
| 5 | 61 | 3.05 | 4.38% |
| 10 | 173 | 8.65 | 0.014% |
| 15 | 290 | 14.50 | <0.0001% |
| 20 | 407 | 20.35 | <0.000001% |

Roughly 41% of successful item rolls belong to the four new items, with a slight increase after Codex exhaustion. This should expose new mechanics over several runs, but a particular Rare item is still uncommon in short runs. Human frequency/variety needs testing; no compensating guarantee was added.

## Champion timing and F1 compatibility

Champion **walk cooldown defaults to 2 s measured from the end of recovery**. With 0.7 s warning + up to 0.4 s rush + 0.8 s recovery, warning-start to next warning-start is normally about **3.9 s**; the arena boundary may shorten a rush. No extra hidden wait. F1 exposes cooldown, warning, rush duration and recovery. New timings apply to the next telegraph; an announced path/duration is not mutated. Cooldown changes reach the live Champion and a shorter value caps the remaining walking cooldown. Existing fixed direction, single swept contact, escort condition and dodge/recovery behavior remain.

F1 adds **13 fields** (Echo delay/damage; Hunter step/cap/expiry; Storm range/damage; Phoenix heal/cooldown; four Champion timings), for **87 numeric settings**, profile **v9**. Profiles v1–v8 validate and load without rewriting their source; new values use Inspector startup defaults. An old profile's 10% item chance is preserved numerically: **Reset defaults** selects the new 5% baseline. No item counters, attack contexts, health or currency are saved in profiles. Progress remains v2.

## Short manual tests

Fastest route: F5, **F1 → Rewards & tools → select one of all eight items → Drop selected item**, collect and equip with I. Use Reset defaults for the CE4 baseline. To stage repeatable single/group encounters, launch with isolated saves:

```powershell
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path 'C:/Users/elias/Lootfall 2.0/lootfall-2.0' -- --test-mode
```

F1 → Rewards & tools → CE4 item choice → Single/Group → **Start CE4 test**. Existing Seed-42 arrangement is reused, with one Quick, one Fan, Pierce and Overcharge, talents inactive. Single target has 2000 HP; group has six 200-HP chasers. Phoenix starts at 60% HP. Other F1 tuning/caps remain effective. No permanent build class or naturally guaranteed loot.

1. **Echo + Pierce + Overcharge:** count four regular attacks. Look for the violet-ringed central echo; fan is not repeated. Watch real echo hits build charge without consuming a ready main shot. Swap scepters while an echo is pending.
2. **Hunter + Quick/Fan + Overcharge:** hold aim on a durable target, then change targets or wait more than 3 gameplay seconds. Look for gradually higher direct-hit numbers, then the reset. Compare the normal damage shown in I with the conditional Hunter description; it is not a guaranteed global multiplier.
3. **Storm + Fan/Pierce:** aim through a group, then deliberately miss the main shot while a side shot hits. One bolt per regular attack, not per pierced target or side projectile. Compare scattered enemies beyond 150 and try Echo + Storm together.
4. **Phoenix + Fan/Pierce/Quick:** start hurt, land 10 real hits and watch one heal. Continue attacking through cooldown; it must not store another heal. Swap books away/back, pause, try near max HP and restart. Check the charge/cooldown in I and F1.
5. **Champion:** isolated jump to wave 5, remove escorts through normal play, sidestep the warning and punish recovery. Adjust timings in F1. Verify the shorter walking interval feels better and a current warning remains trustworthy.

Then play several **natural runs** and record reached/cleared wave, kills, drops found, which item sparked a new card/gear choice, and whether survival is too easy with Phoenix. The success criterion is discovered playstyles, not just the technical presence of eight items.

## Verification and limits

Run `--headless --path . --script res://tests/item_synergy_test.gd -- --test-mode` alongside the existing ten suites. CE4 covers real Echo/Pierce/Overcharge hits, target-specific Hunter stages/cap/expiry, main/side charge, shared Storm with fan/pierce/echo and range/misses, Phoenix counts/cooldown/swaps/max HP, death/reset, all new debug fixtures and pools, v8 compatibility, live Champion timing and a 256-projectile / 64-target batch. There are still at most 256 live projectiles and 512 transient visual effects; damage is computed when visual slots are full. The short scripted batch is not a sustained FPS benchmark.

No Windows export, deployment, new cards/enemies/classes/slots, item levels, affixes, crafting, currency, Seer changes or permanent unlocks. Source/docs are committed locally; no GitHub push without explicit approval. Balance and long-run performance remain human checks.
