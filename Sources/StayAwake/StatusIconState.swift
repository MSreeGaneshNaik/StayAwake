import Cocoa

enum StatusIconState {
    case off
    case on

    /// Drawn ourselves rather than loaded from a named SF Symbol or bundled
    /// asset: guaranteed to render regardless of OS build or bundle-resource
    /// resolution (a symbol-name lookup once silently returned nil here,
    /// leaving the status item blank and the app looking like it wasn't
    /// running). Marked as a template image so AppKit auto-tints it for
    /// light/dark menu bars and the pressed state, like a native icon.
    var icon: NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            // Open rim on top (flat), rounded base at the bottom — a mug silhouette,
            // not a dome. y increases upward in this (non-flipped) coordinate space.
            let cup = NSBezierPath()
            cup.move(to: NSPoint(x: 4, y: 13))
            cup.line(to: NSPoint(x: 4, y: 7))
            cup.curve(to: NSPoint(x: 9, y: 4), controlPoint1: NSPoint(x: 4, y: 5.2), controlPoint2: NSPoint(x: 6.3, y: 4))
            cup.curve(to: NSPoint(x: 14, y: 7), controlPoint1: NSPoint(x: 11.7, y: 4), controlPoint2: NSPoint(x: 14, y: 5.2))
            cup.line(to: NSPoint(x: 14, y: 13))
            cup.close() // straight line back to (4, 13): the open top rim
            cup.lineWidth = 1.4

            let handle = NSBezierPath()
            handle.appendArc(withCenter: NSPoint(x: 14.5, y: 8.5), radius: 2, startAngle: -90, endAngle: 90)
            handle.lineWidth = 1.4

            NSColor.black.set()
            if self == .on {
                cup.fill()

                let steam = NSBezierPath()
                steam.move(to: NSPoint(x: 6.5, y: 13.5))
                steam.curve(to: NSPoint(x: 8, y: 17), controlPoint1: NSPoint(x: 5.3, y: 14.7), controlPoint2: NSPoint(x: 9.2, y: 15.8))
                steam.move(to: NSPoint(x: 10.5, y: 13.5))
                steam.curve(to: NSPoint(x: 12, y: 17), controlPoint1: NSPoint(x: 9.3, y: 14.7), controlPoint2: NSPoint(x: 13.2, y: 15.8))
                steam.lineWidth = 1.0
                steam.stroke()
            }
            cup.stroke()
            handle.stroke()

            return true
        }
        image.isTemplate = true
        return image
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
