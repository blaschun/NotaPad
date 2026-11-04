// SettingsView.swift
// Zweck: Einstellungen (vorerst: Papierkorb-Dauer, Notfall-Export, Prüfliste). Wächst in P9 zum kompletten Menü (Plan 3.14).
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("trash.days") private var trashDays = 30
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var exporting = false

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

                Section {
                    Button {
                        exporting = true
                        exportURL = nil
                        do { exportURL = try EmergencyExport.create(context: context) }
                        catch { exportError = error.localizedDescription }
                        exporting = false
                    } label: {
                        Label("Alle Daten exportieren", systemImage: "square.and.arrow.up.on.square")
                    }
                    .disabled(exporting)
                    if let exportURL {
                        ShareLink(item: exportURL) { Label("ZIP-Datei sichern …", systemImage: "square.and.arrow.up") }
                    }
                } header: {
                    Text("Speicher")
                } footer: {
                    Text("Packt alle Notizbücher in eine ZIP-Datei, die du in der Dateien-App sichern kannst. Mach das vor größeren Updates.")
                }

                Section("Entwicklung") {
                    NavigationLink("Prüfliste (Swift Playgrounds)") { PruefListeView() }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
            .alert("Export fehlgeschlagen", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("Verstanden", role: .cancel) {}
            } message: { Text(exportError ?? "") }
        }
    }
}
