// Toast.swift
// Zweck: Kurze Meldung unten (verschwindet von selbst), optional mit "Rückgängig" (Plan 4.2 / T1.9).
import SwiftUI

struct Toast: Identifiable {
    let id = UUID()
    let message: String
    var undo: (() -> Void)? = nil
}

struct ToastView: View {
    let toast: Toast
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text(toast.message).font(.subheadline)
            if let undo = toast.undo {
                Button("Rückgängig") { undo(); dismiss() }
                    .font(.subheadline.bold())
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.s)
        .notaGlass(cornerRadius: 30)
        .padding(.bottom, Theme.Spacing.xl)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task(id: toast.id) {
            try? await Task.sleep(for: .seconds(4))
            dismiss()
        }
    }
}
