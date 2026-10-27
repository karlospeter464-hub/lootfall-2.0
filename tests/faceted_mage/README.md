# Facettierter Magier – isolierter Stiltest

Nutzerauftrag vom 27.10.2026: Steine kleiner, ihre Tiefe/Formsprache gefällt; Magier in derselben Richtung verbessern. Eigene codebasierte SVG-Zeichnung, keine Bearbeitung des Original-v01-PNGs, kein neues 3D-Modell und kein kostenpflichtiger Dienst.

## Start und Vergleich

Im Spielverzeichnis:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/faceted-mage-user'
& 'C:/Users/elias/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/faceted_mage/mage_slice.gd -- --test-mode
```

V wechselt neuer Magier / bisheriger Produktions-v01/A+; T blendet nur die Umgebungstestprops aus/ein. WASD/Maus/LMB bleiben original. F5 und normale Player-Szene unverändert. --test-mode ist zwingend und isoliert die Daten.

Der Test erbt den vorhandenen Visual-Depth-Harness und ergänzt dessen einmaligen Charakter-Setup-Schritt. --verify führt die echte Route/Kampfprüfungen aus, auch headless. --capture erzeugt before.png/after.png bei exakt demselben Spielzustand; --output=C:/path bestimmt den Ordner. --frames-output=C:/path speichert jeden achten Physikframe. Native Aufnahme mit --fixed-fps 60 bei 1600×1000; logische Arena 1280×800.

## Art und Integration

mage_faceted.svg: editierbare Originalzeichnung 320×400, durch Godots eingebauten SVG-Rasterizer mit Faktor zwei als 640×800 RGBA eingelesen; Mipmaps und lineare Minifikation. Kein neuer Import-/Asset-Generator nötig. Breite Hutkrempe mit sichtbarer Oberseite und dunkler Unterseite, silberne Haarflächen, heller linker Mantel und dunkle rechte Seite, rostrote Innenseite, getrennte Feuerzepter-Silhouette und offenes Buch mit heller Oberseite/dunklem Einband. Formsprache entspricht den prozeduralen Steinprops; Gesicht und Details sind absichtlich vereinfacht.

64 logische Pixel Alpha-Höhe, deklarierter Fußpunkt (320,750) im doppelt gerasterten Bild. Nur Artwork-Textur, Offset und Basismaßstab des instanziierten Players werden umgeschaltet. Produktionseigene AnimationPlayer-Impulse bleiben aktiv; Kandidat verwendet die originale Impulsbibliothek ohne den koordinatenspezifischen v01-Feuermasken-Shader. Fallback stellt v01-Textur, Fußpunkt, Skalierung, A+-Bibliothek und Shader vollständig wieder her. Prozeduraler Gameplay-Player, Signale, Kollision, Schussursprung, Cooldown, Skills/Items, Restoration und Saves unverändert.

Steinprops einschließlich gerichteter und Kontakt-Schatten jetzt 65 % der vorherigen Größe, Bodenpositionen unverändert. Der gemeinsame Harness nimmt das Vergleichspaar nun bei Frame 140 auf, damit Umgebung oder frühe Seer-Warnkreise das Zepter im Art-Vergleich nicht verdecken. Nur für beide Bilder wird die Simulation pausiert und ein neutraler Idle-Frame der jeweiligen Darstellung gewählt; anschließend läuft der Kampf weiter. Vollbilder und identischer Spielzustand bleiben der Nachweis, die 3×-Detailansicht ist ausdrücklich nur eine beschriftete Pixelvergrößerung.

## Prüfung und Bewertung

Final: 26 Headless-Checks für den Magier, 59 native Checks ohne Fehler. Gemeinsamer Tiefentest: 20 Headless-Checks, Produktions-Player-Art-Test: 24 Checks bestanden. Interaktiven neuen Startzweig zusätzlich 90 native Frames ohne Fehler gestartet. Fußanker, 64-Pixel-Höhe, Transparenz, V-Fallback, unveränderte Gameplaywerte, gleiche Zustände im Bildpaar, echte Move-/Cast-Animationen, sieben Wegpunkte und Vorder-/Hintergrundpassagen geprüft.

Native finale Route: zwölf Gegner durchgehend, elf Schüsse/neun Treffer, 62 tatsächlicher Schaden, ca. 898,33 logische Einheiten Bewegung, Spielerleben 100 ohne Statänderungen oder Unverwundbarkeit. 28 echte Viewport-PNGs bilden das 3,73-s-GIF; alle Frames dekodiert, repräsentative Frames und tatsächliche 1600×1000-Bilder gesichtet. Pixelgleiches HUD bestätigt. Kein menschlicher Run oder Performancebenchmark.

Ergebnis: konsistentere Flächenhelligkeiten und ein besser getrenntes offenes Buch; weniger weiches Textur-/Glührauschen als v01. Im Gegenzug stärker vereinfachtes, kantiges Gesicht und steifere Silhouette. Das ist ein Stilangebot zur visuellen Abnahme, kein objektiver Qualitätsbeweis und kein automatischer Produktionsersatz. Eine einzelne Blickrichtung bleibt, Ganze-Bild-Impulse ersetzen keine echten Bein-/Armzyklen. Gegner bleiben über Props, Warnflächen sichtbar, Props durchlaufbar. Weitere Richtungen/Rigging/produktive Integration nicht umgesetzt.
