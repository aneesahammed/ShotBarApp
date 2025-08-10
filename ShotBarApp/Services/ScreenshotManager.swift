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
    
    // Add property to store the previous active application
    private var previousActiveApp: NSRunningApplication?
    
    // MARK: Save location
    
    func refreshSaveDirectory() {
        // Use the app's Documents directory instead of Desktop to avoid permission issues
        // The Desktop directory requires special entitlements and can cause sandbox permission errors
        // The Documents directory is always accessible within the app's sandbox
        let documentsDir = appDocumentsDirectory()
        saveDirectory = documentsDir
        print("Save directory set to: \(documentsDir.path)")
    }
    
    func revealSaveLocationInFinder() {
        // Always reveal the app's Documents directory where screenshots are saved
        let dir = appDocumentsDirectory()
        NSWorkspace.shared.activateFileViewerSelecting([dir])
        // Hide the menu bar popover after revealing folder
        hideMenuBarPopover()
    }
    
    // MARK: Entry points
    
    func captureSelection() {
        SelectionOverlay.present { [weak self] selection, screen in
            guard let self, let selection, let screen else { return }
            Task { @MainActor in
                do {
                    let cg = try await self.captureDisplayRegion(selection: selection, on: screen)
                    self.saveAccordingToPreferences(cgImage: cg, suffix: "Selection")
                    // Hide the menu bar popover after capture
                    self.hideMenuBarPopover()
                } catch {
                    self.toast.show(text: "Selection failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Make this method public so it can be called before the menubar becomes active
    func storePreviousActiveApp() {
        // Store the current frontmost app before our menubar becomes active
        previousActiveApp = NSWorkspace.shared.frontmostApplication
    }
    
    func captureActiveWindow() {
        Task { @MainActor in
            do {
                let content = try await SCShareableContent.current
                
                // Get the current ShotBar app bundle identifier to exclude it
                let currentAppBundleID = Bundle.main.bundleIdentifier ?? "com.shotbarapp.ShotBarApp"
                
                // Filter windows to exclude ShotBar and system windows, prioritize user applications
                let windows = content.windows.filter { win in
                    guard let app = win.owningApplication else { return false }
                    
                    // Exclude ShotBar app itself
                    if app.bundleIdentifier == currentAppBundleID { return false }
                    
                    // Exclude system windows and utilities
                    if app.bundleIdentifier.hasPrefix("com.apple.") { return false }
                    if app.bundleIdentifier.hasPrefix("com.apple.systempreferences") { return false }
                    if app.bundleIdentifier.hasPrefix("com.apple.dt.") { return false }
                    
                    // Only include on-screen windows with reasonable sizes
                    return win.isOnScreen && 
                           win.frame.width > 100 && 
                           win.frame.height > 100 &&
                           win.frame.width < 10000 && 
                           win.frame.height < 10000
                }
                
                // If we have a stored previous active app, prioritize its windows
                var sortedWindows = windows
                if let previousApp = previousActiveApp {
                    sortedWindows = windows.sorted { win1, win2 in
                        let isWin1FromPreviousApp = win1.owningApplication?.bundleIdentifier == previousApp.bundleIdentifier
                        let isWin2FromPreviousApp = win2.owningApplication?.bundleIdentifier == previousApp.bundleIdentifier
                        
                        // Prioritize windows from the previous active app
                        if isWin1FromPreviousApp && !isWin2FromPreviousApp {
                            return true
                        }
                        if !isWin1FromPreviousApp && isWin2FromPreviousApp {
                            return false
                        }
                        
                        // If both are from the same app, use the existing sorting logic
                        // Prioritize larger windows (likely main app windows)
                        let size1 = win1.frame.width * win1.frame.height
                        let size2 = win2.frame.width * win2.frame.height
                        
                        // If size difference is significant, prefer larger
                        if abs(size1 - size2) > 10000 {
                            return size1 > size2
                        }
                        
                        // Otherwise, prefer windows that are more centered on screen
                        let center1 = CGPoint(x: win1.frame.midX, y: win1.frame.midY)
                        let center2 = CGPoint(x: win2.frame.midX, y: win2.frame.midY)
                        let screenCenter = CGPoint(x: NSScreen.main?.frame.midX ?? 0, y: NSScreen.main?.frame.midY ?? 0)
                        
                        let distance1 = sqrt(pow(center1.x - screenCenter.x, 2) + pow(center1.y - screenCenter.y, 2))
                        let distance2 = sqrt(pow(center2.x - screenCenter.x, 2) + pow(center2.y - screenCenter.y, 2))
                        
                        return distance1 < distance2
                    }
                } else {
                    // Fall back to the original sorting logic if no previous app stored
                    sortedWindows = windows.sorted { win1, win2 in
                        // Prioritize larger windows (likely main app windows)
                        let size1 = win1.frame.width * win1.frame.height
                        let size2 = win2.frame.width * win2.frame.height
                        
                        // If size difference is significant, prefer larger
                        if abs(size1 - size2) > 10000 {
                            return size1 > size2
                        }
                        
                        // Otherwise, prefer windows that are more centered on screen
                        let center1 = CGPoint(x: win1.frame.midX, y: win1.frame.midY)
                        let center2 = CGPoint(x: win2.frame.midX, y: win2.frame.midY)
                        let screenCenter = CGPoint(x: NSScreen.main?.frame.midX ?? 0, y: NSScreen.main?.frame.midY ?? 0)
                        
                        let distance1 = sqrt(pow(center1.x - screenCenter.x, 2) + pow(center1.y - screenCenter.y, 2))
                        let distance2 = sqrt(pow(center2.x - screenCenter.x, 2) + pow(center2.y - screenCenter.y, 2))
                        
                        return distance1 < distance2
                    }
                }
                
                guard let target = sortedWindows.first else {
                    self.toast.show(text: "No captureable window found")
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
                // Hide the menu bar popover after capture
                self.hideMenuBarPopover()
            } catch {
                self.toast.show(text: "Window failed: \(error.localizedDescription)")
            }
        }
    }
    
    func captureFullScreens() {
        Task { @MainActor in
            do {
                let content = try await SCShareableContent.current
                let displays = content.displays
                if displays.isEmpty {
                    self.toast.show(text: "No displays")
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
                    self.toast.show(text: "Full screen capture failed")
                } else {
                    // Hide the menu bar popover after successful capture
                    self.hideMenuBarPopover()
                }
            } catch {
                self.toast.show(text: "Full screen failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Menu Management
    
    private func hideMenuBarPopover() {
        // Post notification to hide the menu bar popover
        // This will be handled by the AppDelegate to close the popover
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name("HideMenuBarPopover"), object: nil)
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
        let dir = saveDirectory ?? appDocumentsDirectory()
        let ext = (prefs.imageFormat == .png) ? "png" : "jpg"
        let url = dir.appendingPathComponent(filename(suffix: suffix)).appendingPathExtension(ext)
        
        print("Attempting to save screenshot to: \(url.path)")
        
        do {
            // Ensure directory exists and is writable
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            
            // Try to save the image
            switch prefs.imageFormat {
            case .png: try savePNG(cgImage: cgImage, to: url)
            case .jpg: try saveJPG(cgImage: cgImage, to: url, quality: 0.92)
            }
            print("Successfully saved screenshot to: \(url.path)")
            DispatchQueue.main.async { [weak self] in
                self?.toast.show(text: "Saved \(url.lastPathComponent)")
                self?.playShutterSoundIfEnabled()
            }
        } catch {
            // Log the error for debugging
            print("Save failed: \(error)")
            print("Save directory: \(dir.path)")
            print("Save URL: \(url.path)")
            
            // If saving to the preferred location fails, show error message
            DispatchQueue.main.async { [weak self] in
                self?.toast.show(text: "Save failed: \(error.localizedDescription)")
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
    
    private func appDocumentsDirectory() -> URL {
        // Get the app's Documents directory and ensure it exists
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Create the directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Warning: Could not create Documents directory: \(error)")
        }
        
        return documentsURL
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
