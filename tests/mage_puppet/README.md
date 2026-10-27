# Original-v01 als bewegliche 2D-Puppe – isolierter Proof

Der Nutzer möchte die frühere Originalzeichnung als Referenz behalten und einzelne Bereiche bewegen, statt die Figur in einen anderen Zeichenstil zu ersetzen. Dieser Proof verwendet das bytegleiche Original-v01-PNG als Textur eines kontinuierlichen Polygon2D-Meshes. Keine Neuzeichnung, kein Blender-Modell, keine ausgeschnittenen/retuschierten Rasterdateien und keine kostenpflichtigen Dienste.

## Start

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/mage-puppet-user'
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/mage_puppet/puppet_slice.gd -- --test-mode
```

WASD/Maus/LMB wie bisher. V: Gelenk-Puppe ↔ bisheriges v01/A+ mit Ganzbildimpulsen. T: Testprops an/aus. F5 bleibt der bisherige Player. Der Testmodus wird vor der Szenenerzeugung verlangt; Save-/Restoration-Regeln bleiben unverändert.

Automation: --verify (auch headless); native --capture, optional --output=C:/path und --frames-output=C:/path nach --test-mode. Native Aufnahme mit --fixed-fps 60, Fenster 1600×1000. Der vorhandene Tiefen-/Kampfharness wird wiederverwendet und beobachtet den tatsächlich verwendeten AnimationPlayer.

## Wie einzelne Teile beweglich werden

Drei separat benannte Node2D-Gelenke in Originalbild-Koordinaten: ScepterArm um (99,164), BookHand um (169,188), HatTip um (128,105). Ein regelmäßiges Mesh mit 1.353 Vertices / 2.560 Dreiecken trägt unverändert die Originaltextur. Gewichtete Rotationen bewegen Zepterarm, Buch und Hutspitze, ohne das gesamte Bild zu drehen. Weiche Übergänge halten Schulter-/Ärmelanschlüsse zusammen; die Kernmitte und Fußpunkte sind ungewichtet. Es sind bewegliche Bildbereiche auf einem zusammenhängenden Mesh, noch keine vollständig freigestellten Einzelbilder.

Ein AnimationPlayer steuert Idle, Move und Cast auf den Gelenkrotationen. Originale echte Cast-Signale starten die kurze Zepterbewegung und gegenläufige Buchreaktion; keine neue Verzögerung oder Cooldownänderung. Die maximal geprüfte Geste bewegt den Arm um -0,18 rad, das Buch um +0,12 und die Hutspitze um -0,035 rad. Große Armschwenks/Richtungswechsel sind nicht freigegeben. Die normale Ganzbildanimation ist im Puppet-Modus ausgesetzt, die bestehende minimale Sprite-Atmung bleibt; Fußanker und 64-logischer-Pixel-Maßstab bleiben erhalten. Hurt-Tint wird weitergegeben. V stellt den ursprünglichen Sprite, A+-Animation und Shader wieder her.

Das Original wird im Puppet-Modus auf der Sprite2D nur durch eine transparente Platzhaltertextur unsichtbar gemacht; sein sichtbares Kind-Mesh verwendet dieselbe echte Originaltextur. Dadurch bleiben die vorhandene Player-Schatten-/Angriffslogik und der Physics-Body erhalten. Nur eine Blickrichtung, kein vollständiger Skeleton2D-/Retargeting- oder Asset-Framework-Umbau.

## Verifikation und Medien

- 30 Headless-Prüfungen ohne Fehler, 100 native Prüfungen einschließlich Speichern von Vorschau-/Gameplayframes ohne Fehler. Vorhandener facettierter Test 26 und Produktions-Player-Art 24 ebenfalls bestanden; neuer interaktiver Zweig nativ über 90 Frames gestartet.
- Original-PNG SHA256 weiterhin 831023c026176d2949e3e8a085148ea1cb79d72d1684a0b7977fbbead3053128. Neutralstellung des Meshes und eine normale Sprite2D derselben Textur im identischen GPU-Viewport sind RGBA-bytegleich. Fuß-/Torso-Testvertices bleiben in Cast-Pose unverändert; alle drei beweglichen Bereiche ändern ihre Position. Keine invertierten Dreiecke in der geprüften maximalen Cast-Pose.
- Ursprünglich harte Gewichtsgrenzen führten bei der Extrempose zu Dreiecksüberschlägen; geglättete Gewichte und Begrenzung an der Körpermitte haben den Testfehler behoben. Noch keine Aussage über beliebige größere Winkel.
- Echte native Route: zwölf aktive Gegner, elf Schüsse/neun Treffer, 62 Schaden, ca. 898,33 logische Einheiten Bewegung, sieben Wegpunkte und beide Vorder-/Hintergrundpassagen. Move/Cast am Puppet-AnimationPlayer beobachtet; Originalwerte, Hitbox, Schussursprung und Spielzustand des Vorher-/Nachher-Bildpaars erhalten.
- joints_preview.gif: links GPU-Original in Ruhe, rechts dieselbe echte Mesh-Puppe mit demonstrierten Gelenkposen. 36 gerenderte Vorschauposen, GIF fasst gleiche Nachbarbilder zu 31 Frames zusammen; 3 Sekunden, bewusst verlangsamte Gelenkdemonstration, keine menschliche Spielaufnahme.
- gameplay.gif: 28 echte 1600×1000-Viewportframes, ca. 3,73 Sekunden, aktive KI/Bewegung/echte Schüsse. Keine interpolierte Bewegung. Beide GIFs vollständig dekodiert; repräsentative Neutral-/Extrembilder gesichtet.

## Empfehlung und Grenzen

Der Original-Look bleibt erhalten, während Zepter, Buch und Hut tatsächlich getrennte Bewegungen erhalten. Das ist für kleine lebendige Gesten ein sinnvollerer Ansatz als ein stilistisch anderer neu gezeichneter Magier. Mesh-Verformung ersetzt jedoch keine verdeckten Flächen: Ärmel/Stab und Ausrüstung können sich leicht verziehen. Für deutlich größere Armbewegungen, Überkreuzen vor dem Körper oder neue Blickrichtungen braucht die Referenz sauber getrennte Teile und ergänzte verdeckte Körperflächen. Dann lassen sich die gleichen Gelenkideen auf richtige Cutout-Lagen übertragen.

Kein vollständiger Laufzyklus, keine Richtungsserie oder produktive Übernahme. Menschliche Abnahme und Langzeitperformance offen. Gegner-Prop-Überlagerung und durchlaufbare Testprops bleiben wie zuvor.
