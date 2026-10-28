# Companion slice — playable build and acceptance test

Open the existing `project.godot` in Godot 4.7.2 and press **F5**.

## First play

1. A fresh save uses Friends immediately. An existing v1–v5/global-tree save keeps its original tree until you choose **Switch to Friends / refund exactly … Echoes + verified save backup** in Emberhaven. This replaces the old bonuses with refunded currency; it does not assign old purchases to new talents. The button describes the conversion before applying it. No real saves were used in development tests.
2. **Explore**. In wave 1, Gravitation is visibly holding a circle and weakly gathers nearby pursuers. Clear the normal enemy budget, then select **Rescue / unlock ability + tree**. Q becomes available immediately. In wave 2, clear Prisma's blighted circle and accept the second encounter. E becomes available; the usual wave-2 card choice follows.
3. Aim at a group and press **Q**: Black Hole gathers it. Move to line up the group, aim through it and press **E**: the telegraphed beam fires along the direction locked when E was pressed. LMB still casts fireballs. Q and E have independent 9 s / 7 s cooldowns; the HUD shows readiness, time and beam charging. Pause/inventory/F1 freeze spell timers. Death and restart clear spells.
4. Return to Emberhaven after the run. Both rescued friends appear with distinct silhouettes and short dialogue. **Friends** opens their personal trees. Buy nodes with shared Echoes and set the Q/E dropdowns. Changes apply to the next run; rescue can fill an empty slot immediately during the current run. An empty slot is allowed. A friend cannot occupy both slots.
5. Unequip a developed friend and start another run: its purchases remain saved, but its general stats and special talents do not apply. Re-equip it for a later run. All 15 nodes can eventually be purchased; learn any connected predecessor. There is no mutually exclusive specialization or automatic reset.

## Debug shortcut

For disposable testing, enter **Restoration sandbox — separate test save** in town. F1 → **Test tools** → **Friends: unlock both (current save)**, then Add/Set Echoes. Close F1, purchase talents in Friends, then start a new run. **Ready Q/E (current run)** resets only the current cooldowns. **Finish current wave** uses the normal rescue/card/restoration continuation. Debug tools affect the currently selected save; use the sandbox or `-- --test-mode` to isolate experiments. No release debug console is enabled.

## Trees and combat rules

Each implemented friend has 9 general nodes (three each: +8% damage, +10% HP, 3% shorter fireball interval) and 6 special talents matching masterplan §8.21. Across two fully equipped trees: +48% damage, +60% HP, 18% shorter fireball interval. Additive interval reduction is capped at 30%; the existing absolute 0.08 s fireball floor remains. General damage also scales companion damage; run cards and items retain their fireball-specific rules.

Each of the three branches costs **10 / 25 / 50 / 100 / 180 Echoes** along its five nodes: **1095 per friend**, **2190 total**. These are initial test values. The 10-Echo entry can be bought after the first cleared wave.

- **Gravitation:** radius 150→200; duration 3.5→5 s; collapse for 3× base fireball damage; direct fireballs slow 30% for 1.5 s; direct fireballs deal +25% inside the field; field kills add 15% collapse damage each, capped at ten kills. Collapse damage requires the Collapse talent. Boss pull is 30%; committed Champion rushes keep their existing behavior.
- **Prisma:** width 30→54; charge 0.65→0.3 s; first beam hit emits two shorter 50% rays, without recursive splitting or repeatedly damaging a main-ray target; direct fireballs mark for 4 s; marked targets take +40% beam damage; direct fireball kills shave 0.1 s off a current charge or store up to 0.3 s for the next charge, with a 0.15 s floor. Beam base damage is 4× base fireball damage. The line pierces all intersected enemies once. Beam/collapse use existing armor, damage, kill and item-loot handling without triggering fireball cards or item chains.

The four remaining schools are catalog entries, with rescue type metadata (`confrontation`, `shared_battle`, `challenge`). They are not selectable, unlockable or playable. Shared battle and wave challenge are represented by the two early slice encounters; later confrontation combat/story content remains to be authored. No quest framework, additional currency, class or prestige system.

## Save migration

Progress **v6** reads v1–v5. Read-only loading never rewrites a file. Old global purchases remain fully functional in explicit legacy mode; continued legacy play writes v5 until the player chooses conversion. The one-way in-game conversion copies and verifies the original bytes to `.pre_companions.json` before writing v6; recovery from `.bak` is supported. If an earlier failed conversion left a different backup, it is preserved and a uniquely suffixed backup is created. Exact historical prices are returned, not current tuning prices. Wallet, pending earned/paid Echoes, settlement IDs, restoration ledger, region progress, overflow and regional records stay intact. Repeating conversion cannot refund twice.

New saves store rescued friends, two slots, purchases with paid prices and the conversion refund receipt atomically through the existing Safe JSON transaction. Invalid IDs, duplicate slots, unrescued purchases, disconnected trees and invalid prices are rejected. Failed purchases, rescues, loadout saves or conversion change neither wallet nor ownership. A failed rescue keeps its dialog open for retry and cannot be dismissed with Escape. Old builds cannot read v6; use the preserved pre-conversion save for an intentional downgrade. Never copy test progress over a normal save.

No companion respec is supplied: the new respec rule remains a product decision. Exact legacy reset is retained only in legacy mode. This avoids inventing a new refund economy.

## Automated checks

Always isolate progress:

```powershell
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:/Users/elias/Lootfall 2.0/lootfall-2.0' --script res://tests/companion_test.gd -- --test-mode
```

`companion_test.gd`: **167 passing checks**, also passed natively with D3D12. Covers fresh/legacy/v6 saves, all versions, all 45 historical prices, exact backups, retry/failure behavior, all 30 purchases, actual tree buttons/tabs, snapshots, two-slot validation, real Q/E input, pause/death, live pulling and piercing, upgrades, mark/slow, split, charge and collapse. Native `-- --test-mode --capture` additionally saves staged screenshots under `.godot/companion_slice/`. These are controlled engine fixtures, not a human run.

Existing suites retain explicit global-tree fixtures to test legacy behavior. Current companion flow has its own suite. Existing waves/bosses/cards/eight items/inventory/Echoes/restoration/three-region tests continue to pass. See the German devlog for final suite totals and performance measurements.

Native performance probe: `res://tests/companion_perf.gd -- --test-mode --normal` uses the regular 12-enemy cap, active AI and both spells; omit `--normal` for artificial 80-enemy stress, add `--no-magic` for comparison. It measures 150 frames after warmup, includes presentation/VSync, and excludes kill/save IO. It is not a full late-run benchmark.

## Human acceptance still needed

Play the first two waves naturally; confirm the rescue is clear and the first 10-Echo purchase feels timely. Compare Q alone, E alone, and Q→E. Listen to the separate gravity, windup, beam, collapse and rescue cues. Try talents and equipment/card combinations, return/restart/reload, and check all region progress remains. Assess sound mix, beam readability, cost pacing and dense late-wave performance. No new export or GitHub push accompanies this local slice.
