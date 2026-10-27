# Vier Blickrichtungen – isolierter v01-Magier-Test

Expliziter Folgeauftrag vom 27.10.2026: Version 3 prüfen, um eine Grundlage für die Einschätzung weiterer Figuren zu haben. Vier echte Ansichten (vorne/unten, rechts, hinten/oben, links) folgen dem Zielvektor, unabhängig von WASD. Normales F5 bleibt beim bisherigen v01/A+.

## Start

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/mage-directions-user'
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/mage_four_directions/direction_slice.gd -- --test-mode
```

Alten Test schließen und diesen Starter verwenden. Maus um die Figur bewegen: Kopf und Körper wechseln gemeinsam die Blickrichtung. WASD bewegt unabhängig davon, LMB zaubert. V vergleicht vier Richtungen / bisheriges v01-A+, T blendet die Testprops aus/ein. Der Testmodus wird vor Szenenerzeugung verlangt; normale Saves werden nicht benutzt.

Automation: --verify auch headless; native --capture mit --fixed-fps 60 erzeugt before/after und front/right/back/left.png. Optional --output=C:/path und --frames-output=C:/path nach --test-mode. Fenster 1600×1000, Arena 1280×800 logisch, unveränderte Gameplay-Skripte.

## Bildquellen und Anpassung

Vorne ist das unveränderte Original unter assets/art/characters/apprentice/apprentice_v01.png. Drei zusätzliche Bilder wurden mit dem eingebauten Imagegen-Tool aus genau dieser Referenz erzeugt, jeweils ein separater Aufruf mit echtem transparentem Hintergrund. Kein CLI/API-Fallback, keine externen bezahlten Assetdienste. Vollständige Prompts und Modus in PROMPTS.md. Die originalen generierten PNGs bleiben unter source/{right,back,left}.png erhalten; keine gespiegelte Seite als Ersatz. Originale Toolausgaben unter C:/Users/elias/.codex/generated_images/01a17ef8-d824-7ab3-9b1c-57a4a07d1123/ ebenfalls bewahrt.

Laufzeit-Aufbereitung ausschließlich in Godot: gleichmäßige Skalierung/Platzierung auf transparentes 256×320-Canvas, manuell anhand der Boots und sichtbaren Körperhöhe kalibriert. Keine zusätzliche Neuzeichnung bei der Normalisierung. Gemeinsamer Fußanker (128,300), Zielhöhe ca. 64 logisch, Mipmaps und lineare Minifikation. Die hochauflösenden Rohquellen bleiben unverändert. Fußpunkte/Höhen stehen im DirectionVisual; sie sind spezifische Kalibrierung dieser Figur, keine automatische Lösung für beliebige Charaktere.

Jede Ansicht verwendet die vorhandene kontinuierliche 2D-Puppe mit Arm-/Buch-/Hutgelenk. Zusätzliche Ansichten haben eigene Gelenkpunkte, Einflussbereiche und etwas kleinere Gesten. Nur eine Ansicht rendert/verformt sich gleichzeitig; beim Wechsel wird die bestehende Cast-Altersinformation übernommen. Keine Gliedmaßen-Laufzyklen, keine getrennten Freistellungs-Lagen oder neue 3D-/Skeleton-Pipeline. Der gemeinsame Puppet-Code erlaubt nun genau die dafür benötigten Quellen/Anker/Gewichte, sein ursprünglicher Default bleibt bestehen.

## Richtungswahl und echte Prüfung

Der dominante Anteil des vorhandenen Player.aim entscheidet: unten/vorne, rechts, oben/hinten oder links. Eine kleine Winkeltoleranz verhindert Flackern nahe Diagonalen. Es wird nur die Darstellung ausgewählt; Schussrichtung, Schussursprung, Bewegung, Hitbox, Stats, Items, Skills, Gegner, Restoration und Save-Regeln bleiben im bestehenden Player/Arena-Code.

40 Headless-Prüfungen ohne Fehler; 79 native Prüfungen einschließlich Bildspeicherung erfolgreich. Bestehende Puppe 30, facettierter Test 26 und Produktions-Player-Art 24 ebenfalls bestanden. Neuer interaktiver Startzweig nativ 90 Frames ohne Fehler gestartet. Originalhash, transparente Quellen, alle vier Auswahlfälle, Diagonal-Toleranz, V-Fallback und feste Torso-/Fußpunkte überprüft. Jede der vier maximalen getesteten Gelenkposen ohne invertierte Dreiecke.

Automatisierte Aufnahme zielt zuerst in vier Hauptachsen, danach auf einen Guardian. Native Assertion bestätigt alle vier Ansichten während aktiver KI und seitliche Bewegung unabhängig vom Ziel. Zwölf Gegner durchgehend, zehn Schüsse/drei Treffer, 26 tatsächlicher Schaden, ca. 882,97 logische Einheiten, alle sieben Wegpunkte sowie Vor-/Hintergrundpassagen. Die geringere Trefferzahl stammt vom absichtlichen Schießen in vier Richtungen, nicht von anderen Stats. Eigenständiger Move-/Cast-AnimationPlayer beobachtet. 25 reale Vollbildframes bilden ein ca. 3,6-s-GIF; Anzeigeintervalle aus game.elapsed übernommen und auf 10-ms-GIF-Schritte gerundet. Keine interpolierten Bilder. Alle GIF-Frames dekodiert; native Richtungsbilder und Quelle bei Spielgröße gesichtet.

Der erste native Durchlauf deckte eine Testablauf-Schwäche auf: Vor dem Player-Physiktick gesetztes automatisches Aim wurde vom normalen Mauseingang überschrieben. Der gemeinsame Harness setzt die Testausrichtung jetzt nach dem Physiktick; Produktionssteuerung unverändert. Sampling-Zeitpunkte und Spielzeit werden mitgespeichert. Der historische JSON-Key physics_frames zählt Harness-Beobachtungsschritte, nicht jede zusätzlich während Frame-Speicherung vergangene Engine-Iteration.

BEFORE/AFTER bei gleichem pausiertem Kampfzustand aufgenommen. Vier zusätzliche Bilder ändern nur für die Galerie den Zielvektor, setzen je einen neutralen Gelenkframe und stellen ihn anschließend wieder her. four_views.png ist ein ausdrücklich beschrifteter 3×-Pixelcrop dieser echten Screenshots; Vollbilder erhalten. HUD pixelgleich.

## Ergebnis für weitere Figuren

Technisch übertragbar: Zielvektor → Ansicht, Winkeltoleranz, unabhängiges Laufen/Zielen, fester Fußpunkt und kleine Gelenkimpulse funktionieren mit der vorhandenen Architektur. Die Rückansicht vermittelt den Blick nach oben deutlich besser als ein bloß gekipptes Frontbild.

Art ist noch kein fertiges konsistentes Produktionsset. Generierte Bilder variieren in Hutform/Schnallenposition, Falten, Körperhaltung und Fußstellung; insbesondere die Rückenansicht trägt noch ein sichtbar anders platziertes Schnallendetail. Die linke/rechte Ansicht sind echte Seiten-/3/4-Ansichten, keine exakt orthogonalen Konstruktionszeichnungen. Richtungswechsel bleiben stufig; im Kostüm und der Silhouette kann es springen. Vier Blickrichtungen ersetzen keine neuen Laufzyklen. Meshgesten bleiben klein und können Stoff/Stab leicht verziehen.

Für andere Figuren sind weitere Ansichten, manuelle Größen-/Fußpunktkalibrierung, Gelenkgewichte und Sichtprüfung pro Figur erforderlich. Der Code ist wiederverwendbar; ein einzelnes Bild liefert nicht automatisch ein sauber animiertes Vier-Richtungen-Set. Diesen Proof erst menschlich beurteilen, bevor weitere Figuren oder acht Richtungen produziert werden. Keine produktive Übernahme, kein Export-/Langzeitbenchmark, kein Push/Release.
