# Apprentice — first illustration integration

Source: `Crimson Grimoire Mage Sprite.png`, supplied by the project owner on 2026-10-19 for Art Vertical Slice 01. The authoring tool and a separate license document were not provided; no third-party attribution or final production-rights claim is invented here. This is the owner's supplied prototype asset, not an extracted asset from another game.

Runtime file: `apprentice_crimson_grimoire.png`, **byte-identical** copy; original download preserved. SHA-256: `88915cfbe3703bc38e8a2aa1d1cc2f28441ac303244dcc25a329cbbd4ed57ba5`.

- 1086 × 1448, 3:4, RGBA PNG, 1669737 bytes. Real transparent background and partial-alpha edges; not an opaque black rectangle. Fine semi-transparent fringe pixels and flame details remain from the source. No raster edits or new generation.
- Imported by Godot as a lossless Texture2D with mipmaps and alpha-border fixing; Sprite2D uses linear mipmap filtering. This avoids noisy single-pixel sampling when reduced from illustration size to gameplay size.
- `scenes/player.tscn` → Artwork. Initial scale 0.058; full image approximately 63 × 84 logical pixels, including transparent margins. Original-pixel foot anchor (600, 1410), `centered = false`, offset (-600, -1410). Foot anchor and shadow at the unchanged player world position. Collision remains the original radius-15 circle.
- A 0.6% vertical breath scales around the feet; no gameplay movement. The scene's scale is the base, so adjust it in the Sprite2D Inspector. Hurt modulation and brief cast flash are visual only. Existing aim, charge and talent indicators draw over the artwork.
- `Player → Use Artwork = false` before play restores the old drawn body. No texture on an existing Artwork node also uses the placeholder. No new F1 controls or UI.

The picture is a frontal character illustration. It stays upright; no mouse-facing whole-body rotation or mirrored book/staff. Small ornamental details are not reliably readable at gameplay scale. The staff and book are cosmetic parts of this picture, independent of run equipment. Projectiles still originate at player position + shot direction × 25, not at a newly defined illustrated staff tip. No skill, collision or gear changes were made to match the art.

A final sprite needs a consistent elevated 3/4 view, simpler small-scale silhouette/details, compatible hand/cast anchors and a small, coherent directional/animation set. This prototype does not approve the final Apprentice design or the rest of roadmap A1.
