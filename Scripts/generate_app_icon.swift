#!/usr/bin/env swift
import AppKit
import Foundation

struct IconSpec {
    let size: Int // point size
    let scale: Int // 1 or 2
}

let macIconSpecs: [IconSpec] = [
    IconSpec(size: 16, scale: 1),
    IconSpec(size: 16, scale: 2),
    IconSpec(size: 32, scale: 1),
    IconSpec(size: 32, scale: 2),
    IconSpec(size: 128, scale: 1),
    IconSpec(size: 128, scale: 2),
    IconSpec(size: 256, scale: 1),
    IconSpec(size: 256, scale: 2),
    IconSpec(size: 512, scale: 1),
    IconSpec(size: 512, scale: 2), // 1024px
]

let fileManager = FileManager.default
let currentDir = fileManager.currentDirectoryPath
let appIconDir = URL(fileURLWithPath: currentDir)
    .appendingPathComponent("ShotBarApp/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

func ensureDir(_ url: URL) throws {
    var isDir: ObjCBool = false
    if !fileManager.fileExists(atPath: url.path, isDirectory: &isDir) || !isDir.boolValue {
        throw NSError(domain: "generate_app_icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "AppIcon.appiconset not found at \(url.path)"])
    }
}

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
    return NSColor(calibratedRed: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
}

func drawAppIconBitmap(size pixels: Int) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Failed to create bitmap rep")
    }

    rep.size = NSSize(width: pixels, height: pixels) // 1 point == 1 pixel
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    defer {
        NSGraphicsContext.restoreGraphicsState()
    }

    let rect = NSRect(x: 0, y: 0, width: pixels, height: pixels)

    // Background: rounded square with subtle diagonal gradient
    let backgroundCornerRadius = CGFloat(pixels) * 0.223
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: backgroundCornerRadius, yRadius: backgroundCornerRadius)
    let gradient = NSGradient(colors: [
        color(98, 0, 234),   // Deep purple
        color(3, 155, 229)   // Light blue
    ])!
    gradient.draw(in: bgPath, angle: 60)

    // Foreground: selection rectangle with corner ticks and center dot
    let inset = CGFloat(pixels) * 0.18
    let selectionRect = rect.insetBy(dx: inset, dy: inset)
    let selectionCorner: CGFloat = CGFloat(pixels) * 0.08
    let lineWidth: CGFloat = max(CGFloat(pixels) * 0.045, 4)

    NSColor.white.setStroke()
    NSColor.white.setFill()

    let selection = NSBezierPath(roundedRect: selectionRect, xRadius: selectionCorner, yRadius: selectionCorner)
    selection.lineWidth = lineWidth
    selection.stroke()

    let tickLength: CGFloat = CGFloat(pixels) * 0.12
    let tickOffset: CGFloat = CGFloat(pixels) * 0.02

    func drawCornerTick(at origin: NSPoint, dx: CGFloat, dy: CGFloat) {
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.move(to: origin)
        path.line(to: NSPoint(x: origin.x + dx * (tickLength + tickOffset), y: origin.y))
        path.move(to: origin)
        path.line(to: NSPoint(x: origin.x, y: origin.y + dy * (tickLength + tickOffset)))
        path.stroke()
    }

    drawCornerTick(at: NSPoint(x: selectionRect.minX, y: selectionRect.maxY), dx: 1, dy: -1)
    drawCornerTick(at: NSPoint(x: selectionRect.maxX, y: selectionRect.maxY), dx: -1, dy: -1)
    drawCornerTick(at: NSPoint(x: selectionRect.minX, y: selectionRect.minY), dx: 1, dy: 1)
    drawCornerTick(at: NSPoint(x: selectionRect.maxX, y: selectionRect.minY), dx: -1, dy: 1)

    let dotDiameter: CGFloat = CGFloat(pixels) * 0.09
    let dotRect = NSRect(
        x: selectionRect.midX - dotDiameter / 2,
        y: selectionRect.midY - dotDiameter / 2,
        width: dotDiameter,
        height: dotDiameter
    )
    let dotPath = NSBezierPath(ovalIn: dotRect)
    dotPath.fill()

    return rep
}

func savePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "generate_app_icon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG for \(url.lastPathComponent)"])
    }
    try data.write(to: url)
}

func writeContentsJSON(files: [(filename: String, spec: IconSpec)], to url: URL) throws {
    struct ImageEntry: Codable {
        let filename: String
        let idiom: String
        let scale: String
        let size: String
    }
    struct Root: Codable {
        let images: [ImageEntry]
        struct Info: Codable { let author: String; let version: Int }
        let info: Info
    }

    let images = files.map { f in
        ImageEntry(
            filename: f.filename,
            idiom: "mac",
            scale: "\(f.spec.scale)x",
            size: "\(f.spec.size)x\(f.spec.size)"
        )
    }

    let root = Root(images: images, info: .init(author: "xcode", version: 1))
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(root)
    try data.write(to: url)
}

// Main

do {
    try ensureDir(appIconDir)

    var written: [(String, IconSpec)] = []

    for spec in macIconSpecs {
        let pixels = spec.size * spec.scale
        let rep = drawAppIconBitmap(size: pixels)
        let filename = "appicon_\(spec.size)@\(spec.scale)x.png"
        let outURL = appIconDir.appendingPathComponent(filename)
        try savePNG(rep, to: outURL)
        written.append((filename, spec))
        fputs("Wrote \(outURL.path)\n", stderr)
    }

    let contentsURL = appIconDir.appendingPathComponent("Contents.json")
    try writeContentsJSON(files: written, to: contentsURL)
    fputs("Updated Contents.json\n", stderr)

    // Also write a 1024 preview to repo root for reference
    let preview = drawAppIconBitmap(size: 1024)
    let previewURL = URL(fileURLWithPath: currentDir).appendingPathComponent("ShotBarApp_Icon_1024.png")
    try savePNG(preview, to: previewURL)
    fputs("Wrote preview to \(previewURL.path)\n", stderr)

} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
