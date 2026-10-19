# CE5 — Skill Tree Refresh & Early Progression

Implemented locally; human balance and discoverability acceptance remain open. Open project.godot in Godot and press F5. No export is needed.

## What changed

The same 15-node tree now starts with three effects costing 30 Echoes each:

| Root / unchanged ID | Effect at default tuning |
| --- | --- |
| Kindling / power_1 | A kill arms the next regular central fireball for 5 seconds: +25% direct damage. Kills refresh readiness, never stack. A miss still consumes the shot. No side-shot or automatic Echo bonus. |
| Emberguard / vitality_1 | The first actual nonlethal enemy hit each wave restores 8% effective max HP, capped at full health. Protected hits and debug healing do not trigger it. No revival. |
| Arcane Momentum / flow_1 | Every four direct projectile hits grant +12% movement speed for 3 seconds. Refreshes without stacking or changing base speed. Fan, distinct piercing hits and actual Echo hits count; Burst, Codex and Storm damage do not. |

Kindling multiplies with First Spark and Overcharge on the central projectile, including its distinct piercing hits. It does not amplify Burst, Codex or Storm damage; an empowered direct kill can still trigger Burst and arm another Kindling shot. Emberguard coexists with Phoenix, Renewal and Second Wind. Momentum and Second Wind affect different stats and can run together. Timers stop during inventory, card, console and menu pauses.

The remaining twelve talents, all IDs, links and cross-links remain unchanged. Any one listed predecessor opens a node. Roots replace their old +4% damage / +5% HP / 3% interval bonuses. With the entire tree owned, unconditional totals are now +16% damage, +20% maximum HP and 11% shorter interval, plus all three roots and key effects. Existing purchases retain their paid prices and receive new effects on the next run. Ownership still uses the run-start snapshot. No progress migration or extra currency award is needed; shared progress stays v2. Free reset refunds the exact prices originally paid.

## First purchase and goals

No starting wallet: 0/1/2 cleared waves pay 0/10/30 Echoes at run end. Entering wave 2 does not mean clearing it. Thus a short first run clearing two waves buys one root; dying earlier does not guarantee a purchase. No consolation bonus or reward rule changed. Tier costs remain 30/45/65/90/130 (1080 total).

Emberhaven identifies affordable purchases and names First Spark, Renewal and Second Wind as later goals. Filled branch-colored nodes are owned; gold nodes are affordable; colored outlines require more Echoes; dim nodes need a predecessor. Select a node for name, actual effect, price, prerequisite and state. Mouse, arrow keys, Tab/Shift+Tab and Enter/Space use normal Godot focus; Esc returns to town. Focus has a light outer ring. Small II/III nodes show their full name and effect when selected or hovered.

## Tonight's short acceptance test

1. Finish an ordinary run, return to town and buy a root. Check that the wallet falls by 30 and its detail shows the actual price paid. Restart the game in town to confirm it remains purchased. Do not reset a real wallet merely to test early-run rewards; tests use isolated saves.
2. Kindling: defeat one enemy, watch the orange readiness ring, then fire once. The empowered central projectile has an orange outline. Try Fan and Overcharge; side shots and delayed Echo remain ordinary. Wait five seconds before firing to check expiry. Assess whether the rhythm is noticeable amid combat.
3. Emberguard: take a survivable enemy hit; watch green healing feedback. The next hit that wave should not heal. A new wave restores availability. Try the Phoenix book or Renewal for a defensive path. Assess whether the heal feels useful without erasing danger.
4. Momentum: land four direct hits, including Fan/Piercing if available. A blue foot arc marks the movement buff. Pause in I and inspect the counter/effective movement speed; close I and let it expire. Try Second Wind and assess whether movement is noticeable while firing.
5. Inspect later goals, follow a cross-link, refund all and start another run. No root effect or temporary speed should remain. Try navigating the tree with arrows, Tab and Enter and buying with the mouse.

F1 → Skill tree exposes five new values: Kindling damage/readiness duration, Emberguard heal ratio, Momentum speed/duration. Four hits is the fixed Momentum rule. Effects use active ownership; tuning is live where indicated. Profiles v10 contain 92 numeric fields and read v1–v9 without rewriting them. Old fields retain saved values; absent new fields use startup defaults. Progress and transient effect state are never stored in balance profiles.

## Technical verification

Godot 4.7.2: twelve suites, 898 checks without failures, including 63 CE5 checks. Real projectile combinations, no-ownership behavior, one-shot consumption, expiry, fan/pierce, Echo exclusion, indirect damage exclusion, once-per-wave heal, lethal/protected damage, pause, base-speed restoration, snapshot/refund, v9 compatibility, keyboard focus and all fifteen detail layouts are covered. Existing safe-save failure, exact refund and other twelve talent checks remain in town_tree_test.gd. Six modified gameplay/UI scripts passed Godot MCP script_check.

Four staged native D3D12 screenshots were visually inspected: mixed ownership with Renewal selected, Kindling, Momentum and town affordability. These are controlled previews, not recordings of a natural run. No new clip, Windows export, deployment or GitHub push. Human game feel, balance over several natural runs and external acceptance remain unverified.
