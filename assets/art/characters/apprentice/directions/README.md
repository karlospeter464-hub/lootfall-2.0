# Approved directional Apprentice — 2026-10-28

Front uses the unchanged owner-supplied ../apprentice_v01.png. Left/right are the normalized reference-generated views from the approved isolated four-direction proof; generation prompts remain in tests/mage_four_directions/PROMPTS.md. Back uses the owner-approved review V2; its complete edit prompt is preserved in source/REVIEW_V2.md. No new generation during integration.

source/back_approved_v2.png is the exact approved 1122×1402 RGBA image (SHA256 528b6ea7f47c38a6c7ef41e14810955eacb149d4528551c2d3e833ff1a9c1537). Open cream inner pages face the viewer while the mage faces away. back.png is its lossless normalized 256×320 runtime canvas, using source foot (590,1295), height 1136, scale 274/1136 and Lanczos resampling in Godot. Same shared foot anchor (128,300), player scale 64/274 and collision radius15.

All runtime views use imported/preloaded Texture2D resources with mipmaps. scripts/apprentice_directions.gd selects one active mesh by mouse aim with diagonal hysteresis; apprentice_direction_puppet.gd calibrates local joints; mage_puppet.gd is the shared existing continuous mesh implementation. Idle/move/cast gestures are limited image deformation, not separate walking frames or a full skeletal rig. No external paid assets/tools and no inferred third-party license claims. Source remains prototype art pending any broader rights review.

F5 enables this renderer. V returns to v01/A+; Use Artwork=false preserves the procedural startup. Gameplay, saves, collision and projectile origin are unchanged. Environment proof objects remain test-only.
