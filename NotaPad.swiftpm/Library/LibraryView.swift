// LibraryView.swift
// Zweck: Wurzel der Bibliothek: Seitenleiste + Inhalt, öffnet Notizbücher im Editor (T1.5 / T1.14).
import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("trash.days") private var trashDays = 30
    @State private var selection: SidebarItem = .documents
    @State private var openNotebook: Notebook?
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, showSettings: $showSettings)
        } detail: {
            LibraryContentView(selection: $selection, openNotebook: $openNotebook)
        }
        .fullScreenCover(item: $openNotebook) { notebook in
            EditorView(notebook: notebook)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear { CrashReporter.step = "Bibliothek wird angezeigt" }
        .task {
            CrashReporter.step = "Bibliothek: Papierkorb aufräumen"
            // Papierkorb aufräumen beim Start (Plan 5.9)
            try? LibraryService(context: context).purgeExpired(days: trashDays)
        }
    }
}
