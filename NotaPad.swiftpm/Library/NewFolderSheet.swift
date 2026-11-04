// NewFolderSheet.swift
// Zweck: Neuer Ordner mit Name, Farbe und Symbol (T1.8, Plan 4c.2).
import SwiftUI

enum FolderStyleOptions {
    static let colors = ["#3A6FD8", "#2E9E5B", "#D7263D", "#F28C28", "#F2C230", "#8E5BD8",
                         "#E0589B", "#16A6B6", "#7A7A7A", "#A0522D", "#34495E", "#6BBF59"]
    static let symbols = ["folder.fill", "book.fill", "graduationcap.fill", "briefcase.fill", "house.fill", "heart.fill",
                          "star.fill", "music.note", "paintpalette.fill", "function", "atom", "globe.europe.africa.fill",
                          "laptopcomputer", "sportscourt.fill", "airplane", "cart.fill", "leaf.fill", "pawprint.fill",
                          "camera.fill", "gamecontroller.fill", "lightbulb.fill", "flask.fill", "text.book.closed.fill", "person.2.fill"]
}

struct NewFolderSheet: View {
    let parent: Folder?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = "Neuer Ordner"
    @State private var colorHex = FolderStyleOptions.colors[0]
    @State private var symbol = "folder.fill"
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($focused)
                }
                Section("Farbe") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Theme.Spacing.m) {
                        ForEach(FolderStyleOptions.colors, id: \.self) { hex in
                            Button { colorHex = hex } label: {
                                Circle().fill(Color(hex: hex)).frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.primary, lineWidth: colorHex == hex ? 3 : 0).padding(-3))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Farbe \(hex)")
                        }
                    }
                }
                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Theme.Spacing.m) {
                        ForEach(FolderStyleOptions.symbols, id: \.self) { s in
                            Button { symbol = s } label: {
                                Image(systemName: s).font(.title3).frame(width: 44, height: 44)
                                    .foregroundStyle(symbol == s ? Color.white : Color(hex: colorHex))
                                    .background(RoundedRectangle.nota(10).fill(symbol == s ? Color(hex: colorHex) : Color.clear))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(s)
                        }
                    }
                }
            }
            .navigationTitle("Neuer Ordner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        do {
                            try LibraryService(context: context).createFolder(name: name, colorHex: colorHex, symbol: symbol, in: parent)
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                }
            }
            .alert("Das hat nicht geklappt", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Verstanden", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
            .onAppear { focused = true }
        }
        .presentationDetents([.large])
    }
}
