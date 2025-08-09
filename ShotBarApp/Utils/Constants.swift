import Foundation
import Carbon.HIToolbox

// MARK: - App Constants

struct AppConstants {
    // UI Constants
    static let menuMinWidth: CGFloat = 360
    static let preferencesWidth: CGFloat = 420
    static let menuPadding: CGFloat = 6
    
    // Default Hotkeys
    static let defaultSelectionHotkey = UInt32(kVK_F1)
    static let defaultWindowHotkey = UInt32(kVK_F2)
    static let defaultScreenHotkey = UInt32(kVK_F3)
    
    // UserDefaults Keys
    struct UserDefaultsKeys {
        static let selectionHotkey = "selectionHotkey"
        static let windowHotkey = "windowHotkey"
        static let screenHotkey = "screenHotkey"
        static let imageFormat = "imageFormat"
        static let destination = "destination"
        static let soundEnabled = "soundEnabled"
    }
    
    // File Extensions
    struct FileExtensions {
        static let png = "png"
        static let jpg = "jpg"
    }
}
