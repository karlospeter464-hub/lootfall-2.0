# Default integration — 26 October 2026

The owner has now authorized v01/A+ as the normal Player. **F5 -> Start Run** shows it. V still cycles A+ / original-v01 animation / procedural. Runtime assets live under assets/art/characters/apprentice/ and scripts/; this isolated test reuses Player.visuals. Historical test-only statements below describe earlier work and are superseded by this integration. No gameplay/balance/save changes, no new release ZIP or push. Verification: 224 checks across Player Art (24), A+ (39), Visual Lift (12), Arena (64), Combat Polish (35), Inventory (50); normal main-scene startup and native default screenshot passed. Existing project.godot/editor-generated user files preserved.

# Apprentice Visual Slice A (isolated proof)

The normal Player scene and all production gameplay scripts are unchanged. This test attaches a Sprite2D wrapper and AnimationPlayer only to its own arena instance. It currently uses the owner-supplied lootfall_apprentice_runtime_candidate_v01.png as an isolated runtime candidate, not a permanent production replacement.

From this project directory in PowerShell, using the installed Godot console executable:

```powershell
$godotVisualExe = 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA = Join-Path (Get-Location) '.godot/visual-slice-user'
& $godotVisualExe --path . --script res://tests/visual_slice_a.gd -- --test-mode
```

WASD moves, mouse aims and LMB casts. V cycles A+ -> original v01/A -> procedural -> A+. F1/Escape retain their existing actions. The fixture first runs its assertions and then enables live enemies. Close its game window when finished. Normal F5 still uses the original procedural character. No project launch settings or saved player data are changed.

For automation add --verify and --headless before --path. For native before/idle/cast screenshots use --capture after --test-mode. Optional --output=C:/path/to/directory goes after --test-mode. Captures stage twelve stationary enemies, wave 3, seed 42 and existing seer warnings; they are comparison fixtures, not a performance benchmark or a human run. All tests require --test-mode and isolate progress. The sample does not validate the full A1 asset family or a dense mixed build.

## Current candidate v01 — 25 October 2026

- File tests/fixtures/lootfall_apprentice_runtime_candidate_v01.png; byte-identical copy of owner-supplied Downloads file. SHA256 831023c026176d2949e3e8a085148ea1cb79d72d1684a0b7977fbbead3053128, 80179 bytes. Source/provenance: provided by owner in this chat; separate original authoring file/license evidence not supplied. The German Mage animation sheet is a design reference only and was not sliced or used as a spritesheet.
- 256x320 RGBA, real partial alpha, alpha bounds (18,26,212,274). Sprite2D centered=false; offset=(-128,-300). Declared foot point (128,300) maps exactly to the unchanged player origin in neutral pose. Scale 64/274=0.23357664, giving approximately 49.5x64 logical pixels / 44.6x57.6 display pixels at the normal 1152x720 window. Idle/cast animation slightly changes that envelope.
- Linear mipmap filtering; original PNG pixels preserved. Existing procedural body, old test PNG, historical Crimson asset and normal F5 remain intact. V toggles the new candidate against the original body.
- For a repeatable live-combat capture, run the command above with --combat-capture after --test-mode. The output directory defaults to .godot/visual_slice_a; optional --output=C:/path/to/output also goes after --test-mode. This mode runs the existing isolated checks, then 180 real physics frames with all twelve enemies unfrozen, original WASD movement, accepted attacks and real collision/damage. It aims programmatically at a Guardian; this is an automated combat fixture, not a human playthrough. No stat, enemy-cap, hitbox or progression tuning is applied.
- Outputs: prototype_idle.png, combat.png and combat_metrics.json (plus baseline/cast/size evidence). Native captured count: twelve enemies throughout, ten fired shots, eight direct hits, 80 actual damage, player health 54.5728 after starting at 100; movement about 196 logical units from start. Move and Cast animations both observed in the running AnimationPlayer.
- Visual findings at normal camera scale: no opaque backdrop, obvious rectangular alpha boundary or obvious white/black fringe. Hat/flame silhouette remains readable; face, fingers and book details largely disappear at this size. Aim/projectiles and hostile warning circles remain visible in sampled images. Foot anchor check passes, body never rotates with the mouse. Correction on 26 October: closer alpha/pixel inspection did not identify a separate baked ground-shadow ellipse in this runtime PNG. The earlier double-shadow claim was too broad. Keep original pixels and the existing Godot ground shadow; do not erase boot/costume pixels. A screenshot is not proof of zero temporal jitter.
- Method A is adequate for a first small playable prototype. It cannot animate independent legs, hands, staff or book, and a single facing means spells can travel in directions the drawn pose does not face. Do not add a rig or directional sheet automatically. Decide after human inspection whether this limitation is acceptable or whether one small follow-up (directional stills or a few body frames) is warranted.
- Current verification: 27 headless assertions for the candidate and 39 checks in the native live-combat run; existing player_art and visual_lift suites rechecked separately. Full long-run/performance/release validation remains outside this short test.
## Historical first-proof measurements, 25 October 2026 (previous PNG)
- No Camera2D / camera zoom in current arena. Canvas transform identity; logical viewport 1280x800, default window 1152x720 (0.9 display scale).
- Current procedural body including its shadow/aim indicator: 50x55 rendered pixels at logical 1x in a transparent Godot SubViewport, idle aiming right. Thus about 45x50 display pixels in the default window. State/aim/overcharge effects can enlarge those bounds.
- Collision radius 15; projectile origin remains player position + aim * 25. These are not sprite dimensions.
- Existing optional historical Crimson illustration: full canvas 63x84 logical pixels (1086x1448 at 0.058); it remains untouched and disabled by default.
- New reference PNG: 1086x1448, RGBA, used alpha bounds (31,19,1037,1429), partial transparency confirmed. SHA256 7272d1a45d3766a7ffee1f8fb55c41d6f85e18dc78777ec680f16a285340fa04. Byte-identical owner-supplied source; no raster edits. Source is not final elevated gameplay art; many fine details disappear at runtime size. Separate license proof was not supplied; no production rights claim is made.
- Prototype target: alpha silhouette height 64 logical pixels; scale 64/1429 = 0.044786565. Width about 46.4 logical pixels, about 42x58 display pixels before animation. Transparent fringe may exceed perceptually visible silhouette.
- Temporary source anchor (590,1410) stays attached to player origin. Source feet/perspective still require visual approval. Shadow and gameplay effects remain in the existing Draw code.

## Smallest integration
Existing Player -> VisualMotion (Node2D) -> Artwork (Sprite2D), plus AnimationPlayer under VisualMotion. Only VisualMotion transforms animate. Production update_artwork keeps its existing breathing/hurt modulation; it does not overwrite the wrapper keys. Idle adds 1.2% vertical breathing over 2 seconds; movement adds a 1.5-unit bob and +/-1.43-degree sway over 0.4 seconds; cast adds a 2.5% scale pulse, 1.5-unit local nudge and up to 2-degree tilt over 0.12 seconds. Existing velocity/cast_flash select animations; existing pause freezes them. No rigging, sprite sheet, directional generation or second gameplay state machine.

This only moves/deforms a whole drawing. It cannot produce independent walking legs, an opening book or a moving staff arm. Perspective and silhouette must already work in the PNG. No whole-body mouse rotation or automatic mirroring of asymmetric equipment.

## First runtime PNG delivery contract (proposal for art approval)
- One RGBA PNG named apprentice_idle.png; real transparent background, clean antialiased edges, no black/white matte, text, embedded arena or baked ground shadow.
- Recommended first canvas 256x320 px. Visible silhouette about 280 px high, foot-contact anchor around (128,300); retain padding above hat/staff and below feet. Record the actual alpha bounds and precise foot point with the delivery rather than forcing a different pose into that number.
- Render the silhouette initially at 64 logical pixels high: scale = 64 / actual alpha height (0.22857 if 280). At the default window this is approximately 58 display pixels. Review a 60–72 logical-pixel range before fixing the final scale. No camera change.
- Elevated 3/4 top-down view, one consistent facing direction; visible hat top/shoulders and convincing foot contact. No portrait/flat frontal view and no isometric camera requirement.
- Retain broad pointed hat, silver hair, simple dark cloak with rust-red lining, wooden scepter with one orange fire accent, clearly held open spellbook. Simplify fingers, folds, facial features and flame fragments; 2–3 shading planes. Aim for a contour that remains about 1–2 logical pixels thick after scaling.
- Separate ground shadow in Godot; cosmetic staff does not relocate the existing shot origin. No large baked glow that obscures hostile warnings.
- Lossless 2D texture; linear filtering, mipmaps for minification, alpha-border correction. Keep higher-resolution authoring source separate from the runtime PNG and record author/source/usage permission.
- Before adopting it, compare in this exact fixture at normal size, walk/cast/hurt/pause and toggle V. Approve silhouette/perspective before another asset family. The permanent Player integration is a separate next step after this review.

Historical first proof: 26 headless assertions, four existing suites with 131 checks, and native capture run with 30 checks passed. See current candidate results above. Native D3D12 screenshots and a transparent 1x baseline in the Devlog gallery. Human style/animation acceptance, sustained combat stress and release export remain open. Existing actual Godot editor could not be inspected through this chat's MCP: it points to the older lootfall_starter project and returned AUTH_FAILED. All reported measurements/captures came from a fresh native Godot process using the explicit active Lootfall 2.0 path.
## A+ animation polish — 26 October 2026

v02 was rejected by the owner. v01 remains the single texture source and unchanged backup (SHA256 831023c026176d2949e3e8a085148ea1cb79d72d1684a0b7977fbbead3053128). No PNG editing or new drawing, no rig and no production Player integration. Original library is retained for mode 1; A+ uses mode 2, procedural fallback mode 0.

A+ adds 2.8-second breathing/weight-shift, a low-amplitude 0.34-second movement cycle and velocity-based body skew. Position stays zero in all four A+ animations: the declared (128,300) foot point remains fixed, with no vertical hopping. Existing tiny Player breathing/hurt tint remains. A short shader changes only warm flame pixels inside the measured fire area, with an independent pause-aware clock and bounded glow. No shader TIME is used, so pause freezes it. No external image-generation/edit service was used.

Actual accepted main-shot signals trigger the visual pulse at the unchanged projectile origin and a 0.24-second recoil/return. Preparation uses the last 0.10 seconds of an existing cooldown only when another cast is intended. The first shot remains immediate; no windup, delay, damage or cooldown change was introduced. A separately swinging staff/arm cannot be reconstructed by this whole-image transform; that would need a small separately authored arm/staff layer, not a full rig.

Use the usual test command for the interactive comparison. To record the repeatable demo, add --polish-clip after --test-mode and use Godot --write-movie C:/path/to/capture.avi --fixed-fps 30 before the separator. The demo includes original v01, A+ idle, procedural comparison, then active combat with four movement directions and several accepted casts. Enemies are stationary during the comparison and final return only; twelve are active during the combat section.

Actual recording: 236 native MJPEG/PCM frames at 1152x720/30 fps, 7.8667 seconds. Review MP4 is 7.7667 seconds/233 frames after cutting only 0.1 seconds of startup, H.264/AAC. Ten fired shots, ten direct hits, 84 actual damage; player health 54.5728; preparation, move and cast states observed. Normal F5, body/hitbox, shot origin, skill values, progression/save formats and source PNG unchanged. Real engine simulation with scripted input, not a human playthrough or synthetic sprite video.

Tests: 39 isolated assertions plus 20 Player Art, 12 Visual Lift and 35 Combat Polish checks, all passed (106 headless total). Native demo: nine checks passed, including twelve active enemies, real shots/hits and animation states. Foot anchoring, actual V key handler for all three modes, original material restoration, pause including fire clock, reset/hurt and unchanged source hash covered. MP4 completely decoded, no black intervals detected; eight actual video frames inspected. This is not a full temporal/human animation or performance acceptance.

Evidence: Devlog Progress/captures/2026-10-26_aplus/{aplus_gameplay.mp4,original_idle.png,aplus_idle.png,procedural.png,aplus_combat.png,polish_metrics.json,clip_frames.jpg}. Native AVI retained outside Git under C:/Users/elias/Video_Production/Visual_Slice_A_Plus/aplus_native.avi. Comparison labels are test-only. A+ is a useful intermediate; a small arm/staff B proof promises a more distinct casting gesture while keeping this controller as fallback.
