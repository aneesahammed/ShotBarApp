import Foundation
import Carbon.HIToolbox

// MARK: - Hotkey Model

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


