# Apprentice Visual Slice A (isolated proof)

The normal Player scene and all production gameplay scripts are unchanged. This test attaches a Sprite2D wrapper and AnimationPlayer only to its own arena instance. It uses the owner-supplied Chibi Witch PNG as a temporary reference, not an approved final runtime character.

From this project directory in PowerShell, using the installed Godot console executable:

```powershell
$godotVisualExe = 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA = Join-Path (Get-Location) '.godot/visual-slice-user'
& $godotVisualExe --path . --script res://tests/visual_slice_a.gd -- --test-mode
```

WASD moves, mouse aims, LMB casts, V switches between the new PNG and the original procedural body. F1/Escape retain their existing actions. The fixture first runs its assertions and then enables live enemies. Close its game window when finished. Normal F5 still uses the original procedural character. No project launch settings or saved player data are changed.

For automation add --verify and --headless before --path. For native before/idle/cast screenshots use --capture after --test-mode. Optional --output=C:/path/to/directory goes after --test-mode. Captures stage twelve stationary enemies, wave 3, seed 42 and existing seer warnings; they are comparison fixtures, not a performance benchmark or a human run. All tests require --test-mode and isolate progress. The sample does not validate the full A1 asset family or a dense mixed build.

## Native measurements, 25 October 2026
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

Verification: 26 new headless assertions, four existing suites with 131 checks, and native capture run with 30 checks all passed. Native D3D12 screenshots and a transparent 1x baseline in the Devlog gallery. Human style/animation acceptance, sustained combat stress and release export remain open. Existing actual Godot editor could not be inspected through this chat's MCP: it points to the older lootfall_starter project and returned AUTH_FAILED. All reported measurements/captures came from a fresh native Godot process using the explicit active Lootfall 2.0 path.
