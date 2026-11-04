// SettingsView.swift
// Zweck: Einstellungen (vorerst: Papierkorb-Dauer, Prüfliste). Wächst in P9 zum kompletten Menü (Plan 3.14).
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("trash.days") private var trashDays = 30

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Aufbewahrung: \(trashDays) Tage", value: $trashDays, in: 1...365)
                } header: {
                    Text("Papierkorb")
                } footer: {
                    Text("Gelöschte Elemente werden nach dieser Zeit endgültig entfernt.")
                }
                Section("Entwicklung") {
                    NavigationLink("Prüfliste (Swift Playgrounds)") { PruefListeView() }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
    }
}
