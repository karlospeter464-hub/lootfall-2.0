# Blender mage — isolated comparison (27 October 2026)

One existing owner-supplied Tripo mesh, one Blender render. No production Player, gameplay, F5, project configuration or save-format changes. Normal player remains v01/A+.

From the project directory:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/blender-mage-user'
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/blender_mage_slice.gd -- --test-mode
```

WASD moves, mouse aims, LMB casts. V switches Blender / production v01 A+. Escape/F1 retain existing behavior. Test mode is mandatory, including when launching tests/blender_mage_arena.tscn directly. Do not change the F5 main scene.

Add --verify for an automated 180-physics-frame combat check (headless supported). Add --combat-capture for native fallback_idle.png, prototype_idle.png and combat.png; optional --output=C:/path goes after --test-mode. Native capture uses the unchanged normal 1152x720 window / 1280x800 logical viewport, identity canvas transform, twelve actual enemies and scripted WASD/accepted attacks. Enemies are frozen only for idle comparisons; all twelve AI instances run during combat. This is automated gameplay, not a human playthrough.

## Source and render

Live Blender 5.2.3 LTS scene was unsaved. Its complete original state was saved before modification to C:/Users/elias/Lootfall 2.0/Blender Repo/visual_slice_2026-10-27/tripo_original.blend. Working render scene: tripo_render_working.blend in the same folder. Earlier apprentice_test.blend untouched. Textures are packed; both files approximately 21 MB.

Object tripo_node_c94d54a4-7a03-4c20-8699-79094788ce0b: 210075 vertices, 376328 faces, world dimensions 0.47618 x 0.33775 x 1.0. Genuine volumetric mesh, one UV layer, original basecolor/normal/roughness-metallic 4096x4096 textures. No armature, modifiers or animation. Owner-imported Tripo source; no new generation, upload or paid service. Separate source-generation settings/license evidence were not inspected.

Original mesh and material nodes retained. Cube and default light/camera excluded from render; dedicated orthographic camera at (0.55,-3,2.15), looking at (0,0,0.5), 28.41-degree elevation, ortho scale 1.17. EEVEE, three area lights, Standard view transform, transparent film, 512x640 8-bit RGBA PNG. No floor/shadow catcher, no baked ground shadow. Reopen the working blend and render its active camera to reproduce.

mage_idle.png alpha bounds: (118,58,276,510). Declared ground anchor is the projection of world (0,0,0): (256,560.55891). Godot scale 64/510=0.1254902 gives 34.64x64 logical pixels / approximately 31.2x57.6 window pixels before animation. Lossless texture import, mipmaps, linear minification, alpha-border correction. Existing Godot shadow remains.

The test controller subclasses the production visual controller, using its original idle/move/cast library and disabling the v01-specific fire shader for this differently placed scepter. V fully restores the original texture, foot pivot, scale, A+ animation and flame shader. Small test scene fixtures retain the Player/Arena topology and reference the original gameplay scripts. Separate fixture scenes avoid replacing a live script whose constructor has already allocated animation nodes.

## Verified

- New comparison: 23 headless checks, 0 failures; native D3D12: 26 checks, 0 failures, clean final exit.
- Native combat: twelve enemies throughout; nine shots, eight hits, 80 damage; real movement 196.04 logical units from start; health ended at 54.5728; move and cast observed.
- Original player-art suite: 24 checks, 0 failures. Original visual-slice suite: 39 checks, 0 failures.
- Transparency, mipmaps, 64-pixel height, foot projection, unchanged collision radius 15 / speed 245 / damage 14 / cast interval 0.36, pause and V fallback covered.
- One import-only safe-save warning from existing editor settings; import exited 0 and runtime tests/captures succeeded. No security/editor safety settings changed. Initial inherited-scene override leaked two unparented visual nodes; flat test fixtures removed the cause and final runs exit without those warnings.

## Visual decision

Technical pipeline works. This render is not yet a production-quality Style-C sprite. The body is much narrower than v01; glossy silver/dark texture noise replaces the broad graphic shapes and orange accent. Head and scepter outline are visible, but face/hand detail disappears. The closed side-hanging book merges with the sleeve; it is not the required open, visibly held grimoire. Ground projection is plausible and aligned; a single image with whole-body impulses still slides instead of walking. Rendered materials differ visibly from the graphic enemies.

Keep the model as a controllable 3D source; do not build a full animation pipeline yet. First resolve the silhouette, simplify glossy materials and establish an open-book casting pose, then repeat this exact small comparison. Future directional stills can share camera/light setup. Real idle/walk/cast frames require a cleaned deformable body, armature/weights, separated controllable scepter/book, hand contacts and authored cycles; current dense single mesh is not already animation-ready. Retopology should be decided from deformation quality rather than performed automatically.

A specialized anime sprite generator was not tested, so no quality/cost superiority is established. For this source, deterministic camera/direction consistency is useful; the current style mismatch remains. A same-size generator baseline would be a separate small test if this appearance cannot be brought to the chosen art direction cheaply.

Not checked: human style acceptance, long-run performance, directional frame quality or release exports. No new rigging, texturing pipeline, paid tooling, push or release.
