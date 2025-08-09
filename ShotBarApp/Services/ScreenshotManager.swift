import Foundation
import SwiftUI
import ScreenCaptureKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import AppKit

// MARK: - Screenshot Manager (ScreenCaptureKit)

final class ScreenshotManager: ObservableObject {
    @Published var saveDirectory: URL?
    private let toast = Toast()
    private var prefs: Preferences { AppServices.shared.prefs }
    
    // MARK: Save location
    
    func refreshSaveDirectory() {
        saveDirectory = macOSScreenshotDirectory() ?? defaultDesktop()
    }
    
    func revealSaveLocationInFinder() {
        let dir = saveDirectory ?? macOSScreenshotDirectory() ?? defaultDesktop()
        NSWorkspace.shared.activateFileViewerSelecting([dir])
    }
    
    // MARK: Entry points
    
    func captureSelection() {
        SelectionOverlay.present { [weak self] selection, screen in
            guard let self, let selection, let screen else { return }
            Task {
                do {
                    let cg = try await self.captureDisplayRegion(selection: selection, on: screen)
                    self.saveAccordingToPreferences(cgImage: cg, suffix: "Selection")
                } catch {
                    DispatchQueue.main.async {
                        self.toast.show(text: "Selection failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func captureActiveWindow() {
        Task {
            do {
                guard let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
                    DispatchQueue.main.async {
                        self.toast.show(text: "No active app window")
                    }
                    return
                }
                let content = try await SCShareableContent.current
                let windows = content.windows.filter { win in
                    guard let app = win.owningApplication else { return false }
                    return app.processID == frontPID && win.isOnScreen
                }
                guard let target = windows.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
                    DispatchQueue.main.async {
                        self.toast.show(text: "No captureable window")
                    }
                    return
                }
                let filter = SCContentFilter(desktopIndependentWindow: target)
                let config = SCStreamConfiguration()
                // Render at window size in pixels
                let pxSize = pixelSize(forWindowFrame: target.frame)
                config.width = pxSize.width
                config.height = pxSize.height
                let cg = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                self.saveAccordingToPreferences(cgImage: cg, suffix: "Window")
            } catch {
                DispatchQueue.main.async {
                    self.toast.show(text: "Window failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func captureFullScreens() {
        Task {
            do {
                let content = try await SCShareableContent.current
                let displays = content.displays
                if displays.isEmpty {
                    DispatchQueue.main.async {
                        self.toast.show(text: "No displays")
                    }
                    return
                }
                var saved = 0
                for (i, d) in displays.enumerated() {
                    let filter = SCContentFilter(display: d, excludingWindows: [])
                    let config = SCStreamConfiguration()
                    let px = pixelSize(forDisplay: d)
                    config.width = px.width
                    config.height = px.height
                    let cg = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                    let suffix = displays.count > 1 ? "Display\(i+1)" : "Screen"
                    self.saveAccordingToPreferences(cgImage: cg, suffix: suffix)
                    saved += 1
                }
                if saved == 0 {
                    DispatchQueue.main.async {
                        self.toast.show(text: "Full screen capture failed")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.toast.show(text: "Full screen failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: SCK helpers
    
    private func captureDisplayRegion(selection: CGRect, on screen: NSScreen) async throws -> CGImage {
        let content = try await SCShareableContent.current
        
        // Map NSScreen -> SCDisplay via CGDirectDisplayID
        guard
            let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else {
            throw NSError(domain: "ShotBar", code: -10, userInfo: [NSLocalizedDescriptionKey: "No display ID"])
        }
        let displayID = CGDirectDisplayID(num.uint32Value)
        
        guard let scDisplay = content.displays.first(where: { $0.displayID == displayID }) else {
            throw NSError(domain: "ShotBar", code: -10, userInfo: [NSLocalizedDescriptionKey: "Display mapping failed"])
        }
        
        // True pixels per point (robust on scaled/Sidecar displays)
        let pxPerPtX = CGFloat(CGDisplayPixelsWide(displayID))  / screen.frame.width
        let pxPerPtY = CGFloat(CGDisplayPixelsHigh(displayID)) / screen.frame.height
        
        // selection is in GLOBAL points → make it screen-local points
        var local = selection
        local.origin.x -= screen.frame.minX
        local.origin.y -= screen.frame.minY
        
        // Convert to display-local PIXELS (origin = TOP-LEFT)
        let pixelX = Int((local.origin.x * pxPerPtX).rounded(.towardZero))
        let pixelW = Int((local.size.width * pxPerPtX).rounded(.towardZero))
        let pixelH = Int((local.size.height * pxPerPtY).rounded(.towardZero))
        
        // Y: distance from top to TOP edge of the selection
        let pixelYFromTop = Int(((screen.frame.height - (local.origin.y + local.size.height)) * pxPerPtY)
            .rounded(.towardZero))
        
        guard pixelW >= 4, pixelH >= 4 else {
            throw NSError(domain: "ShotBar", code: -11, userInfo: [NSLocalizedDescriptionKey: "Selection too small"])
        }
        
        let filter = SCContentFilter(display: scDisplay, excludingWindows: [])
        let cfg = SCStreamConfiguration()
        cfg.sourceRect = CGRect(x: pixelX, y: pixelYFromTop, width: pixelW, height: pixelH)
        cfg.width  = pixelW
        cfg.height = pixelH
        
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg)
    }
    
    static func promptForPermissionIfNeeded() {
        // There isn't a dedicated SCK authorization API; touching SCK triggers the system prompt.
        Task {
            _ = try? await SCShareableContent.current
        }
    }
    
    private func pixelSize(forDisplay d: SCDisplay) -> (width: Int, height: Int) {
        // SCDisplay provides a frame in points; convert using NSScreen matching displayID.
        if let ns = NSScreen.screens.first(where: {
            ((($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value) == d.displayID)
        }) {
            let s = ns.backingScaleFactor
            let w = Int((ns.frame.width * s).rounded(.toNearestOrEven))
            let h = Int((ns.frame.height * s).rounded(.toNearestOrEven))
            return (w, h)
        }
        // Fallback: common 1x assumption (shouldn't happen on modern macOS)
        let w = Int(d.frame.width)
        let h = Int(d.frame.height)
        return (w, h)
    }
    
    private func pixelSize(forWindowFrame frame: CGRect) -> (width: Int, height: Int) {
        // Use main screen scale as a reasonable default
        let s = NSScreen.main?.backingScaleFactor ?? 2.0
        let w = Int((frame.width * s).rounded(.toNearestOrEven))
        let h = Int((frame.height * s).rounded(.toNearestOrEven))
        return (w, h)
    }
    
    // MARK: Saving
    
    private func saveAccordingToPreferences(cgImage: CGImage, suffix: String) {
        switch prefs.destination {
        case .clipboard:
            self.saveToClipboard(cgImage: cgImage)
        case .file:
            self.save(cgImage: cgImage, suffix: suffix)
        }
    }
    
    private func saveToClipboard(cgImage: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Convert CGImage to NSImage for clipboard
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        
        if pasteboard.writeObjects([nsImage]) {
            DispatchQueue.main.async { [weak self] in
                self?.toast.show(text: "Screenshot copied to clipboard")
                self?.playShutterSoundIfEnabled()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.toast.show(text: "Failed to copy to clipboard")
            }
        }
    }
    
    private func save(cgImage: CGImage, suffix: String) {
        let dir = saveDirectory ?? macOSScreenshotDirectory() ?? defaultDesktop()
        let ext = (prefs.imageFormat == .png) ? "png" : "jpg"
        let url = dir.appendingPathComponent(filename(suffix: suffix)).appendingPathExtension(ext)
        
        do {
            // Ensure directory exists and is writable
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            
            // Try to save the PNG
            switch prefs.imageFormat {
            case .png: try savePNG(cgImage: cgImage, to: url)
            case .jpg: try saveJPG(cgImage: cgImage, to: url, quality: 0.92)
            }
            DispatchQueue.main.async { [weak self] in
                self?.toast.show(text: "Saved \(url.lastPathComponent)")
                self?.playShutterSoundIfEnabled()
            }
        } catch {
            // Fallback to Desktop if the preferred location fails
            let ext = (prefs.imageFormat == .png) ? "png" : "jpg"
            let fallbackURL = defaultDesktop().appendingPathComponent(filename(suffix: suffix)).appendingPathExtension(ext)
            do {
                switch prefs.imageFormat {
                case .png: try savePNG(cgImage: cgImage, to: fallbackURL)
                case .jpg: try saveJPG(cgImage: cgImage, to: fallbackURL, quality: 0.92)
                }
                DispatchQueue.main.async { [weak self] in
                    self?.toast.show(text: "Saved to Desktop: \(fallbackURL.lastPathComponent)")
                    self?.playShutterSoundIfEnabled()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.toast.show(text: "Save failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func filename(suffix: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Screenshot \(df.string(from: Date())) \(suffix)"
    }
    
    private func savePNG(cgImage: CGImage, to url: URL) throws {
        let uti = UTType.png.identifier as CFString
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else {
            throw NSError(domain: "ShotBar", code: -1, userInfo: [NSLocalizedDescriptionKey: "CGImageDestinationCreateWithURL failed"])
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        if !CGImageDestinationFinalize(dest) {
            throw NSError(domain: "ShotBar", code: -2, userInfo: [NSLocalizedDescriptionKey: "CGImageDestinationFinalize failed"])
        }
    }
    
    private func saveJPG(cgImage: CGImage, to url: URL, quality: Double) throws {
        let uti = UTType.jpeg.identifier as CFString
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else {
            throw NSError(domain: "ShotBar", code: -1, userInfo: [NSLocalizedDescriptionKey: "CGImageDestinationCreateWithURL failed"])
        }
        let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        if !CGImageDestinationFinalize(dest) {
            throw NSError(domain: "ShotBar", code: -2, userInfo: [NSLocalizedDescriptionKey: "CGImageDestinationFinalize failed"])
        }
    }
    
    private func playShutterSoundIfEnabled() {
        guard AppServices.shared.prefs.soundEnabled else { return }
        NSSound(named: NSSound.Name("Tink"))?.play()
    }
    
    private func defaultDesktop() -> URL {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    }
    
    private func macOSScreenshotDirectory() -> URL? {
        let domain = "com.apple.screencapture" as CFString
        if let v = CFPreferencesCopyAppValue("location" as CFString, domain) {
            if CFGetTypeID(v) == CFStringGetTypeID() {
                return URL(fileURLWithPath: v as! String, isDirectory: true)
            } else if CFGetTypeID(v) == CFURLGetTypeID() {
                return (v as! URL)
            }
        }
        return nil
    }
}
