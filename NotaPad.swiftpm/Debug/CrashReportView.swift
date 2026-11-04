// CrashReportView.swift
// Zweck: Zeigt den Absturzbericht des letzten Starts (siehe CrashReporter). Text lässt sich markieren, kopieren und teilen.
import SwiftUI

struct CrashReportView: View {
    let report: String
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(report)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.m)
            }
            .navigationTitle("Letzter Absturz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kopieren") { UIPasteboard.general.string = report }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: report)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Weiter zur App", action: onContinue).buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
