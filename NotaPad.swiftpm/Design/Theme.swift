// Theme.swift
// Zweck: zentrale Design-Tokens (Plan 4.2). Im restlichen Code keine festen Abstände/Radien/Farben.
import SwiftUI

enum Theme {
    /// 8-Punkt-Raster
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20   // Seitenrand
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let huge: CGFloat = 48
    }

    /// Eckradien (immer .continuous = Apple-Squircle)
    enum Radius {
        static let cover: CGFloat = 10
        static let card: CGFloat = 14
        static let popover: CGFloat = 22
    }

    /// Mindestgrößen für Trefferflächen (HIG)
    enum Hit {
        static let minimum: CGFloat = 44
        static let tool: CGFloat = 48
    }

    /// Papierfarben (getrennt von der UI-Palette)
    enum Paper {
        static let white = "#FFFFFF"
        static let ivory = "#FBF8F1"
        static let lightGray = "#F4F4F4"
        static let slate = "#2C2C2E"
        static let black = "#1C1C1E"
    }

    /// Standard-Coverfarbe
    static let defaultCoverHex = "#3A6FD8"

    /// Animationen
    enum Motion {
        static let standard: Animation = .smooth(duration: 0.3)
        static let toolSwitch: Animation = .snappy(duration: 0.25)
    }
}

extension RoundedRectangle {
    /// Squircle mit Token-Radius
    static func nota(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
