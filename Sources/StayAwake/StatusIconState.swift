import Foundation

enum StatusIconState {
    case off
    case on

    /// A plain-text glyph rather than an SF Symbol image: guaranteed to render
    /// even if a symbol name doesn't resolve on a given OS build, which would
    /// otherwise leave the status item blank and effectively invisible.
    var menuBarGlyph: String {
        switch self {
        case .off: return "☕"
        case .on: return "☕●"
        }
    }

    var menuTitle: String {
        switch self {
        case .off: return "Stay Awake"
        case .on: return "Stay Awake ✓"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .off: return "Stay Awake is off"
        case .on: return "Stay Awake is on"
        }
    }
}
