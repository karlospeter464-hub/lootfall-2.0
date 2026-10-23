# Lootfall Alpha 0.2 - Windows release (2026-10-23)

Release/QA package; no gameplay, balancing or save-schema changes. Current local gameplay checkpoint **770fe86** includes all restoration/art/test-tool follow-ups. Alpha metadata is **0.2.0**, PE file/product version **0.2.0.0**. Existing application name/userdata path retained.

## Deliverable

ZIP: `C:/Users/elias/Lootfall 2.0/Exports/Playtest_v0.2/Lootfall_Alpha_v0.2_Windows.zip`.

Size: **39857009 bytes**. SHA-256: `67eb6a4d66acc3e541d7240ab0386de74e97eba9846167d0c59ded348bc58d1a`.

| File at ZIP root | Bytes |
| --- | ---: |
| ASSET_NOTICES.txt | 1106 |
| GODOT_LICENSES.txt | 112879 |
| Lootfall.exe | 109168640 |
| Lootfall.pck | 1963040 |
| README.txt | 2850 |

No installer/editor/account required. Extract everything and launch Lootfall.exe. Matching official Godot **4.7.2 stable Windows x86_64 release template**; stored archive SHA-512 verified against stored official checksums and installed template byte-compared against archive. No debug export or console wrapper. Windows 10/11 x64, Intel/AMD CPU, Direct3D 12 GPU/current driver, mouse and keyboard. 4 GB RAM/500 MB disk recommended; wider hardware not certified.

## Included features

Three regions, local records, persistent non-spendable Restoration, wave-end live healing, region unlocks and absolute overflow; 45 connected permanent talents with exact refunds; existing six cards/eight items/two recurring bosses and procedural visuals. Save v4 reads earlier valid v1-v3. Unfinished runs are not resumed; saved Restoration remains, Echoes settle at run end. Decorative terrain/water stays traversable. One playable mage, wave-100 safety limit. The test console and sandbox are not available to release players.

## Reproduce export

Use the existing Windows Desktop preset; APPDATA points to the dedicated ExportTools/appdata with matching templates, TEMP/TMP to a writable dedicated build-temp folder. Run:

```powershell
& $godotExe --headless --path $gamePath --export-release 'Windows Desktop' $outputExe
```

Source commands and original v0.1 notes remain in WINDOWS_PLAYTEST.md. Do not export over the v0.1 package. Tests/profiles, addons/MCP, editor caches, credentials, JSON/config/log data and developer documents are excluded. Internal .godot imported textures, baked scenes, UID/class metadata are required runtime data. dev_console.gdc is an inert preload dependency; runtime does not instantiate it and its test entry points reject release use.

## Verification and honest limits

| Check | Result |
| --- | --- |
| Source regression | **1272 checks / 17 suites, zero failures**, isolated APPDATA/test-mode |
| Exported-resource regression | **868 checks / 10 suites, zero failures**, editor/test executable loads final PCK from standalone package directory; no source-resource fallback |
| Final package audit | **8 checks, zero failures**; actual PCK, entry point/version, three regions/45 talents, excluded data, MCP autoload removed |
| Native release QA | **87 checks + 23 restart/frontier checks, zero failures**, D3D12 on AMD Radeon RX 7600S |
| Binary and ZIP | Windows PE machine 0x8664, version metadata correct; QA EXE byte-identical to shipped EXE; ZIP CRC, five-file allowlist, fresh extraction byte-compared |
| Normal release entry | Final EXE/PCK started separately with fresh isolated APPDATA; normal D3D12 startup log, no script/resource error. Fresh extracted ZIP additionally started with its normal entry point headlessly. |

Native QA executes a byte-identical copy of **the actual release EXE** with a separate QA entry PCK. That harness mounts the final game PCK and instantiates its actual arena, player/UI/enemies/items, using the same input settings. QA files are under verification/ only, never in the deliverable. This distinction matters: it exercises real release guards/runtime, but does not substitute for a complete human walkthrough of the uninstrumented shipped entry point.

Covered: fresh Emberhaven, Start/Explore button, movement and cast actions, aim calculation following the actual viewport pointer, physical pickup of all eight items and equip actions, I/Esc pause, Echo/Storm/Hunter/Phoenix effects, real enemy/boss scenes through ten programmed clears, cards/resume, live wave credits, death/result, Echoes payout, talent purchase, a second process reloading wallet/talent/world, actual healing tween/100% completion, both frontier unlocks and overflow, no duplicate settlement. Developer console, F1, sandbox, wallet and wave shortcuts are hidden/rejected in actual release runtime.

Not a natural human run: encounters/items/near-completion saves are fixtures, enemies cleared programmatically. Initial OS-window input attempts could not reach terminal-launched windows. On the user-requested retry the freshly extracted ZIP window became reachable: fresh Emberhaven/zero progress, F1 unavailable and Explore starting a real run were directly observed. User input then occurred; a live screenshot shows wave 2, combat and +4 Restoration, and the isolated save confirms points [4,0,0]. No further input was injected into the user's active session. This retry used --quit-after 3600 only as a test timeout; the normal ZIP launch has no such timeout. Mouse injection had coordinate ambiguity; an initial 'must point right' assertion failed, and was replaced by checking aim against the actual viewport pointer. The synthetic pointer could produce unrealistic coordinates; that assertion checks direction computation, not a complete real-device/window-focus acceptance run. **Complete manual EXE keyboard/mouse playthrough, long-session difficulty and broad hardware performance remain open.** No remaining game/packaging failure was found in the final automated checks.

Rejected diagnostics/attempts are retained in verification/: initial audit ran from the source directory and saw local files, so it was repeated standalone; standard release template rejects --script/--main-pack path overrides, so the independent QA copy uses an adjacent QA PCK without altering shipped files. Initial QA missed InputMap settings; harness corrected to match the game. Initial headless mouse check had no usable pointer. Known restricted-environment editor cache/settings and system certificate-store startup diagnostics are logged; no OS protection changed. Final release test logs have no GDScript/resource errors. No normal development saves were loaded or deleted.

## itch.io materials and licenses

`C:/Users/elias/Lootfall 2.0/Exports/Playtest_v0.2/itch_assets/`: six PNGs plus English description.md, download_and_start.md, changelog.md, known_limitations.md and screenshot_notes.md. All six are actual native release-runtime captures with controlled fixtures, including Life Returns and deep tree rows XII-XV; no fabricated trailer. Feedback URL is explicitly a placeholder.

Godot MIT/full bundled-library notices are in GODOT_LICENSES.txt. No habitat photographs or third-party music used as assets; MCP addon excluded. Optional owner-supplied mage illustration is still a bundled scene dependency while default visuals are procedural. Authoring provenance/separate redistribution license was not supplied; **the owner should confirm public redistribution rights before upload**. ASSET_NOTICES.txt records this without inventing licensing. Technical packaging is complete; this publication-rights question is open.

No itch.io publication, cloud upload, GitHub push, new paid service or additional installed app.
