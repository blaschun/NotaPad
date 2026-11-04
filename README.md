# NotaPad

GoodNotes-ähnliche iPad-Notiz-App (Swift + SwiftUI, gebaut mit Swift Playgrounds auf dem iPad).
Gesamtplan: `C:\Users\serap\Desktop\NotaPad-Plan\NotaPad-Plan.md`

## Ablauf (Plan 2b, „Arbeitsablauf Windows → iPad")
1. **Einmalig auf dem iPad (T0.1):** Swift Playgrounds → „+ App" → Name `NotaPad` → in iCloud Drive/Playgrounds speichern.
   Die von Playgrounds erzeugten Dateien `ContentView.swift` und die Datei mit `@main` (z. B. `MyApp.swift`) **löschen** –
   `App/NotaPadApp.swift` aus diesem Repo ersetzt sie.
2. **Auf dem PC:** Code im Ordner `NotaPad.swiftpm\` bearbeiten, dann `tools\sync-to-icloud.ps1` ausführen.
   Das Skript kopiert alle Quellordner nach `iCloudDrive\Playgrounds\NotaPad.swiftpm` und fasst `Package.swift` nie an.
3. **Auf dem iPad:** Projekt öffnen → ▶. In der App oben rechts „Prüfliste" (Q1–Q20) ausfüllen.
4. Nie gleichzeitig am PC und am iPad am Code ändern (iCloud-Konfliktkopien).

## Stand
- P0: Repo, Kopierskript, SDK-Check (`Design/GlassCompat.swift`), Prüfliste-Ansicht (`Debug/PruefListeView.swift`)
- P1 Code geschrieben (T1.5–T1.14): Bibliothek, Seitenleiste, Raster/Liste, Sortieren, Ordner, Verschieben, Auswahlmodus, Papierkorb, Titelsuche, Editor-Platzhalter – noch NICHT auf dem iPad getestet
- Bundle-ID **nie ändern** (Daten hängen daran).
