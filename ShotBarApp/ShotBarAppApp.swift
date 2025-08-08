import SwiftUI
import AppKit
import CoreGraphics
import QuartzCore
import ImageIO
import UniformTypeIdentifiers
import Carbon.HIToolbox

// MARK: - App

@main
struct ShotBarApp: App {
    @StateObject private var prefs = Preferences()
    @StateObject private var hotkeys = HotkeyManager()
    @StateObject private var shots = ScreenshotManager()

    var body: some Scene {
        MenuBarExtra("ShotBar", systemImage: "camera.viewfinder") {
            VStack(alignment: .leading, spacing: 6) {
                Button("Capture Selection   ⇧⌘4-like") { shots.captureSelection() }
                Button("Capture Active Window") { shots.captureActiveWindow() }
                Button("Capture Full Screen(s)") { shots.captureFullScreens() }
                Divider()
                Button("Reveal Save Folder") { shots.revealSaveLocationInFinder() }
                Divider()
                Button("Preferences…") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                Button("Quit") { NSApp.terminate(nil) }
            }
            .padding(.vertical, 4)
            .frame(minWidth: 240)
        }
        .menuBarExtraStyle(.window)

        Settings {
            PreferencesView()
                .environmentObject(prefs)
                .environmentObject(hotkeys)
                .environmentObject(shots)
                .frame(width: 420)
        }
        .onChange(of: prefs.selectionHotkey) { _ in rebindHotkeys() }
        .onChange(of: prefs.windowHotkey)    { _ in rebindHotkeys() }
        .onChange(of: prefs.screenHotkey)    { _ in rebindHotkeys() }
        .onAppear {
            shots.refreshSaveDirectory()
            rebindHotkeys()
        }
    }

    private func rebindHotkeys() {
        hotkeys.unregisterAll()
        if let hk = prefs.selectionHotkey { hotkeys.register(id: .selection, hotkey: hk) { shots.captureSelection() } }
        if let hk = prefs.windowHotkey    { hotkeys.register(id: .window,    hotkey: hk) { shots.captureActiveWindow() } }
        if let hk = prefs.screenHotkey    { hotkeys.register(id: .screen,    hotkey: hk) { shots.captureFullScreens() } }
    }
}

// MARK: - Preferences model

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
        if let hk { defaults.set(try? JSONEncoder().encode(hk), forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }

    private func load(key: String) -> Hotkey? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Hotkey.self, from: data)
    }
}

// MARK: - Preferences UI

struct PreferencesView: View {
    @EnvironmentObject var prefs: Preferences
    @EnvironmentObject var shots: ScreenshotManager

    var body: some View {
        Form {
            Section("Save Location") {
                HStack {
                    Text(shots.saveDirectory?.path ?? "Using system screenshot folder")
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer()
                    Button("Reveal") { shots.revealSaveLocationInFinder() }
                }
                Text("By default, the app honors macOS’ Screenshot location (defaults domain com.apple.screencapture).")
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
                    _ = shots.checkOrRequestScreenRecordingPermission(promptIfNeeded: true)
                }
                Text("If captures fail, grant Screen Recording in System Settings → Privacy & Security.")
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

// MARK: - Global hotkeys

enum HotkeyID: UInt32 { case selection = 1, window = 2, screen = 3 }

final class HotkeyManager: ObservableObject {
    private var eventHandler: EventHandlerRef?
    private var hotkeyRefs: [HotkeyID: EventHotKeyRef?] = [:]
    private var callbacks: [HotkeyID: () -> Void] = [:]

    func register(id: HotkeyID, hotkey: Hotkey, callback: @escaping () -> Void) {
        callbacks[id] = callback
        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID(signature: OSType(UInt32(bitPattern: 0x53484B31)), id: id.rawValue) // 'SHK1'
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

// MARK: - Screenshot manager

final class ScreenshotManager: ObservableObject {
    @Published var saveDirectory: URL?
    private let toast = Toast()

    // Save location
    func refreshSaveDirectory() { saveDirectory = macOSScreenshotDirectory() ?? defaultDesktop() }
    func revealSaveLocationInFinder() {
        if let dir = saveDirectory ?? macOSScreenshotDirectory() ?? defaultDesktop() {
            NSWorkspace.shared.activateFileViewerSelecting([dir])
        }
    }

    // Capture: Selection
    func captureSelection() {
        guard checkOrRequestScreenRecordingPermission(promptIfNeeded: true) else { return }
        SelectionOverlay.present { [weak self] rect in
            guard let self, let rect else { return } // cancelled
            if let cg = CGWindowListCreateImage(rect, [.optionOnScreenOnly], kCGNullWindowID, [.bestResolution]) {
                self.save(cgImage: cg, suffix: "Selection")
            } else {
                self.toast.show(text: "Selection capture failed")
            }
        }
    }

    // Capture: Active Window
    func captureActiveWindow() {
        guard checkOrRequestScreenRecordingPermission(promptIfNeeded: true) else { return }
        guard let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            toast.show(text: "No active app window")
            return
        }
        guard let infoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            toast.show(text: "Cannot query windows")
            return
        }
        let candidates = infoList.compactMap { dict -> (id: CGWindowID, bounds: CGRect)? in
            guard let pid = dict[kCGWindowOwnerPID as String] as? pid_t, pid == frontPID,
                  let layer = dict[kCGWindowLayer as String] as? Int, layer == 0,
                  let isOnscreen = dict[kCGWindowIsOnscreen as String] as? Bool, isOnscreen,
                  let wid = dict[kCGWindowNumber as String] as? CGWindowID,
                  let bDict = dict[kCGWindowBounds as String] as? [String: CGFloat] else { return nil }
            return (wid, CGRect(x: bDict["X"] ?? 0, y: bDict["Y"] ?? 0, width: bDict["Width"] ?? 0, height: bDict["Height"] ?? 0))
        }
        guard let best = candidates.max(by: { $0.bounds.width * $0.bounds.height < $1.bounds.width * $1.bounds.height }) else {
            toast.show(text: "No captureable window"); return
        }
        if let cg = CGWindowListCreateImage(.null, [.optionIncludingWindow], best.id, [.bestResolution]) {
            save(cgImage: cg, suffix: "Window")
        } else {
            toast.show(text: "Window capture failed")
        }
    }

    // Capture: Full Screens (all displays)
    func captureFullScreens() {
        guard checkOrRequestScreenRecordingPermission(promptIfNeeded: true) else { return }
        let screens = NSScreen.screens
        var saved = 0
        for (idx, screen) in screens.enumerated() {
            guard let dispID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value else { continue }
            if let cg = CGDisplayCreateImage(CGDirectDisplayID(dispID)) {
                let suffix = screens.count > 1 ? "Display\(idx+1)" : "Screen"
                save(cgImage: cg, suffix: suffix)
                saved += 1
            }
        }
        if saved == 0 { toast.show(text: "Full screen capture failed") }
    }

    // Permissions
    @discardableResult
    func checkOrRequestScreenRecordingPermission(promptIfNeeded: Bool) -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        if promptIfNeeded { return CGRequestScreenCaptureAccess() }
        return false
    }

    // Save
    private func save(cgImage: CGImage, suffix: String) {
        let dir = (saveDirectory ?? macOSScreenshotDirectory() ?? defaultDesktop())
        let url = dir.appendingPathComponent(filename(suffix: suffix)).appendingPathExtension("png")
        do {
            try savePNG(cgImage: cgImage, to: url)
            toast.show(text: "Saved \(url.lastPathComponent)")
        } catch {
            toast.show(text: "Save failed: \(error.localizedDescription)")
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
            throw NSError(domain: "Screenshot", code: -1, userInfo: [NSLocalizedDescriptionKey: "CGImageDestinationCreateWithURL failed"])
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        if !CGImageDestinationFinalize(dest) {
            throw NSError(domain: "Screenshot", code: -2, userInfo: [NSLocalizedDescriptionKey: "CGImageDestinationFinalize failed"])
        }
    }

    // Save locations
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

// MARK: - Selection overlay (drag rectangle)

final class SelectionOverlay: NSWindow, NSWindowDelegate {
    private var startPoint: CGPoint = .zero
    private var currentPoint: CGPoint = .zero
    private var shapeLayer = CAShapeLayer()
    private var onComplete: ((CGRect?) -> Void)?

    private static var activeOverlays: [SelectionOverlay] = []

    static func present(onComplete: @escaping (CGRect?) -> Void) {
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
        let rect = normalizedRect(startPoint: startPoint, endPoint: currentPoint)
        let path = NSBezierPath(rect: self.frame).cgPath
        let selectionPath = NSBezierPath(rect: rect).cgPath
        let combined = CGMutablePath()
        combined.addPath(path)
        combined.addPath(selectionPath)
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
        SelectionOverlay.activeOverlays.forEach { $0.orderOut(nil) }
        SelectionOverlay.activeOverlays.removeAll()
        onComplete?(rect)
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
