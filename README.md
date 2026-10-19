# Lootfall 2.0 — The Ember Trial

Open `project.godot` in Godot 4.7 and press **F5**. Main scene: `scenes/arena.tscn`. Game UI and code are English.

## First external Windows playtest build

A standalone **Windows x86_64 release v0.1** is packaged locally outside Git, with CE5 gameplay frozen at `00e378d`. See [WINDOWS_PLAYTEST.md](WINDOWS_PLAYTEST.md) for the exact ZIP path, manifest, checksum, export reproduction and smoke-test limits. `export_presets.cfg` defines Windows Desktop; templates/build artifacts/test data are not committed. No new gameplay or balance changes. Source regression: 898 checks; exported-PCK regression under the test runtime: 688 checks; package audit: 6 checks, all passing. Native EXE start/F1/run/combat/death/town observed; full native progression acceptance remains open. No upload or GitHub push.

## CE5: Skill Tree Refresh & Early Progression

The three 30-Echo roots are now **Kindling** (kill → one empowered central shot), **Emberguard** (one nonlethal-hit heal per wave) and **Arcane Momentum** (four direct hits → temporary movement speed). The same fifteen IDs, connections, costs, free exact refunds and safe progress v2 are preserved. Existing root purchases receive the new effects next run, replacing their old flat stats. The refreshed tree distinguishes owned/affordable/available/locked nodes, supports arrows and shows later goals in town.

See [CE5_PLAYTEST.md](CE5_PLAYTEST.md) for rules, profile compatibility and tonight's short acceptance test. With an empty wallet, **two cleared waves pay the 30 Echoes needed for a root**; one cleared wave pays 10. There is no new first-run reward guarantee. F1 now has 92 fields; profiles v10 accept v1–v9. Older CE3/CE4 guides describe their original package; CE5 is the current tree/profile reference.

## CE4: Item Discovery & Synergy Expansion

Eight items now share the same two slots and eight-field bag. New: **Echo Scepter** (every fourth attack repeats the central shot), **Hunter's Scepter** (capped per-target direct-hit streak), **Storm Grimoire** (one lightning attempt per attack) and **Phoenix Grimoire** (10 direct hits heal, with cooldown). Default item chance is **5%**; the rarity cascade is unchanged. Champion walking cooldown defaults to **2 s after recovery**, adjustable with its other timings in F1.

See [CE4_PLAYTEST.md](CE4_PLAYTEST.md) for exact interactions, 87 F1 fields/profile v9 compatibility, repeatable item tests, and expected loot counts. Existing v8 profiles retain their old numbers; Reset defaults selects the CE4 baseline. No new cards, Seer behavior, permanent unlocks or economy changes.

## CE3: Build Discovery & Card Synergies

**Follow-up:** Ember Burst now defaults to radius **105** / **70%** damage. The Rune Champion gains a locked-direction charge after all escorts are gone. Press **I** for the expanded build overview, selected-card stacks, trigger states and item-effect comparison. See [COMBAT_POLISH_PLAYTEST.md](COMBAT_POLISH_PLAYTEST.md). Existing saved profiles retain their values; Reset defaults applies the new Burst defaults.

Each wave/boss card choice now draws up to three different valid cards from six. Ember Power, Quick Casting and Fire Fan remain repeatable within their limits. Ember Burst (direct-kill explosion), Piercing Flame (two different direct targets) and Overcharge (four direct hits charge the next main shot for +75%) can each be selected once per run. All reset on restart. No build weighting, guaranteed synergy or new permanent unlocks.

See [CE3_PLAYTEST.md](CE3_PLAYTEST.md) for exact interactions, three isolated F1 test builds, tuning and the natural three-to-five-run acceptance guide. The follow-up adds the Champion charge and build overview described in [COMBAT_POLISH_PLAYTEST.md](COMBAT_POLISH_PLAYTEST.md); Seer encounter weighting remains separate.

## Town and permanent skill tree

The game starts in **Emberhaven**. Choose **Start Run**. Death or a prototype safety stop pays Echoes once, then **Return to Town** opens the city menu. **Awaken the Skill Tree** lets you spend Echoes on permanent talents before your next attempt. Town is a menu, not a walkable map.

The first region has 15 nodes: one entry effect, two small nodes, one notable and one key node on each of Power, Vitality and Flow. Buy a root or a node connected from **any one** of its listed predecessors. Cross-links connect Power II → Vitality III, Vitality II → Flow III and Flow II → Power III. All 15 can be active together. Default costs by tier are **30 / 45 / 65 / 90 / 130 Echoes**; the entire region costs **1080**.

| Path | Small node / notable | Key node |
| --- | --- | --- |
| Power | Kindling entry; two +4% damage nodes / +8% notable | **First Spark:** +35% direct-hit damage against full-health enemies; does not amplify splash |
| Vitality | Emberguard entry; two +5% max HP nodes / +10% notable | **Renewal:** heal 6% of effective max HP once per cleared wave, capped at full health |
| Flow | Momentum entry; two 3% interval nodes / 5% notable | **Second Wind:** after nonlethal health loss, 20% shorter attack interval for 3 seconds; refreshes without stacking |

Power and Vitality bonuses add within their paths; Power then multiplies with cards and equipment. Flow's summed reduction (capped at 60%) multiplies with cards and the Swift Scepter. Second Wind multiplies that interval temporarily; its timer stops while paused. Base HP remains a separate F1 value from the effective maximum.

Town purchases apply when **Start Run** takes a snapshot of the owned talents. **Reset all** is free and returns the **actual prices paid**, even if F1 prices changed afterward. The next run removes refunded bonuses. Purchases and refunds save wallet and talents together; failed writes change neither. Failed reward saves still block leaving the result screen until retry succeeds.

## Play

- From wave 2, **Cinder Seers** join the melee enemies: a blue diamond silhouette keeps its distance and marks a fixed ground position in pink. Leave the circle during the 1.4-second warning, or defeat the seer before its attack resolves. The position does not track you after marking. Default recovery is 2.0 seconds, impact radius 38, and damage uses the enemy damage value. Inventory/pause/freeze stop the warning. At most two seers are active; the overall default cap is now 12. Every fourth spawn from wave 2 is a seer when its cap permits; later waves and recovery phases vary role cadence under the same active caps.
- **WASD:** move. **Mouse:** aim. **Hold left mouse button:** cast fireballs. **I:** equipment. **Escape:** close the current window or pause/resume. The pause menu also has an Equipment button.
- Ascend until death, with a configurable technical safety cap (default 100). Cards repeat at 2/4/5 in each five-wave block: 2, 4, 5, 7, 9, 10, etc. Wave 5/15/etc. hosts Rune Champion; 10/20/etc. hosts Ash Prophet. Boss cards draw from the same six-card pool with distinct presentation. No regular six-wave victory.
- Walk over loot to put it in your **eight-field bag**. Picking up does not activate an item. **I** pauses combat and shows item descriptions, current equipment and a before/after comparison. Select a bag item and **Equip selected** to swap its matching **scepter/book** slot. Unequip returns it to the bag. Put on the ground keeps it nearby; a full bag leaves ground loot available, and a full ground cap refuses a drop without deleting your item.
- Each eligible kill first has a **5% chance to drop an item**. A separate cascade then checks **Legendary 2% → Rare 25% → Magic 50% → Normal remainder**, stopping at the first eligible success. These are independent conditional checks, not flat shares. The item is chosen from the winning rarity pool. Ground cap 16 still applies; uncollected loot stays between waves.
- Fixed pools: **Normal — Ember Scepter** (white), **Magic — Swift Scepter, Echo Scepter, Storm Grimoire** (blue), **Rare — Focus Grimoire, Hunter's Scepter, Phoenix Grimoire** (gold), **Legendary — Cinder Codex** (orange). Inventory inspection identifies rarity in text as well as color. Effects are unchanged; these are fixed item types, not randomized quality variants.
- Before the natural Codex drops, actual shares per successful item roll are **2% / 24.5% / 36.75% / 36.75%** (L/R/M/N); at 5% item chance, chances per eligible kill are **0.1% / 1.225% / 1.8375% / 1.8375%**. The existing one-natural-Codex-per-run rule remains: an exhausted Legendary pool falls through to Rare, giving **0% / 25% / 37.5% / 37.5%** per item. Forced console drops can still bypass that limit for testing. Restart restores eligibility. Longer ascents still allow only one natural Codex per run; boss kills use the same ordinary item roll as other kills.
- Original four effects (four new CE4 effects are detailed in CE4_PLAYTEST.md): **Ember Scepter** adds 30% damage; **Swift Scepter** shortens the casting interval by 20%; **Focus Grimoire** adds 40% damage instead of splash; **Cinder Codex** adds splash on impact: **85-unit radius, 60% of that fireball's damage**, excluding the directly hit enemy. All effects require equipping. Damage bonuses from gear add together, then multiply card-adjusted damage; Swift multiplies the card-adjusted interval. Splash derives from the resulting fireball damage.
- Death or the technical safety stop opens the result and awards **Echoes for completed waves** once. Through wave 6: unchanged `10 * cleared * (cleared + 1) / 2`. Each cleared wave after 6 adds 25, then 27, 29, etc. Payouts at 10/15/20 are 322/507/742. No additional boss payout. Dying during wave 4 pays for three cleared waves; entering a wave alone earns nothing.
- Echoes and best reached wave are saved at run end. Restart retains them but clears the cards, bag, equipment, ground loot, enemies, projectiles and run counters. Closing the app mid-run does not pay the unfinished run. Items are not persisted.
- Ground items show their name; full-bag feedback remains visible. Detailed effects stay in the paused inventory. Permanent items, procedural affixes, XP progression and new classes remain outside this package.
- **Destroy selected** removes a selected bag item and frees its field immediately. It produces no ground item or reward. Equipped items must be unequipped first. Put on the ground remains available; no automatic duplicate deletion is active.

## F1 developer console (debug builds only)

**F1** opens/closes the console; **Escape** closes it. Gameplay pauses while it is open. Closing preserves an existing pause, upgrade choice or result screen. SpinBox fields accept keyboard entry and arrow controls; each field shows when it applies.

92 settings are split into tabs:

| Tab | Adjustable values |
| --- | --- |
| Player | Movement, maximum health, base damage, cast interval, hit protection |
| Waves | Safety cap, first-wave enemies/growth, normal budget ceiling, active cap, spawn interval/decay, safe spawn distance, break, HP scale/damage growth, boss HP and escort budget |
| Enemies | Base health/speed/damage, health/speed growth per wave, seer cap/warning/recovery/radius/HP/interruption; guardian first wave/cadence/cap/HP/speed/flat armor/minimum damage |
| Combat & loot | Projectile speed/lifetime/spread, existing card strengths, Burst radius/damage and Overcharge bonus, separate item chance and Legendary/Rare/Magic checks, pickup radius, ground cap, all eight item effects and their tuning |
| Rewards & tools | Early Echoes tiers, late-wave reward/growth, isolated wave jump; invulnerability, freeze enemies, restore HP, force a physical Codex or selected item drop, defeat active enemies, apply RNG seed |
| Skill tree | Five tier prices, small/notable bonuses for all paths, First Spark, Renewal and Second Wind values/duration; three entry effects (five tuning fields) |

**Application:** Player/build settings update the actual build while preserving already chosen cards. Lowering max HP clamps current health; raising it does not heal. Enemy stats affect new spawns; lowering the cap does not delete existing enemies. Wave budgets change when the next wave starts. Projectile speed/lifetime affect new shots. Codex explosion settings affect the next impact. Card strength edits update already chosen cards and the choice text when the next choice opens. Cards repeat after stages 2/4/5 of every five-wave block. Effective interval is at least 0.08 seconds, fan count at most 9; saturated cards are disabled. Live projectiles are capped at 256.

**Metrics:** FPS/approximate frame interval, static memory, run state/unpaused time/seed, reached/cleared/best wave, enemy count/cap/budget/HP, defeats, live/fired/hit projectiles, actual damage (excluding overkill), average damage per unpaused run second, health lost, effective player/build values, card counts, ground loot/drop count/Codex status, splash/drop settings, wallet, predicted payout, bag occupancy and equipped item IDs.

**Save profile / Load profile:** Balancing values are saved separately from game progress. Profiles load manually; restarting the application restores Inspector defaults until you load your profile. Loading validates every value and known key before applying any of them. Profiles do not contain currency, current health, items, RNG state or test switches.

New profiles use version 10 with 92 settings. Versions 1/2/3/4/5/6/7/8/9 (28/33/48/52/54/63/71/74/87 values) remain supported: newer fields use startup defaults with a status message. Loading leaves the source file untouched. Unknown versions, missing/unknown keys and invalid values reject the entire load. **Legacy probability numbers now use the new model:** the previous Codex chance becomes the Legendary check per item, and previous other-gear chance becomes the total item chance. The load status explicitly calls out this changed basis; old profiles do not restore the old drop algorithm. Rare/Magic use startup defaults if absent. F1 metrics show conditional-derived shares per item and chances per eligible kill, adjusted for the Codex limit.

Old numeric wave limits are preserved as safety stops; Reset defaults restores the new 100-wave ascent baseline. Tree effect tuning affects active talents live; ownership changes apply next run. Prices affect new purchases, not refunds. Defaults never erase owned talents or paid prices. Seer values affect new spawns; a zero seer cap disables new seers without deleting existing enemies. Old profiles can restore their previous overall enemy cap.

**Reset defaults:** Restores the Inspector values captured at startup and clears invulnerability/freeze. It does not refill HP, remove chosen cards or erase saved currency. Invulnerability and freeze also reset on a new run; balancing values stay until reset/reload/application restart.

**Important for testing:** These are real run controls. Test kills, forced drops, healing, invulnerability and edited rewards can affect earned/saved Echoes. Use `-- --test-mode` when you want isolated progress/profile files. Test actions are disabled by removing the console entirely in release builds; no free-form code execution is provided.

## Saved files and error handling

Normal files: `user://progress.json` and `user://balance_profile.json` in Godot's app data folder. Each replacement is written to a temporary file and read back, then the previous file is retained as `.bak`. A missing main progress file can recover from a validated backup. Invalid existing progress is preserved and not overwritten. A failed reward write shows a retry button; the run cannot silently restart and discard the pending reward. A successful payout cannot be repeated from the result screen. Closing the app while saving is failing can still lose an unpersisted reward.

Progress version 2 includes wallet, best wave and a talent-to-paid-price ledger. Old version-1 wallets load unchanged with an empty tree; the next successful save migrates them. Unknown talents, disconnected purchases, invalid prices and wallet/refund overflow are rejected. Run equipment is still never saved. Invalid progress disables Start Run and town purchases and offers Retry loading progress; repair the preserved source before retrying.

## Automated verification

From this project folder, first set `$godotExe` to your local console executable:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/test-user'
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
& $godotExe --headless --path . --script res://tests/arena_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/loot_console_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/inventory_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/town_tree_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/encounter_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/rarity_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/counterplay_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/ascent_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/card_synergy_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/combat_polish_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/item_synergy_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/early_progression_test.gd -- --test-mode
& $godotExe --headless --path . --quit-after 120 -- --test-mode
```

For parallel suites use a different APPDATA subdirectory per process to avoid MCP registry file contention. The test scripts require `--test-mode`, use process-specific file names and do not modify normal progress. The arena test accelerates the full run by defeating enemies programmatically; it does not validate human difficulty or game feel.

Current verification: 64 arena + 54 loot/console + 50 inventory + 69 town/tree + 19 encounter/disposal + 28 rarity + 74 counterplay + 249 ascent + 128 card synergy + 35 combat polish + 65 item synergy + 63 early progression = **898 checks, no failures** on Godot 4.7.2. Rarity tests include exact roll order/early exit, 0%/100% endpoints, 100,000 seeded cascade samples, real drop gates, the natural Codex limit and legacy profiles. Six CE5 gameplay/UI scripts passed Godot MCP `script_check`; four native CE5 town/tree previews were inspected. See CE5_PLAYTEST.md for current root and layout coverage. These are automated checks, not human balance acceptance.

For staged engine previews:

```powershell
& $godotExe --path . --script res://tests/capture_preview.gd -- --test-mode --view=loot --output=C:/path/to/preview.png
```

Views: `ce4_inventory`, `ce4_effects`, `followup_inventory`, `followup_inventory_effects`, `champion_charge`, `ce3_cards`, `ce3_combat`, `ce2_boss5`, `ce2_boss10`, `ce2_intro`, `ce2_reward`, `ce2_metrics`, `ce1_feedback`, `ce1`, `ce1_tools`, `rarity_loot`, `rarity_metrics`, `encounter`, `town`, `skilltree`, `tree_tuning`, `inventory`, `loot`, `console`, `tuning`, `upgrade`, `result`; no view argument captures the arena. Town/tree previews use staged test currency and purchases; encounter stages locked warning circles; rarity_loot forces all eight items. These are reproducible test arrangements, not human playthroughs.

## Manual acceptance

Play a full run; use F1 → Rewards & tools → choose an item → Drop selected item, collect it, then press I. Explain its effect before equipping; compare both books and both scepters, swap with a full bag and put an item down. Check actual equipped effects, repeated normal/boss cards, death/safety-stop payouts, new-run item reset and saved currency after restarting the app. Open F1 over equipment, an existing pause, a card choice and the result. Try a profile save/reset/load and another window size. Human readability, balance and release export remain open.

For P2: finish a run → Return to Town → buy a connected talent → Start Run and notice its effect. Close/reopen the application to confirm the purchase. Try a cross-link, all three key effects, and Reset all after editing costs in F1. Default full-tree bonuses are +20% damage, +25% max HP and 14% shorter interval plus the three key effects; difficulty and earning pace still need human playtesting.

For encounters: reach wave 2, prioritize seers or move out of their marked circles while melee enemies pursue you. Check whether this changes your target and movement choices with fewer enemies. Fill your bag, destroy an unwanted bag item and collect the waiting ground drop. Human warning readability, mixed-wave difficulty and the best long-term disposal/rarity rules remain open.

Development documentation: `C:/Users/elias/OneDrive/Dokumente/ChatGPT/Lootfall 2.0`. Game source: `C:/Users/elias/Lootfall 2.0/lootfall-2.0`.

## CE2: Ascent & Boss Milestones

See [CE2_PLAYTEST.md](CE2_PLAYTEST.md) for the wave 1–20 guide, all new formulas/values, boss interruption rule, 3/4/5-hit comparison, timing definitions and open balance questions. The target is 15–20 minutes, not a time limit or an accepted duration. No new skills, items, classes, currencies, guaranteed boss loot or permanent gear.

## CE1: Combat Counterplay (retained systems; CE2 defaults apply)

Rune Guardians first appear in wave 3, every sixth spawn candidate, with at most two alive. They replace a normal spawn and obey the total cap. A guardian has 6x wave-scaled HP, 55% movement speed and normal contact damage. Its damage taken is `max(incoming - 8, incoming * 0.2)`: one reduction per event, for direct hits and splash alike. Non-positive input deals no damage. Its broad green rune silhouette and shield outline identify the role. The shield flashes when hit. Floating numbers separate actual HP damage from absorbed damage, e.g. 6.0 and 8.0 BLOCKED on a 14-damage shot. Absorption is calculated after the minimum-damage floor, excludes overkill, and never inflates dealt-damage metrics; this is existing armor feedback, with no shield HP or recharge. All values are initial tuning, not accepted balance.

Cinder Seers now have 6x wave-scaled HP so rapid fire can interrupt them before killing them. Three direct projectile hits during the 1.4-second warning cancel that cast and begin the full 2.0-second recovery. Splash never counts. Dots and **INTERRUPT n/3** show concentration damage; **BROKEN** lasts one second after interruption. Seers prefer 210 units of distance instead of 280 and begin their first warning after 0.35 s instead of 1 s. Every new cast resets the count; death clears the cast. Warning, recovery and feedback timers respect pause/freeze. Set the hit threshold to zero to disable interruption for newly spawned seers.

Default no-talent profiles using only existing gear/cards:

| Profile | Equipment and two cards | Damage / aimed shot | Cast interval |
| --- | --- | --- | --- |
| Rapid | Swift Scepter, two Quick Casting | 14 | 0.18432 s |
| Heavy | Ember Scepter + Focus Grimoire, two Ember Power | 40.46 | 0.36 s |
| Area | Ember Scepter + Cinder Codex, two Fire Fan | 18.2; 10.92 splash | 0.36 s; three fan shots |

At wave 3 a seer now has 204 HP. In a real-projectile test spanning the new warning, Rapid interrupted once and landed seven hits (106 HP left). Swift plus only one Quick card also interrupted (six total hits, 120 HP left); Heavy and the standard 0.36-second fireball each landed four hits without interruption. This proves feasibility in the controlled arrangement, not player skill or general matchup balance.

**Try all nine matchups:** launch isolated debug play from PowerShell:

```powershell
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path 'C:/Users/elias/Lootfall 2.0/lootfall-2.0' -- --test-mode
```

Open **F1 > Rewards & tools**, select a build and Chaser group / Cinder Seer / Rune Guardian, then **Start CE1 test**. Close F1 and aim right. Repeat with the same tuning for all nine combinations, including weak matchups. Existing F1 tuning is preserved; Reset defaults first for the baseline. The arrangement restarts the isolated run, uses seed 42, stages existing items/cards, and temporarily excludes talents without changing ownership or spending Echoes. It consumes the existing wave spawn budget/caps, has no extra spawn platform, and returns to normal wave flow after the encounter. Low role/total caps and a changed first guardian wave affect the arrangement too. This test action refuses normal launches without `--test-mode`; normal manual gear drops remain available.

New **Enemies** controls: Seer HP multiplier and direct hits to interrupt; Guardian first wave, candidate cadence, cap (0/1/2), HP multiplier, speed multiplier, flat armor and minimum damage ratio. All apply to new enemies. Existing warning duration remains the interrupt window. Metrics show the effective interval and interruptions on currently active seers only. Profiles v6 preserve all prior validation and legacy defaults; progress format is unchanged.

Additional suite: `--headless --path . --script res://tests/counterplay_test.gd -- --test-mode`. Its 74 five-hit-reference checks include real player cooldown/swept-projectile interruption vs non-interruption, guardian direct/splash/floor behavior, cluster splash, pause/freeze/death/restart, role/global caps, all nine arrangements and v5/v6 profiles. Six gameplay scripts passed MCP script checks; native D3D12 CE1 encounter/tools previews were inspected.

Playtest questions: Does breaking concentration feel intentional? Can slow fire win by killing or dodging? Is guardian armor readable without feeling immune? Does Area gain a clear advantage on groups? Does one build dominate every encounter? No human matchup acceptance, export or long-session balance test yet. No salvage Echoes, item levels, new player stats, new gear or reward/persistence changes in CE1.

## Local version control

Public GitHub repositories, explicitly authorized by the owner on 2026-10-18: [game](https://github.com/karlospeter464-hub/lootfall-2.0) and [development chronicle](https://github.com/karlospeter464-hub/lootfall-2.0-devlog). The local game and chronicle remain separate repositories. Machine-specific settings, credentials, caches and real save files stay excluded. Publishing a future change still requires the applicable user authorization.

This game directory is versioned separately from the development chronicle at `C:/Users/elias/OneDrive/Dokumente/ChatGPT/Lootfall 2.0`. This preserves the existing open-editor and MCP paths. Game commits include scripts, scenes, tests, project settings and the active Godot MCP Toolkit with its license. Caches, save files, machine-specific MCP settings and the inactive Godot AI addon are excluded without deleting local files.

After a tested feature, commit the selected game changes, then record that game commit in the chronicle alongside its screenshots and documentation and commit those there. No remote publishing is implied by a local commit.
