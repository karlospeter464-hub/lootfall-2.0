# CE3 — Build Discovery & Card Synergies

Start natural runs with F5. The existing wave 2/4/5 choices in each five-wave block now offer up to three distinct cards drawn uniformly without replacement from six valid cards. Bosses use the same pool. There is no build weighting or guaranteed synergy. Offers stay fixed while inspecting equipment or tuning F1; unavailable cards are removed rather than rerolled. An entirely exhausted pool continues without an upgrade.

| Card | Effect | Repeatable? |
| --- | --- | --- |
| Ember Power | +35% base fireball damage per choice | Yes |
| Quick Casting | 20% shorter interval per choice, 0.08 s minimum | Yes, until capped |
| Fire Fan | One extra shot per cast, aimed main shot preserved, nine maximum | Yes, until capped |
| Ember Burst | A direct projectile kill explodes at the defeated enemy: radius 105, 70% shot damage | Choose once per run |
| Piercing Flame | Each shot can directly hit two different enemies, including both in one frame | Choose once per run |
| Overcharge | Four successful direct hits ready the next main shot for +75% damage | Choose once per run |

Burst never damages its dead primary and indirect kills never trigger more Bursts. Codex and Burst can both damage nearby survivors, each respecting Guardian armor separately. Piercing can cause Codex splash on each direct hit; the other pierced target may also receive splash when in range. The shot cannot directly hit the same enemy twice. First Spark remains direct-only; its full-health bonus does not propagate into splash or Burst. Overcharge increases the triggering projectile's damage and therefore its derived area damage.

Overcharge counts direct hits from every fan shot and both piercing targets, including lethal hits; indirect damage and zero damage do not count. While ready, extra hits are not banked. Only the main/first fireball consumes the charge; side shots stay normal. Missed charged shots still spend the charge when fired. A rejected spawn at the projectile cap does not consume it. The player's cyan ring fills with hits; a full ring, bright hand, READY text and a cyan charged projectile identify the effect. Esc, I and F1 preserve charge. Restart clears cards and charge; nothing is permanently unlocked.

## Three repeatable build tests

Launch an isolated debug game (separate test saves; this replaces the active test run):

```powershell
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path 'C:/Users/elias/Lootfall 2.0/lootfall-2.0' -- --test-mode
```

Open **F1 → Rewards & tools**, choose a CE3 build, click **Start CE3 test**, close F1 and aim right. Each uses seed 42 and the existing six-chaser arrangement with talents inactive. Current tuning and spawn caps are retained; **Reset defaults** first for a baseline. Normal waves resume after the group. The action refuses ordinary launches without `--test-mode`.

1. **Burst + Power + Ember:** Ember Burst, two Power cards, Ember Scepter. Aim to finish a target near its allies. Compare against scattered targets; indirect kills must not produce chain explosions.
2. **Piercing + Fan + Codex:** Piercing Flame, two Fan cards, Cinder Codex. Position to line up enemies. Compare grouped versus spread enemies; repeated splash can be strong in clusters, but armor still reduces each damage event.
3. **Overcharge + Quick + Fan:** Overcharge, two Quick and two Fan cards, no gear. Watch the ring charge from actual hits. The next aimed main shot glows; side shots remain normal. Miss deliberately, pause and reopen inventory to inspect behavior.

These are test fixtures, not promises of naturally offered cards. For the success criterion, play **three to five natural runs** and record offered/selected cards, found/equipped items, wave/death cause, whether aim/positioning changed, and whether a boss forced the same swap. A varied offer is not proof of a varied playstyle. The follow-up adds a solo Champion charge; see COMBAT_POLISH_PLAYTEST.md. Seer relevance remains separate open combat work; no new enemy was added.

## Tuning and verification

F1 adds only Burst radius, Burst damage ratio and Overcharge damage bonus. Piercing's two targets and the four-hit threshold are fixed rules in this iteration. Profile v8 has 74 numeric values and validates v1–v7 profiles without rewriting them; new fields take Inspector startup defaults. Save progression stays v2. The RNG seed control reproduces card offers given the same prior RNG calls/actions; it does not independently seed cards or guarantee matching drops across different fights.

Run `--headless --path . --script res://tests/card_synergy_test.gd -- --test-mode` alongside the eight existing suites. The new suite covers random validity and seed replay, unique/exhausted cards, actual card buttons, direct/indirect kill attribution, duplicate Burst protection, Power/Ember scaling, piercing/splash/armor/Seer rules, charge consumption/fan shots, pauses/reset, legacy v7 and three presets. A scripted 256-projectile / 64-enemy batch checks combined mechanics and the 512-effect visual ceiling; it is not a sustained FPS benchmark. Damage is still applied when the visual ceiling is reached.

Human balance, long-run performance, export builds and other display sizes remain unverified. No new items, enemies, classes, currencies, progression rules or automatic build guidance were added.
