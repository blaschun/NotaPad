// NotaPadApp.swift
// Zweck: Einstiegspunkt. Zeigt zuerst einen eventuellen Absturzbericht, baut dann (erst danach!) den SwiftData-Container.
// Schlägt das fehl, wird der Fehler angezeigt statt abzustürzen (T1.4).
// Hinweis: Die von Swift Playgrounds erzeugte @main-Datei und ContentView.swift müssen gelöscht sein (siehe README).
import SwiftUI
import SwiftData

@main
struct NotaPadApp: App {
    @State private var report: String? = CrashReporter.prepare()
    @State private var containerResult: Result<ModelContainer, Error>?

    var body: some Scene {
        WindowGroup {
            if let report {
                CrashReportView(report: report) { self.report = nil }
            } else {
                switch containerResult {
                case nil:
                    ProgressView("Lade …")
                        .onAppear {
                            CrashReporter.step = "Datenbank (SwiftData) wird geöffnet"
                            containerResult = Result { try ModelContainer(for: Folder.self, Notebook.self, Page.self) }
                            CrashReporter.step = "Datenbank geöffnet"
                        }
                case .success(let container)?:
                    LibraryView()
                        .modelContainer(container)
                case .failure(let error)?:
                    ContentUnavailableView(
                        "Daten konnten nicht geladen werden",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                }
            }
        }
    }
}
