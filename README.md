# Lootfall 2.0 — The Ember Trial

Open `project.godot` in Godot 4.7 and press **F5**. Main scene: `scenes/arena.tscn`. Game UI and code are English.

## Play

- **WASD:** move. **Mouse:** aim. **Hold left mouse button:** cast fireballs. **I:** equipment. **Escape:** close the current window or pause/resume. The pause menu also has an Equipment button.
- Clear six waves by default. After waves 2 and 4, choose one of three cards. These choices remain wave-based.
- Walk over loot to put it in your **eight-field bag**. Picking up does not activate an item. **I** pauses combat and shows item descriptions, current equipment and a before/after comparison. Select a bag item and **Equip selected** to swap its matching **scepter/book** slot. Unequip returns it to the bag. Put on the ground keeps it nearby; a full bag leaves ground loot available, and a full ground cap refuses a drop without deleting your item.
- Enemies have a **2% Codex drop chance** per eligible defeat, at most one natural Codex per run. On a kill without a Codex drop, a separate **10% other-gear roll** chooses equally between the two scepters and Focus Grimoire. Uncollected loot remains between waves; the default ground cap is 16. Forced console drops can create duplicate Codices for testing; only the equipped book works.
- Four fixed test items: **Ember Scepter** adds 30% damage; **Swift Scepter** shortens the casting interval by 20%; **Focus Grimoire** adds 40% damage instead of splash; **Cinder Codex** adds splash on impact: **85-unit radius, 60% of that fireball's damage**, excluding the directly hit enemy. All effects require equipping. Damage bonuses from gear add together, then multiply card-adjusted damage; Swift multiplies the card-adjusted interval. Splash derives from the resulting fireball damage.
- Death or clearing the final wave opens the result screen and awards **Echoes for completed waves**. Default: `10 * cleared * (cleared + 1) / 2`, so clearing 1/2/3/6 waves earns 10/30/60/210 Echoes. Dying during wave 4 pays for the first three cleared waves. Entering a wave alone earns nothing.
- Echoes and best reached wave are saved at run end. Restart retains them but clears the cards, bag, equipment, ground loot, enemies, projectiles and run counters. Closing the app mid-run does not pay the unfinished run. Items are not persisted.
- Echoes are currently banked; the Hideout and spending/unlocks are a later package. Permanent items, procedural affixes, XP progression and new enemy classes remain outside this package.

## F1 developer console (debug builds only)

**F1** opens/closes the console; **Escape** closes it. Gameplay pauses while it is open. Closing preserves an existing pause, upgrade choice or result screen. SpinBox fields accept keyboard entry and arrow controls; each field shows when it applies.

33 settings are split into tabs:

| Tab | Adjustable values |
| --- | --- |
| Player | Movement, maximum health, base damage, cast interval, hit protection |
| Waves | Wave limit, first-wave enemies, enemies added per wave, active enemy cap, spawn interval, safe spawn distance, intermission |
| Enemies | Base health/speed/damage, health/speed growth per wave |
| Combat & loot | Projectile speed/lifetime/spread, all three card strengths, Codex and other-gear drop chances, pickup radius, ground cap, all four item effects |
| Rewards & tools | Echoes per cleared-wave tier; invulnerability, freeze enemies, restore HP, force a physical Codex or selected item drop, defeat active enemies, apply RNG seed |

**Application:** Player/build settings update the actual build while preserving already chosen cards. Lowering max HP clamps current health; raising it does not heal. Enemy stats affect new spawns; lowering the cap does not delete existing enemies. Wave budgets change when the next wave starts. Projectile speed/lifetime affect new shots. Codex explosion settings affect the next impact. Card strength edits update already chosen cards and the choice text when the next choice opens. The run still has exactly two choices, at waves 2 and 4. Raising the wave limit in the console is available for pressure tests, with no extra card events.

**Metrics:** FPS/approximate frame interval, static memory, run state/unpaused time/seed, reached/cleared/best wave, enemy count/cap/budget/HP, defeats, live/fired/hit projectiles, actual damage (excluding overkill), average damage per unpaused run second, health lost, effective player/build values, card counts, ground loot/drop count/Codex status, splash/drop settings, wallet, predicted payout, bag occupancy and equipped item IDs.

**Save profile / Load profile:** Balancing values are saved separately from game progress. Profiles load manually; restarting the application restores Inspector defaults until you load your profile. Loading validates every value and known key before applying any of them. Profiles do not contain currency, current health, items, RNG state or test switches.

New profiles use version 2 with 33 settings. Existing version-1 profiles with all 28 original settings remain supported: the five new item settings use startup defaults, with a visible status message. Loading leaves the old file untouched; saving writes version 2. Unknown versions, missing/unknown keys and invalid values reject the entire load.

**Reset defaults:** Restores the Inspector values captured at startup and clears invulnerability/freeze. It does not refill HP, remove chosen cards or erase saved currency. Invulnerability and freeze also reset on a new run; balancing values stay until reset/reload/application restart.

**Important for testing:** These are real run controls. Test kills, forced drops, healing, invulnerability and edited rewards can affect earned/saved Echoes. Use `-- --test-mode` when you want isolated progress/profile files. Test actions are disabled by removing the console entirely in release builds; no free-form code execution is provided.

## Saved files and error handling

Normal files: `user://progress.json` and `user://balance_profile.json` in Godot's app data folder. Each replacement is written to a temporary file and read back, then the previous file is retained as `.bak`. A missing main progress file can recover from a validated backup. Invalid existing progress is preserved and not overwritten. A failed reward write shows a retry button; the run cannot silently restart and discard the pending reward. A successful payout cannot be repeated from the result screen. Closing the app while saving is failing can still lose an unpersisted reward.

## Automated verification

From this project folder, first set `$godotExe` to your local console executable:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/test-user'
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
& $godotExe --headless --path . --script res://tests/arena_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/loot_console_test.gd -- --test-mode
& $godotExe --headless --path . --script res://tests/inventory_test.gd -- --test-mode
& $godotExe --headless --path . --quit-after 120 -- --test-mode
```

The test scripts require `--test-mode`, use process-specific file names and do not modify normal progress. The arena test accelerates the full run by defeating enemies programmatically; it does not validate human difficulty or game feel.

INV1 verification: 58 arena + 54 loot/console + 46 inventory checks = 158 checks, no failures on Godot 4.7.2. Five changed gameplay scripts also passed Godot MCP `script_check`. Native D3D12 previews of equipment, ground item explanation and tuning were inspected.

For staged engine previews:

```powershell
& $godotExe --path . --script res://tests/capture_preview.gd -- --test-mode --view=loot --output=C:/path/to/preview.png
```

Views: `inventory`, `loot`, `console`, `tuning`, `upgrade`, `result`; no view argument captures the arena. These are reproducible test arrangements, not human playthroughs.

## Manual acceptance

Play a full run; use F1 → Rewards & tools → choose an item → Drop selected item, collect it, then press I. Explain its effect before equipping; compare both books and both scepters, swap with a full bag and put an item down. Check actual equipped effects, both wave cards, death/victory payouts, new-run item reset and saved currency after restarting the app. Open F1 over equipment, an existing pause, a card choice and the result. Try a profile save/reset/load and another window size. Human readability, balance and release export remain open.

Development documentation: `C:/Users/elias/OneDrive/Dokumente/ChatGPT/Lootfall 2.0`. Game source: `C:/Users/elias/Lootfall 2.0/lootfall-2.0`.

## Local version control

This game directory is versioned separately from the development chronicle at `C:/Users/elias/OneDrive/Dokumente/ChatGPT/Lootfall 2.0`. This preserves the existing open-editor and MCP paths. Game commits include scripts, scenes, tests, project settings and the active Godot MCP Toolkit with its license. Caches, save files, machine-specific MCP settings and the inactive Godot AI addon are excluded without deleting local files.

After a tested feature, commit the selected game changes, then record that game commit in the chronicle alongside its screenshots and documentation and commit those there. No remote publishing is implied by a local commit.
