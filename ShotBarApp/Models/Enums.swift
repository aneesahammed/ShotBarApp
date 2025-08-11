import Foundation

// MARK: - App Enums

enum ImageFormat: String, Codable, CaseIterable, Identifiable { 
    case png, jpg
    var id: String { rawValue.uppercased() } 
}

enum Destination: String, Codable, CaseIterable, Identifiable { 
    case file, clipboard
    var id: String { rawValue } 
}

enum HotkeyID: UInt32 { 
    case selection = 1, window = 2, screen = 3 
}
