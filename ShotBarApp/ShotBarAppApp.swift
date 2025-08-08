import SwiftUI
import AppKit
import Combine
import Carbon.HIToolbox
import ScreenCaptureKit
import CoreGraphics
import QuartzCore
import ImageIO
import UniformTypeIdentifiers

// MARK: - App Services (singletons to simplify wiring)

final class AppServices {
    static let shared = AppServices()

    let prefs = Preferences()
    let hotkeys = HotkeyManager()
    let shots = ScreenshotManager()

    private var cs = Set<AnyCancellable>()

    private init() {
        // Rebind hotkeys whenever prefs change.
        prefs.$selectionHotkey.merge(with: prefs.$windowHotkey, prefs.$screenHotkey)
            .sink { [weak self] _ in self?.rebindHotkeys() }
            .store(in: &cs)

        // Initial setup
        shots.refreshSaveDirectory()
        rebindHotkeys()
    }

    func rebindHotkeys() {
        hotkeys.unregisterAll()
        if let hk = prefs.selectionHotkey { hotkeys.register(id: .selection, hotkey: hk) { [weak self] in self?.shots.captureSelection() } }
        if let hk = prefs.windowHotkey    { hotkeys.register(id: .window,    hotkey: hk) { [weak self] in self?.shots.captureActiveWindow() } }
        if let hk = prefs.screenHotkey    { hotkeys.register(id: .screen,    hotkey: hk) { [weak self] in self?.shots.captureFullScreens() } }
    }
}

// MARK: - AppDelegate to run launch-time setup (Scene has no onAppear)

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = AppServices.shared // touch singletons to init
    }
}

// MARK: - App

@main
struct ShotBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let S = AppServices.shared

    var body: some Scene {
        // Menubar UI
        MenuBarExtra("ShotBar", systemImage: "camera.viewfinder") {
            VStack(alignment: .leading, spacing: 6) {
                Button("Capture Selection → Clipboard") { S.shots.captureSelection() }
                Button("Capture Active Window → File") { S.shots.captureActiveWindow() }
                Button("Capture Full Screen(s) → File") { S.shots.captureFullScreens() }
                Divider()
                Button("Reveal Save Folder") { S.shots.revealSaveLocationInFinder() }
                Divider()
                Button("Preferences…") { 
                    NSApp.keyWindow?.close()
                    // Give SwiftUI a moment to process the close
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApp.sendAction(Selector("showPreferencesWindow:"), to: nil, from: nil)
                    }
                }
                Button("Quit") { NSApp.terminate(nil) }
            }
            .padding(.vertical, 4)
            .frame(minWidth: 240)
        }
        .menuBarExtraStyle(.window)

        // Preferences window
        Settings {
            PreferencesView(prefs: S.prefs, shots: S.shots)
                .frame(width: 420)
        }
    }
}

// MARK: - Preferences Model

struct Hotkey: Codable, Equatable, Identifiable {
    var keyCode: UInt32
    var id: String { "kc-\(keyCode)" }

    static let allFKeys: [Hotkey] = [
        Hotkey(keyCode: UInt32(kVK_F1)),  Hotkey(keyCode: UInt32(kVK_F2)),
        Hotkey(keyCode: UInt32(kVK_F3)),  Hotkey(keyCode: UInt32(kVK_F4)),
        Hotkey(keyCode: UInt32(kVK_F5)),  Hotkey(keyCode: UInt32(kVK_F6)),
        Hotkey(keyCode: UInt32(kVK_F7)),  Hotkey(keyCode: UInt32(kVK_F8)),
        Hotkey(keyCode: UInt32(kVK_F9)),  Hotkey(keyCode: UInt32(kVK_F10)),
        Hotkey(keyCode: UInt32(kVK_F11)), Hotkey(keyCode: UInt32(kVK_F12)),
    ]

    var displayName: String {
        switch Int(keyCode) {
        case kVK_F1: return "F1";  case kVK_F2: return "F2";  case kVK_F3: return "F3"
        case kVK_F4: return "F4";  case kVK_F5: return "F5";  case kVK_F6: return "F6"
        case kVK_F7: return "F7";  case kVK_F8: return "F8";  case kVK_F9: return "F9"
        case kVK_F10: return "F10"; case kVK_F11: return "F11"; case kVK_F12: return "F12"
        default: return "KeyCode \(keyCode)"
        }
    }
}

final class Preferences: ObservableObject {
    @Published var selectionHotkey: Hotkey? { didSet { save() } }
    @Published var windowHotkey: Hotkey?    { didSet { save() } }
    @Published var screenHotkey: Hotkey?    { didSet { save() } }

    private let defaults = UserDefaults.standard

    init() {
        selectionHotkey = load(key: "selectionHotkey") ?? Hotkey(keyCode: UInt32(kVK_F1))
        windowHotkey    = load(key: "windowHotkey")    ?? Hotkey(keyCode: UInt32(kVK_F2))
        screenHotkey    = load(key: "screenHotkey")    ?? Hotkey(keyCode: UInt32(kVK_F3))
    }

    private func save() {
        save(selectionHotkey, key: "selectionHotkey")
        save(windowHotkey,    key: "windowHotkey")
        save(screenHotkey,    key: "screenHotkey")
    }

    private func save(_ hk: Hotkey?, key: String) {
        if let hk, let data = try? JSONEncoder().encode(hk) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func load(key: String) -> Hotkey? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Hotkey.self, from: data)
    }
}

// MARK: - Preferences UI

struct PreferencesView: View {
    @ObservedObject var prefs: Preferences
    @ObservedObject var shots: ScreenshotManager

    var body: some View {
        Form {
            Section("Save Location") {
                HStack {
                    Text(shots.saveDirectory?.path ?? "Using system screenshot folder")
                        .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    Spacer()
                    Button("Reveal") { shots.revealSaveLocationInFinder() }
                }
                Text("Honors macOS screenshot location (defaults domain com.apple.screencapture).")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Section("Hotkeys (global)") {
                HotkeyPickerRow(title: "Selection", selection: $prefs.selectionHotkey)
                HotkeyPickerRow(title: "Active Window", selection: $prefs.windowHotkey)
                HotkeyPickerRow(title: "Full Screen(s)", selection: $prefs.screenHotkey)
                Text("Tip: Some keyboards require holding Fn for F-keys unless you enable “Use F1, F2, etc. as standard function keys”.")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Section("Permissions") {
                Button("Check Screen Recording Permission") {
                    ScreenshotManager.promptForPermissionIfNeeded()
                }
                Text("If captures fail, grant Screen & System Audio Recording in System Settings → Privacy & Security.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct HotkeyPickerRow: View {
    let title: String
    @Binding var selection: Hotkey?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker("", selection: Binding(
                get: { selection?.id ?? "none" },
                set: { newID in
                    if newID == "none" { selection = nil }
                    else if let hk = Hotkey.allFKeys.first(where: { $0.id == newID }) { selection = hk }
                })) {
                    Text("None").tag("none")
                    ForEach(Hotkey.allFKeys) { hk in
                        Text(hk.displayName).tag(hk.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
        }
    }
}

// MARK: - Global hotkeys (Carbon)

enum HotkeyID: UInt32 { case selection = 1, window = 2, screen = 3 }

final class HotkeyManager: ObservableObject {
    private var eventHandler: EventHandlerRef?
    private var hotkeyRefs: [HotkeyID: EventHotKeyRef?] = [:]
    private var callbacks: [HotkeyID: () -> Void] = [:]

    func register(id: HotkeyID, hotkey: Hotkey, callback: @escaping () -> Void) {
        callbacks[id] = callback
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(UInt32(bitPattern: 0x53484B31)), id: id.rawValue) // 'SHK1'
        let status = RegisterEventHotKey(hotkey.keyCode, 0, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status == noErr {
            hotkeyRefs[id] = hotKeyRef
            installHandlerIfNeeded()
        } else {
            print("RegisterEventHotKey failed (\(status)) for \(id)")
        }
    }

    func unregisterAll() {
        for (_, ref) in hotkeyRefs { if let ref { UnregisterEventHotKey(ref) } }
        hotkeyRefs.removeAll()
        callbacks.removeAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit { unregisterAll() }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            var hkID = EventHotKeyID()
            let status = GetEventParameter(event,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil,
                                           MemoryLayout<EventHotKeyID>.size,
                                           nil,
                                           &hkID)
            if status == noErr, let userData {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                if let id = HotkeyID(rawValue: hkID.id), let cb = manager.callbacks[id] { cb() }
            }
            return noErr
        }, 1, &eventType, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &eventHandler)
    }
}

// MARK: - Screenshot Manager (ScreenCaptureKit)

final class ScreenshotManager: ObservableObject {
    @Published var saveDirectory: URL?
    private let toast = Toast()

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
                    self.saveToClipboard(cgImage: cg)
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
                self.save(cgImage: cg, suffix: "Window")
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
                    self.save(cgImage: cg, suffix: suffix)
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
        // Fallback: common 1x assumption (shouldn’t happen on modern macOS)
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

    private func saveToClipboard(cgImage: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Convert CGImage to NSImage for clipboard
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        
        if pasteboard.writeObjects([nsImage]) {
            DispatchQueue.main.async { [weak self] in
                self?.toast.show(text: "Screenshot copied to clipboard")
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.toast.show(text: "Failed to copy to clipboard")
            }
        }
    }

    private func save(cgImage: CGImage, suffix: String) {
        let dir = saveDirectory ?? macOSScreenshotDirectory() ?? defaultDesktop()
        let url = dir.appendingPathComponent(filename(suffix: suffix)).appendingPathExtension("png")
        
        do {
            // Ensure directory exists and is writable
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            
            // Try to save the PNG
            try savePNG(cgImage: cgImage, to: url)
            DispatchQueue.main.async { [weak self] in
                self?.toast.show(text: "Saved \(url.lastPathComponent)")
            }
        } catch {
            // Fallback to Desktop if the preferred location fails
            let fallbackURL = defaultDesktop().appendingPathComponent(filename(suffix: suffix)).appendingPathExtension("png")
            do {
                try savePNG(cgImage: cgImage, to: fallbackURL)
                DispatchQueue.main.async { [weak self] in
                    self?.toast.show(text: "Saved to Desktop: \(fallbackURL.lastPathComponent)")
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

// MARK: - Selection overlay (drag rectangle) — returns rect + screen

final class SelectionOverlay: NSWindow, NSWindowDelegate {
    private var startPoint: CGPoint = .zero
    private var currentPoint: CGPoint = .zero
    private var shapeLayer = CAShapeLayer()
    private var onComplete: ((CGRect?, NSScreen?) -> Void)?

    private static var activeOverlays: [SelectionOverlay] = []

    static func present(onComplete: @escaping (CGRect?, NSScreen?) -> Void) {
        activeOverlays = NSScreen.screens.map { screen in
            let w = SelectionOverlay(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
            w.onComplete = onComplete
            return w
        }
        activeOverlays.forEach { $0.makeKeyAndOrderFront(nil) }
        NSCursor.crosshair.set()
    }

    convenience init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool, screen: NSScreen) {
        self.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
        isOpaque = false
        backgroundColor = NSColor.black.withAlphaComponent(0.15)
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        level = .screenSaver
        collectionBehavior = [.transient, .ignoresCycle]
        delegate = self

        let v = NSView(frame: contentRect)
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.15).cgColor

        shapeLayer.fillRule = .evenOdd
        shapeLayer.fillColor = NSColor.black.withAlphaComponent(0.15).cgColor
        shapeLayer.strokeColor = NSColor.white.withAlphaComponent(0.9).cgColor
        shapeLayer.lineWidth = 2
        v.layer?.addSublayer(shapeLayer)

        contentView = v
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = NSEvent.mouseLocation
        currentPoint = startPoint
        updateSelectionPath()
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = NSEvent.mouseLocation
        updateSelectionPath()
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = NSEvent.mouseLocation
        let rect = normalizedRect(startPoint: startPoint, endPoint: currentPoint)
        cleanup(andCompleteWith: rect.width > 4 && rect.height > 4 ? rect : nil)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            cleanup(andCompleteWith: nil)
        }
    }

    private func updateSelectionPath() {
        guard let contentView = self.contentView else { return }

        let rectScreen = normalizedRect(startPoint: startPoint, endPoint: currentPoint)

        // Convert from SCREEN → WINDOW space, then use view bounds for the outer path
        let rectWin = self.convertFromScreen(rectScreen)
        let outer = NSBezierPath(rect: contentView.bounds).cgPath
        let inner = NSBezierPath(rect: rectWin).cgPath

        let combined = CGMutablePath()
        combined.addPath(outer)
        combined.addPath(inner)
        shapeLayer.path = combined
    }

    private func normalizedRect(startPoint: CGPoint, endPoint: CGPoint) -> CGRect {
        let x = min(startPoint.x, endPoint.x)
        let y = min(startPoint.y, endPoint.y)
        let w = abs(startPoint.x - endPoint.x)
        let h = abs(startPoint.y - endPoint.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func cleanup(andCompleteWith rect: CGRect?) {
        let s = self.screen
        SelectionOverlay.activeOverlays.forEach { $0.orderOut(nil) }
        SelectionOverlay.activeOverlays.removeAll()
        onComplete?(rect, s)
        onComplete = nil
    }
}

private extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            switch element(at: i, associatedPoints: &points) {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            @unknown default: break
            }
        }
        return path
    }
}

// MARK: - HUD toast

final class Toast {
    private var window: NSWindow?

    func show(text: String, duration: TimeInterval = 1.25) {
        let label = NSTextField(labelWithString: text)
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.lineBreakMode = .byTruncatingMiddle

        let padding: CGFloat = 14
        let size = label.intrinsicContentSize
        let frame = NSRect(x: 0, y: 0, width: size.width + padding*2, height: size.height + padding)
        let win = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .statusBar
        win.hasShadow = true
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.transient, .ignoresCycle]

        let bg = NSVisualEffectView(frame: frame)
        bg.material = .hudWindow
        bg.blendingMode = .withinWindow
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 10

        label.frame = NSRect(x: padding, y: (frame.height - size.height)/2 - 1, width: size.width, height: size.height)
        bg.addSubview(label)
        win.contentView = bg

        if let screen = NSScreen.main {
            let origin = CGPoint(x: screen.frame.maxX - frame.width - 20, y: screen.frame.maxY - frame.height - 36)
            win.setFrameOrigin(origin)
        }

        win.alphaValue = 0
        win.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            win.animator().alphaValue = 1
        }

        self.window = win
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, let win = self.window else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                win.animator().alphaValue = 0
            }, completionHandler: {
                win.orderOut(nil)
                self.window = nil
            })
        }
    }
}
