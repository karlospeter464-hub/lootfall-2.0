# Ashen Fields – isolierter Visual Depth Proof

Ein begrenzter Umgebungstest: ein gebrochener Ruinenpfeiler, ein großer Fels, Kontaktschatten und ein dezenter kühler Boden-Lichtverlauf. Ausschließlich neue Testdateien; keine produktive Integration, kein neuer Charakter und keine Kollisions-, Gameplay-, Restoration- oder Save-Änderung.

## Start

Aus dem Spielverzeichnis in PowerShell:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/visual-depth-user'
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/visual_depth/depth_slice.gd -- --test-mode
```

T schaltet BEFORE/AFTER um; WASD bewegt, Maus zielt, LMB zaubert. V behält seine vorhandenen Charaktermodi. --test-mode ist vor jeder Szeneninstanzierung zwingend; es isoliert die Testdaten. F5 behält die normale Hauptszene.

Für die Automation zusätzlich --verify (auch headless). Für native Vergleichsbilder --capture verwenden; optional --output=C:/path nach --test-mode. --frames-output=C:/path speichert jeden achten Physikframe als echtes Viewport-PNG. Der aufgezeichnete native Durchlauf verwendet --fixed-fps 60 und den normalen 1152×720-Bildschirm bei 1280×800 logischen Pixeln.

## Technik und Grenzen

Der vorhandene Visual-Slice-Harness liefert Testmodus, Prüfungen und Screenshots; die originale Arena wird unverändert instanziiert. Zwei Node2D-Zeichner verwenden die bestehenden Polygon-/Linientechniken. Ein Bodenpass zeichnet gerichtete weiche Kontaktschatten und einen niedrigen Alpha-Verlauf. Es gibt keine echten Schattenlichter, Normalmaps oder neue Renderpipeline. Die GradientTexture2D bleibt als Member referenziert; eine nur lokale Textur wurde beim ersten Versuch vor der Ausgabe freigegeben und erschien weiß. Dieser Fehler wurde vor den finalen Aufnahmen korrigiert.

Nur im Test: Player Z=2, Prop Z=3 hinter dem Prop-Fußpunkt / Z=1 davor. Gegner samt ihren im selben CanvasItem gezeichneten Warnflächen bleiben Z=4, Projektile Z=5. Dadurch ist die Spieler-Verdeckung demonstriert, aber ausdrücklich keine allgemeine Y-Sortierung der Gegnerwelt. Gegner können optisch vor hohen Objekten schweben. Bestehende Arena-Bodeneffekte sind weiter im Arena-Canvas. Props bleiben durchlaufbar, weil neue Kollisionen ausgeschlossen sind. Das ist ein Tiefen-/Lesbarkeitstest, keine vollständige Levelgeometrie.

BEFORE/AFTER kommen aus derselben laufenden Kampfsituation bei Physikframe 30. Für die zwei Aufnahmen wird ausschließlich der Szenenbaum pausiert und der Tiefenpass ausgeblendet/eingeblendet. Spieler-/Gegner-/Projektiltransforms, Aim, Leben, Kamera, RNG, Welle und Player-Visualclock bleiben laut Assertion identisch. Nach den Aufnahmen läuft der Kampf weiter. Gegner waren während des Bewegungstests aktiv; eingefroren wurde nur für den identischen Bildvergleich.

## Verifiziert am 27.10.2026

- 19 neue Headless-Prüfungen, 51 native D3D12-Prüfungen: keine Fehler. Vorhandener Visual-Lift-Test: 12 Prüfungen, keine Fehler. Interaktiver Startzweig separat nativ über 90 Frames ohne Fehler gestartet.
- Native Route: sieben Wegpunkte, 222 durch den Harness beobachtete Physikframes, ca. 898,33 logische Einheiten, hinter/vor beiden Props nachgewiesen; zwölf Gegner durchgehend aktiv. Elf echte Schüsse, neun Treffer, 62 tatsächlicher Schaden. Spielerleben am Ende 100 ohne Unverwundbarkeit oder Statänderung.
- 28 echte Viewport-PNGs bilden das 3,73-s-GIF; keine synthetische Bewegung oder interpolierten Bilder. PNGs 1152×720, normale Kamera. GIF nutzt nur Palettenkompression; Anzeigezeit auf 10-ms-GIF-Schritte gerundet.
- Bildprüfung: HUD und Bereiche außerhalb der Arena bytegleich; subtiler Lichtverlauf bleibt auf den Boden begrenzt, kein weißer Hintergrund. Repräsentative Frames für vorne/hinten gesichtet; sämtliche GIF-Frames vollständig dekodiert.

## Entscheidung – visuelle Iteration beendet

Die wahrgenommene Höhe und der Bodenkontakt nehmen sichtbar zu. Helle Oberseiten, dunkle Seiten, Kontaktzone und Spieler-Verdeckung liefern auch bei normaler Spielgröße räumliche Hinweise. Der Test zeigt: Die bestehende Godot-2D-Architektur kann diese Tiefe ohne Frameworkumbau darstellen.

Die beiden Props bleiben jedoch offensichtlich einfache geometrische Platzhalter. Insbesondere das große helle Felsfacet und der blockartige Pfeiler heben die Assetqualität noch nicht auf das gewünschte Dark-Fantasy-Niveau. Der weiche Schatten ersetzt keine gestaltete Steinoberfläche; Gegner-Überlagerung und Durchlaufbarkeit offenbaren den Testcharakter. Deshalb hier gestoppt, ohne weitere Effekte oder zusätzliche Props anzuhängen. Nicht als freigegebener Grafikumbau behandeln.

Nächste Entscheidung nach menschlichem Vergleich: ob eine einzelne besser ausgearbeitete Prop-Grafik in genau diesem Schichtaufbau einen gezielten Folgetest rechtfertigt. Keine automatische Assetserie, Biome-Überarbeitung oder produktive Integration. Kein Langzeit-Performancebenchmark, keine Veröffentlichung und kein Push.
