// ToolOptionsPopover.swift
// Zweck: Einheitliches Options-Popover (Plan 4.5): Live-Vorschau · Haupt-Auswahl · Farbe · Stärke.
// Die Farbe/Stärke gehört immer zum gerade gewählten Favoriten-Platz der Unterleiste.
import SwiftUI

struct ToolOptionsPopover: View {
    @Bindable var tool: ToolState

    private let palette = ["#000000", "#3A3A3C", "#8E8E93", "#D7263D", "#F28C28", "#FFE14D",
                           "#7BE07B", "#2E9E5B", "#16A6B6", "#1F5FD6", "#8E5BD8", "#FF8AD8"]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            switch tool.settings.tool {
            case .pen:
                preview
                Picker("Stiftart", selection: $tool.settings.penKind) {
                    ForEach(PenKind.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                colorSection
                widthSection(range: 0.1...3)
            case .highlighter:
                preview
                colorSection
                widthSection(range: 1...15)
            case .eraser:
                Text("Radierer").font(.headline)
                Picker("Radieren auf", selection: $tool.settings.eraserTarget) {
                    ForEach(EraserTarget.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Text("Der Strich-Radierer entfernt ganze Striche. Weitere Arten folgen mit der eigenen Engine.")
                    .font(.footnote).foregroundStyle(.secondary)
            case .lasso:
                Text("Lasso").font(.headline)
            }
        }
        .padding(Theme.Spacing.m)
        .frame(width: 320)
    }

    private var preview: some View {
        Canvas { ctx, size in
            var path = Path()
            path.move(to: CGPoint(x: 16, y: size.height * 0.65))
            path.addCurve(to: CGPoint(x: size.width - 16, y: size.height * 0.35),
                          control1: CGPoint(x: size.width * 0.35, y: size.height * 0.1),
                          control2: CGPoint(x: size.width * 0.65, y: size.height * 0.95))
            let width = CGFloat(tool.widthMm * 72 / 25.4)
            let color = Color(hex: tool.colorHex).opacity(tool.settings.tool == .highlighter ? 0.45 : 1)
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
        .frame(height: 70)
        .background(RoundedRectangle.nota(Theme.Radius.card).fill(Color.white))
        .overlay(RoundedRectangle.nota(Theme.Radius.card).stroke(Color(.separator), lineWidth: 0.5))
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Farbe").font(.subheadline.weight(.semibold))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Theme.Spacing.xs) {
                ForEach(palette, id: \.self) { hex in
                    Button { tool.colorHex = hex } label: {
                        Circle().fill(Color(hex: hex)).frame(width: 34, height: 34)
                            .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: tool.colorHex.uppercased() == hex ? 3 : 0).padding(-3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Farbe \(hex)")
                }
            }
            ColorPicker("Eigene Farbe", selection: Binding(
                get: { Color(hex: tool.colorHex) },
                set: { tool.colorHex = $0.hexString() }
            ), supportsOpacity: false)
        }
    }

    private func widthSection(range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            HStack {
                Text("Stärke").font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.1f mm", tool.widthMm)).monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: Binding(get: { tool.widthMm }, set: { tool.widthMm = $0 }), in: range)
        }
    }
}
