# Current default — four-direction Apprentice, 2026-10-28

Approved directional mage is now the normal player. See directions/README.md for source, approved V2 rear and runtime details. V restores the previous A+ visual; Use Artwork=false starts procedural.

## Historical v01/A+ integration (26 October)

# Current default — Apprentice v01 / A+, 2026-10-26

Runtime image: apprentice_v01.png, byte-identical copy of the owner-supplied lootfall_apprentice_runtime_candidate_v01.png. Original test fixture and download retained. SHA256 831023c026176d2949e3e8a085148ea1cb79d72d1684a0b7977fbbead3053128, 256x320 RGBA, alpha bounds (18,26,212,274), real transparency. This is the same image used in the approved A+ test; no new artwork or raster edits. Separate source/license evidence was not supplied; provenance remains owner-supplied prototype art.

scenes/player.tscn uses this texture plus scripts/apprentice_visual.gd and scripts/apprentice_fire.gdshader. Lossless imported texture with mipmaps/alpha-border fix and linear mipmap filtering; standard import/preload dependencies work without tests/ files or raw-PNG reads. Foot point (128,300), offset (-128,-300), scale 64/274 = 0.23357664, about 64 logical pixels high. Collision radius 15, shot start player position + direction * 25, gameplay and save format unchanged.

F5 -> Start Run shows A+. V cycles A+ / original-v01 animation / procedural. Player -> Use Artwork=false before starting selects procedural fallback. Existing source, original procedural body and historical Crimson image below are retained. First shot has no animation delay; precharge reads the existing cooldown. Whole-body pose remains fixed-facing; no independent arm/staff or step frames. No new B rig.

The native Player starts the shared visual controller after its own reset. The isolated test now reuses that component; there is no duplicate animation implementation. Disable/missing texture keeps the procedural body. Original PNG remains unmodified as backup; earlier suspicion of a second baked ground-shadow ellipse was corrected by pixel inspection.

## Historical 19 October integration (not the current default)
# Apprentice — first illustration integration

Source: `Crimson Grimoire Mage Sprite.png`, supplied by the project owner on 2026-10-19 for Art Vertical Slice 01. The authoring tool and a separate license document were not provided; no third-party attribution or final production-rights claim is invented here. This is the owner's supplied prototype asset, not an extracted asset from another game.

Runtime file: `apprentice_crimson_grimoire.png`, **byte-identical** copy; original download preserved. SHA-256: `88915cfbe3703bc38e8a2aa1d1cc2f28441ac303244dcc25a329cbbd4ed57ba5`.

- 1086 × 1448, 3:4, RGBA PNG, 1669737 bytes. Real transparent background and partial-alpha edges; not an opaque black rectangle. Fine semi-transparent fringe pixels and flame details remain from the source. No raster edits or new generation.
- Imported by Godot as a lossless Texture2D with mipmaps and alpha-border fixing; Sprite2D uses linear mipmap filtering. This avoids noisy single-pixel sampling when reduced from illustration size to gameplay size.
- `scenes/player.tscn` → Artwork. Initial scale 0.058; full image approximately 63 × 84 logical pixels, including transparent margins. Original-pixel foot anchor (600, 1410), `centered = false`, offset (-600, -1410). Foot anchor and shadow at the unchanged player world position. Collision remains the original radius-15 circle.
- A 0.6% vertical breath scales around the feet; no gameplay movement. The scene's scale is the base, so adjust it in the Sprite2D Inspector. Hurt modulation and brief cast flash are visual only. Existing aim, charge and talent indicators draw over the artwork.
- Visual Lift 01 defaults to `Player → Use Artwork = false` for the new procedural mage. Set it to true before play to opt into this preserved illustration. No texture on an existing Artwork node also uses the placeholder. No new F1 controls or UI.

The picture is a frontal character illustration. It stays upright; no mouse-facing whole-body rotation or mirrored book/staff. Small ornamental details are not reliably readable at gameplay scale. The staff and book are cosmetic parts of this picture, independent of run equipment. Projectiles still originate at player position + shot direction × 25, not at a newly defined illustrated staff tip. No skill, collision or gear changes were made to match the art.

A final sprite needs a consistent elevated 3/4 view, simpler small-scale silhouette/details, compatible hand/cast anchors and a small, coherent directional/animation set. This prototype does not approve the final Apprentice design or the rest of roadmap A1.
