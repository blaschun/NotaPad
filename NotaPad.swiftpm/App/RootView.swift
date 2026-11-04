// RootView.swift
// Zweck: Platzhalter-Startbildschirm "Hallo NotaPad" (Abnahme P0) mit Zugang zur Prüfliste.
// Wird in T1.5 durch die Bibliothek (LibraryView) ersetzt.
import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var notebooks: [Notebook]

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.m) {
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text("Hallo NotaPad")
                    .font(.largeTitle.bold())
                Text("\(notebooks.count) Notizbücher gespeichert")
                    .foregroundStyle(.secondary)
                Text(GlassSupport.description)
                    .font(.footnote)
                    .padding(Theme.Spacing.s)
                    .notaGlass(cornerRadius: Theme.Radius.card)
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
            .toolbar {
                NavigationLink("Prüfliste") { PruefListeView() }
            }
        }
    }
}
