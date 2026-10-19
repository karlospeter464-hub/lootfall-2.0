# First external playtest — Windows v0.1

Gameplay remains the CE5 checkpoint **00e378d**. Feature freeze: no gameplay, balance, progression or save-format changes. Local source tags `playtest-v0.1-source-2026-10-19` mark both repositories before packaging. No upload, distribution, GitHub push or storefront deployment.

## Deliverable

ZIP: `C:/Users/elias/Lootfall 2.0/Exports/Playtest_v0.1/Lootfall_Prototype_Playtest_v0.1_Windows.zip` (outside both Git repositories).

| File at ZIP root | Bytes | Purpose |
| --- | ---: | --- |
| Lootfall.exe | 109168640 | Windows x86_64 release executable, no console wrapper |
| Lootfall.pck | 133712 | Exported game resources and configuration |
| README.txt | 1767 | Requirements, extraction/start instructions, controls and limitations |
| GODOT_LICENSES.txt | 112879 | Godot and bundled third-party license/copyright notices |

ZIP size: **39392635 bytes**. SHA-256: `5733779764BB4533F818797BB5F3853D49C3C9E2E18AF159899784E4570DE92D`. A fresh extraction was compared with the package: all four files byte-identical. No installed Godot is required on the tester's computer.

## Build

Godot **4.7.2 stable**, official matching standard export templates. Downloaded from the official godotengine/godot-builds 4.7.2-stable release and validated against its SHA512-SUMS.txt. Only the Windows x86_64 release template, its optional console helper and version marker were installed in a dedicated build APPDATA outside Git. The console helper is not distributed.

Preset `Windows Desktop` uses x86_64, separate PCK, release export and no signing. Tests, addons, local/editor configuration, JSON data and developer documents are excluded. The existing MCP export plugin removes its runtime autoload; the packed settings were checked. The console script remains a compiled dependency of arena.gd, but is not instantiated in release; there is no F1 hint or accessible developer UI. Existing debug test entry points require a debug runtime. No developer or test files are distributed at the ZIP root or under tests/addons in the PCK. Internal `.godot/exported`, imported icon and UID/class metadata are runtime resources produced by Godot, not copied editor/shader caches.

With matching templates installed, export using:

```powershell
& $godotExe --headless --path . --export-release 'Windows Desktop' 'C:/path/outside/git/Lootfall.exe'
```

For this build, APPDATA and TEMP/TMP were directed to dedicated ExportTools folders. The first sandboxed export returned exit 0 despite failing to write temporary project.binary; that output was rejected. Repeating with explicit build temp and appropriate write permissions completed with no export errors. No safe-save or Windows protection setting was disabled. Export logs and template downloads stay outside Git and outside the ZIP.

## Verification and exact limits

| Check | Result / runtime |
| --- | --- |
| Existing regression suites | **898 checks, 0 failures**, all twelve source suites, isolated profiles |
| Packed resource regression | **688 checks, 0 failures**: Arena 64, Inventory 50, Town 69, Ascent 249, Cards 128, Items 65, Early Progression 63. Actual exported PCK loaded by Godot editor/test executable; not the release executable. Covers cards, physical pickup/equipment, both bosses, new item effects, payout, purchase/refund, load and restart. |
| Export audit | **6 checks, 0 failures**, actual PCK/configuration, no MCP autoload, real game entry point, resource resolution and excluded data; audit script also passes Godot MCP validation |
| Executable | Windows PE machine 0x8664 verified; built with --export-release and official release template |
| Native release start | Actual Lootfall.exe with fresh isolated APPDATA opens Emberhaven at zero Echoes/talents. D3D12 on AMD Radeon RX 7600S. |
| Native release F1 | Pressed in Emberhaven: no console; footer has no F1 developer hint. |
| Native release run/input | Start Run, movement, aimed fireballs, enemies and a natural Hunter's Scepter ground drop observed in the actual EXE. |
| Native release death/result | Actual death in wave 1: result shows zero cleared waves, zero reward (correct), saved progress and working Return to Town; best wave 1 visible in town. Isolated progress.json written. |
| Full native release acceptance | **Not completed**: card selection, item pickup/equipping, boss fights/new effects, a positive Echoes payout, talent purchase and cross-process reloading of purchased progress still need a normal EXE playthrough. Their packed-resource regression passed; do not equate it with release acceptance. |

The attempted external `--script` smoke harness did not run in the standard release template (path overrides unavailable); it merely launched the normal game. These attempts are not counted as successful automated release checks. The experiment was moved outside the repository/package. Native Windows control was then stopped by the user's physical Escape key; no further Computer Use actions were taken. No screenshot or clip was archived for this export; existing CE5 screenshots remain historical previews.

Normal development saves were not deleted or used by the test processes. Dedicated source/packed-test profiles and `Exports/Playtest_v0.1/verification/native-user` were used. Diagnostic logs, test profiles, failed probes and extracted ZIP verification copies are outside the deliverable.

No known packaging/start blocker remains. Unsigned prototype, unfinished balance, wider hardware compatibility and the remaining native acceptance steps are explicit limits. The user distributes the ZIP manually.
