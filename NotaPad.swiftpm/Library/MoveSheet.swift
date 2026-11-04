// MoveSheet.swift
// Zweck: "Verschieben …"-Sheet mit Ordnerbaum (T1.10, Plan 4c.1).
// Regeln: aktueller Ort ausgegraut; ein Ordner kann nicht in sich selbst oder seine Unterordner.
import SwiftUI
import SwiftData

struct MoveSheet: View {
    let items: [LibraryItem]
    let onMove: (Folder?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Folder> { $0.deletedAt == nil }, sort: \Folder.name) private var folders: [Folder]
    @State private var target: Folder?
    @State private var targetIsRoot = false
    @State private var errorMessage: String?

    private var service: LibraryService { LibraryService(context: context) }

    /// Aktueller Ort (nur eindeutig, wenn alle Elemente am selben Ort liegen)
    private var currentLocationIDs: Set<UUID?> {
        Set(items.map { item -> UUID? in
            switch item {
            case .folder(let f): return f.parent?.id
            case .notebook(let n): return n.folder?.id
            }
        })
    }

    private func isAllowed(_ folder: Folder?) -> Bool {
        for case .folder(let moved) in items {
            if service.isSelfOrDescendant(folder, of: moved) { return false }
        }
        if currentLocationIDs.count == 1, currentLocationIDs.first! == folder?.id { return false }
        return true
    }

    /// Ordner in Baumreihenfolge mit Einrückung
    private func flatten(_ parent: Folder?, depth: Int) -> [(Folder, Int)] {
        folders.filter { $0.parent?.id == parent?.id }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .flatMap { [($0, depth)] + flatten($0, depth: depth + 1) }
    }

    var body: some View {
        NavigationStack {
            List {
                row(title: "Dokumente (oberste Ebene)", symbol: "doc.on.doc", color: .accentColor,
                    depth: 0, allowed: isAllowed(nil), isSelected: targetIsRoot) { target = nil; targetIsRoot = true }
                ForEach(flatten(nil, depth: 0), id: \.0.id) { folder, depth in
                    row(title: folder.name, symbol: "folder.fill", color: Color(hex: folder.colorHex),
                        depth: depth, allowed: isAllowed(folder), isSelected: target?.id == folder.id) {
                        target = folder; targetIsRoot = false
                    }
                }
            }
            .navigationTitle("Verschieben")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Neuer Ordner", systemImage: "folder.badge.plus") {
                        do { target = try service.createFolder(name: "Neuer Ordner", in: target); targetIsRoot = false }
                        catch { errorMessage = error.localizedDescription }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Hierher verschieben") { onMove(target); dismiss() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!(targetIsRoot || target != nil))
                    .padding(Theme.Spacing.m)
            }
            .alert("Das hat nicht geklappt", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Verstanden", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(title: String, symbol: String, color: Color, depth: Int, allowed: Bool, isSelected: Bool,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label { Text(title) } icon: { Image(systemName: symbol).foregroundStyle(color) }
                Spacer()
                if isSelected { Image(systemName: "checkmark").foregroundStyle(Color.accentColor) }
            }
            .padding(.leading, CGFloat(depth) * 20)
            .frame(minHeight: Theme.Hit.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!allowed)
        .opacity(allowed ? 1 : 0.4)
    }
}
