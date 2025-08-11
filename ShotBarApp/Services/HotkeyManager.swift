import Foundation
import Carbon.HIToolbox
import SwiftUI

// MARK: - Global hotkeys (Carbon)

final class HotkeyManager: ObservableObject, HotkeyRegistrable {
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
