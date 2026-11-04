// NotaPadApp.swift
// Zweck: Einstiegspunkt. Baut den SwiftData-Container; schlägt das fehl, wird der Fehler angezeigt statt abzustürzen (T1.4).
// Hinweis: Die von Swift Playgrounds erzeugte @main-Datei und ContentView.swift müssen gelöscht werden (siehe README).
import SwiftUI
import SwiftData

@main
struct NotaPadApp: App {
    private let containerResult: Result<ModelContainer, Error>

    init() {
        containerResult = Result {
            try ModelContainer(for: Folder.self, Notebook.self, Page.self)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let container):
                LibraryView()
                    .modelContainer(container)
            case .failure(let error):
                ContentUnavailableView(
                    "Daten konnten nicht geladen werden",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            }
        }
    }
}
