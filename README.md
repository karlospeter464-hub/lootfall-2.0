# Lootfall 2.0 — The Ember Trial

Open `project.godot` in Godot 4.7 and press **F5**. Main scene: `scenes/arena.tscn`. Game UI and code are English.

## Play

- **WASD:** move. **Mouse:** aim. **Hold left mouse button:** cast fireballs. **Escape:** pause/resume.
- Clear six waves by default. After waves 2 and 4, choose one of three cards. These choices remain wave-based.
- Enemies have a **2% Codex drop chance** per eligible defeat by default. Walk over the golden **Cinder Codex** to collect it. At most one can drop/be active per run; an uncollected book remains between waves.
- The Codex adds splash damage to nearby enemies on a fireball impact: **85-unit radius, 60% of that fireball's damage** by default. The directly hit enemy takes only its normal hit. The item resets on the next run.
- Death or clearing the final wave opens the result screen and awards **Echoes for completed waves**. Default: `10 * cleared * (cleared + 1) / 2`, so clearing 1/2/3/6 waves earns 10/30/60/210 Echoes. Dying during wave 4 pays for the first three cleared waves. Entering a wave alone earns nothing.
- Echoes and best reached wave are saved at run end. Restart retains them but clears the build, Codex, enemies, projectiles and run counters. Closing the app mid-run does not pay the unfinished run.
- Echoes are currently banked; the Hideout and spending/unlocks are a later package. No inventory, permanent item collection, XP bar or extra enemy class was added.

## F1 developer console (debug builds only)

**F1** opens/closes the console; **Escape** closes it. Gameplay pauses while it is open. Closing preserves an existing pause, upgrade choice or result screen. SpinBox fields accept keyboard entry and arrow controls; each field shows when it applies.

28 settings are split into tabs:

| Tab | Adjustable values |
| --- | --- |
| Player | Movement, maximum health, base damage, cast interval, hit protection |
| Waves | Wave limit, first-wave enemies, enemies added per wave, active enemy cap, spawn interval, safe spawn distance, intermission |
| Enemies | Base health/speed/damage, health/speed growth per wave |
| Combat & loot | Projectile speed/lifetime/spread, all three card strengths, Codex drop chance/pickup radius/explosion radius/splash ratio |
| Rewards & tools | Echoes per cleared-wave tier; invulnerability, freeze enemies, restore HP, force a physical Codex drop, defeat active enemies, apply RNG seed |

**Application:** Player/build settings update the actual build while preserving already chosen cards. Lowering max HP clamps current health; raising it does not heal. Enemy stats affect new spawns; lowering the cap does not delete existing enemies. Wave budgets change when the next wave starts. Projectile speed/lifetime affect new shots. Codex explosion settings affect the next impact. Card strength edits update already chosen cards and the choice text when the next choice opens. The run still has exactly two choices, at waves 2 and 4. Raising the wave limit in the console is available for pressure tests, with no extra card events.

**Metrics:** FPS/approximate frame interval, static memory, run state/unpaused time/seed, reached/cleared/best wave, enemy count/cap/budget/HP, defeats, live/fired/hit projectiles, actual damage (excluding overkill), average damage per unpaused run second, health lost, effective player/build values, card counts, ground loot/drop count/Codex status, splash/drop settings, wallet and predicted payout.

**Save profile / Load profile:** Balancing values are saved separately from game progress. Profiles load manually; restarting the application restores Inspector defaults until you load your profile. Loading validates every value and known key before applying any of them. Profiles do not contain currency, current health, items, RNG state or test switches.

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
& $godotExe --headless --path . --quit-after 120 -- --test-mode
```

The test scripts require `--test-mode`, use process-specific file names and do not modify normal progress. The arena test accelerates the full run by defeating enemies programmatically; it does not validate human difficulty or game feel.

For staged engine previews:

```powershell
& $godotExe --path . --script res://tests/capture_preview.gd -- --test-mode --view=loot --output=C:/path/to/preview.png
```

Views: `loot`, `console`, `tuning`, `upgrade`, `result`; no view argument captures the arena. These are reproducible test arrangements, not human playthroughs.

## Manual acceptance

Play a full run; verify a forced Codex pickup and its splash, both card choices, death/victory payouts, new-run item reset and saved currency after restarting the application. Open F1 during play, an existing pause, a card choice and the result. Try a profile save/reset/load, then adjust one parameter at a time. Test another window size. Human balance and release export remain open.

Development documentation: `C:/Users/elias/OneDrive/Dokumente/ChatGPT/Lootfall 2.0`. Game source: `C:/Users/elias/Lootfall 2.0/lootfall-2.0`.

## Local version control

This game directory is versioned separately from the development chronicle at `C:/Users/elias/OneDrive/Dokumente/ChatGPT/Lootfall 2.0`. This preserves the existing open-editor and MCP paths. Game commits include scripts, scenes, tests, project settings and the active Godot MCP Toolkit with its license. Caches, save files, machine-specific MCP settings and the inactive Godot AI addon are excluded without deleting local files.

After a tested feature, commit the selected game changes, then record that game commit in the chronicle alongside its screenshots and documentation and commit those there. No remote publishing is implied by a local commit.
