import AppKit

/// Generates the ShotBar menu bar template icon as a vector drawing.
/// The icon adapts automatically to light/dark mode via `isTemplate = true`.
enum MenuBarIcon {
    /// Returns a template NSImage sized appropriately for the menu bar.
    /// macOS typically renders menu bar icons at 18x18 points.
    static func makeTemplateIcon(size: CGFloat = 18) -> NSImage {
        let imageSize = NSSize(width: size, height: size)
        let image = NSImage(size: imageSize)
        image.lockFocus()

        // Use current label color; template images ignore actual color when drawn in status bar
        let strokeColor = NSColor.labelColor
        strokeColor.setStroke()
        strokeColor.setFill()

        // Coordinate helpers
        let scale = size / 18.0
        let lineWidth: CGFloat = 1.8 * scale
        let cornerRadius: CGFloat = 3.0 * scale

        // Draw a "selection" rounded rectangle inset
        let inset: CGFloat = 3.0 * scale
        let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
        let selectionPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        selectionPath.lineWidth = lineWidth
        selectionPath.stroke()

        // Draw corner ticks to imply selection handles
        let tickLength: CGFloat = 4.5 * scale
        let tickOffset: CGFloat = 1.0 * scale

        func drawCornerTick(at origin: NSPoint, dx: CGFloat, dy: CGFloat) {
            let path = NSBezierPath()
            path.lineWidth = lineWidth
            path.move(to: origin)
            path.line(to: NSPoint(x: origin.x + dx * (tickLength + tickOffset), y: origin.y))
            path.move(to: origin)
            path.line(to: NSPoint(x: origin.x, y: origin.y + dy * (tickLength + tickOffset)))
            path.stroke()
        }

        // Four corners (top-left, top-right, bottom-left, bottom-right)
        drawCornerTick(at: NSPoint(x: rect.minX, y: rect.maxY), dx: 1, dy: -1)
        drawCornerTick(at: NSPoint(x: rect.maxX, y: rect.maxY), dx: -1, dy: -1)
        drawCornerTick(at: NSPoint(x: rect.minX, y: rect.minY), dx: 1, dy: 1)
        drawCornerTick(at: NSPoint(x: rect.maxX, y: rect.minY), dx: -1, dy: 1)

        // Small "shutter" dot to hint screenshot/camera
        let dotDiameter: CGFloat = 3.2 * scale
        let dotRect = NSRect(
            x: rect.midX - dotDiameter / 2,
            y: rect.midY - dotDiameter / 2,
            width: dotDiameter,
            height: dotDiameter
        )
        let dotPath = NSBezierPath(ovalIn: dotRect)
        dotPath.fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
