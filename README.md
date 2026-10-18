# Lootfall 2.0 — The Ember Trial

Open `project.godot` in Godot 4.7 and press **F5**. Main scene: `scenes/arena.tscn`. Game UI and code are English.

## Town and permanent skill tree

The game starts in **Emberhaven**. Choose **Start Run**. Death or victory pays Echoes once, then **Return to Town** opens the city menu. **Awaken the Skill Tree** lets you spend Echoes on permanent talents before your next attempt. Town is a menu, not a walkable map.

The first region has 15 nodes: three small nodes, one notable and one key node on each of Power, Vitality and Flow. Buy a root or a node connected from **any one** of its listed predecessors. Cross-links connect Power II → Vitality III, Vitality II → Flow III and Flow II → Power III. All 15 can be active together. Default costs by tier are **30 / 45 / 65 / 90 / 130 Echoes**; the entire region costs **1080**.

| Path | Small node / notable | Key node |
| --- | --- | --- |
| Power | +4% damage each / +8% damage | **First Spark:** +35% direct-hit damage against full-health enemies; does not amplify splash |
| Vitality | +5% max HP each / +10% max HP | **Renewal:** heal 6% of effective max HP once per cleared wave, capped at full health |
| Flow | 3% shorter interval each / 5% shorter interval | **Second Wind:** after nonlethal health loss, 20% shorter attack interval for 3 seconds; refreshes without stacking |

Power and Vitality bonuses add within their paths; Power then multiplies with cards and equipment. Flow's summed reduction (capped at 60%) multiplies with cards and the Swift Scepter. Second Wind multiplies that interval temporarily; its timer stops while paused. Base HP remains a separate F1 value from the effective maximum.

Town purchases apply when **Start Run** takes a snapshot of the owned talents. **Reset all** is free and returns the **actual prices paid**, even if F1 prices changed afterward. The next run removes refunded bonuses. Purchases and refunds save wallet and talents together; failed writes change neither. Failed reward saves still block leaving the result screen until retry succeeds.

## Play

- From wave 2, **Cinder Seers** join the melee enemies: a blue diamond silhouette keeps its distance and marks a fixed ground position in pink. Leave the circle during the 1.1-second warning, or defeat the seer before its attack resolves. The position does not track you after marking. Default recovery is 2.8 seconds, impact radius 38, and damage uses the enemy damage value. Inventory/pause/freeze stop the warning. At most two seers are active; the overall default cap is now 12. Every fourth spawn from wave 2 is a seer when its cap permits; wave budgets and card events are unchanged.
- **WASD:** move. **Mouse:** aim. **Hold left mouse button:** cast fireballs. **I:** equipment. **Escape:** close the current window or pause/resume. The pause menu also has an Equipment button.
- Clear six waves by default. After waves 2 and 4, choose one of three cards. These choices remain wave-based.
- Walk over loot to put it in your **eight-field bag**. Picking up does not activate an item. **I** pauses combat and shows item descriptions, current equipment and a before/after comparison. Select a bag item and **Equip selected** to swap its matching **scepter/book** slot. Unequip returns it to the bag. Put on the ground keeps it nearby; a full bag leaves ground loot available, and a full ground cap refuses a drop without deleting your item.
- Enemies have a **2% Codex drop chance** per eligible defeat, at most one natural Codex per run. On a kill without a Codex drop, a separate **10% other-gear roll** chooses equally between the two scepters and Focus Grimoire. Uncollected loot remains between waves; the default ground cap is 16. Forced console drops can create duplicate Codices for testing; only the equipped book works.
- Four fixed test items: **Ember Scepter** adds 30% damage; **Swift Scepter** shortens the casting interval by 20%; **Focus Grimoire** adds 40% damage instead of splash; **Cinder Codex** adds splash on impact: **85-unit radius, 60% of that fireball's damage**, excluding the directly hit enemy. All effects require equipping. Damage bonuses from gear add together, then multiply card-adjusted damage; Swift multiplies the card-adjusted interval. Splash derives from the resulting fireball damage.
- Death or clearing the final wave opens the result screen and awards **Echoes for completed waves**. Default: `10 * cleared * (cleared + 1) / 2`, so clearing 1/2/3/6 waves earns 10/30/60/210 Echoes. Dying during wave 4 pays for the first three cleared waves. Entering a wave alone earns nothing.
- Echoes and best reached wave are saved at run end. Restart retains them but clears the cards, bag, equipment, ground loot, enemies, projectiles and run counters. Closing the app mid-run does not pay the unfinished run. Items are not persisted.
- Ground items show their name; full-bag feedback remains visible. Detailed effects stay in the paused inventory. Permanent items, procedural affixes, XP progression and new classes remain outside this package.
- **Destroy selected** removes a selected bag item and frees its field immediately. It produces no ground item or reward. Equipped items must be unequipped first. Put on the ground remains available; no automatic duplicate deletion is active. Rarity cascades are requested but still pending the probability basis and item-quality decision.

## F1 developer console (debug builds only)

**F1** opens/closes the console; **Escape** closes it. Gameplay pauses while it is open. Closing preserves an existing pause, upgrade choice or result screen. SpinBox fields accept keyboard entry and arrow controls; each field shows when it applies.

52 settings are split into tabs:

| Tab | Adjustable values |
| --- | --- |
| Player | Movement, maximum health, base damage, cast interval, hit protection |
| Waves | Wave limit, first-wave enemies, enemies added per wave, active enemy cap, spawn interval, safe spawn distance, intermission |
| Enemies | Base health/speed/damage, health/speed growth per wave, seer cap/warning/recovery/impact radius |
| Combat & loot | Projectile speed/lifetime/spread, all three card strengths, Codex and other-gear drop chances, pickup radius, ground cap, all four item effects |
| Rewards & tools | Echoes per cleared-wave tier; invulnerability, freeze enemies, restore HP, force a physical Codex or selected item drop, defeat active enemies, apply RNG seed |
| Skill tree | Five tier prices, small/notable bonuses for all paths, First Spark, Renewal and Second Wind values/duration |

**Application:** Player/build settings update the actual build while preserving already chosen cards. Lowering max HP clamps current health; raising it does not heal. Enemy stats affect new spawns; lowering the cap does not delete existing enemies. Wave budgets change when the next wave starts. Projectile speed/lifetime affect new shots. Codex explosion settings affect the next impact. Card strength edits update already chosen cards and the choice text when the next choice opens. The run still has exactly two choices, at waves 2 and 4. Raising the wave limit in the console is available for pressure tests, with no extra card events.

**Metrics:** FPS/approximate frame interval, static memory, run state/unpaused time/seed, reached/cleared/best wave, enemy count/cap/budget/HP, defeats, live/fired/hit projectiles, actual damage (excluding overkill), average damage per unpaused run second, health lost, effective player/build values, card counts, ground loot/drop count/Codex status, splash/drop settings, wallet, predicted payout, bag occupancy and equipped item IDs.

**Save profile / Load profile:** Balancing values are saved separately from game progress. Profiles load manually; restarting the application restores Inspector defaults until you load your profile. Loading validates every value and known key before applying any of them. Profiles do not contain currency, current health, items, RNG state or test switches.

New profiles use version 4 with 52 settings. Versions 1/2/3 (28/33/48 values) remain supported: newer fields use startup defaults with a status message. Loading leaves the source file untouched. Unknown versions, missing/unknown keys and invalid values reject the entire load. Tree effect tuning affects active talents live; ownership changes apply next run. Prices affect new purchases, not refunds. Defaults never erase owned talents or paid prices. Seer values affect new spawns; a zero seer cap disables new seers without deleting existing enemies. Old profiles can restore their previous overall enemy cap.

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
& $godotExe --headless --path . --quit-after 120 -- --test-mode
```

The test scripts require `--test-mode`, use process-specific file names and do not modify normal progress. The arena test accelerates the full run by defeating enemies programmatically; it does not validate human difficulty or game feel.

Current verification: 59 arena + 54 loot/console + 46 inventory + 69 town/tree + 19 encounter/disposal = **247 checks, no failures** on Godot 4.7.2. Four changed gameplay scripts and the new test passed Godot MCP `script_check`; two new native D3D12 previews were inspected. Earlier P2 town/tree checks also passed with native rendering and a simulated mouse purchase. These are automated checks, not human balance acceptance.

For staged engine previews:

```powershell
& $godotExe --path . --script res://tests/capture_preview.gd -- --test-mode --view=loot --output=C:/path/to/preview.png
```

Views: `encounter`, `town`, `skilltree`, `tree_tuning`, `inventory`, `loot`, `console`, `tuning`, `upgrade`, `result`; no view argument captures the arena. Town/tree previews use staged test currency and purchases; encounter stages locked warning circles. These are reproducible test arrangements, not human playthroughs.

## Manual acceptance

Play a full run; use F1 → Rewards & tools → choose an item → Drop selected item, collect it, then press I. Explain its effect before equipping; compare both books and both scepters, swap with a full bag and put an item down. Check actual equipped effects, both wave cards, death/victory payouts, new-run item reset and saved currency after restarting the app. Open F1 over equipment, an existing pause, a card choice and the result. Try a profile save/reset/load and another window size. Human readability, balance and release export remain open.

For P2: finish a run → Return to Town → buy a connected talent → Start Run and notice its effect. Close/reopen the application to confirm the purchase. Try a cross-link, all three key effects, and Reset all after editing costs in F1. Default full-tree bonuses are +20% damage, +25% max HP and 14% shorter interval plus the three key effects; difficulty and earning pace still need human playtesting.

For encounters: reach wave 2, prioritize seers or move out of their marked circles while melee enemies pursue you. Check whether this changes your target and movement choices with fewer enemies. Fill your bag, destroy an unwanted bag item and collect the waiting ground drop. Human warning readability, mixed-wave difficulty and the best long-term disposal/rarity rules remain open.

Development documentation: `C:/Users/elias/OneDrive/Dokumente/ChatGPT/Lootfall 2.0`. Game source: `C:/Users/elias/Lootfall 2.0/lootfall-2.0`.

## Local version control

This game directory is versioned separately from the development chronicle at `C:/Users/elias/OneDrive/Dokumente/ChatGPT/Lootfall 2.0`. This preserves the existing open-editor and MCP paths. Game commits include scripts, scenes, tests, project settings and the active Godot MCP Toolkit with its license. Caches, save files, machine-specific MCP settings and the inactive Godot AI addon are excluded without deleting local files.

After a tested feature, commit the selected game changes, then record that game commit in the chronicle alongside its screenshots and documentation and commit those there. No remote publishing is implied by a local commit.
