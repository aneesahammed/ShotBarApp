import SwiftUI
import AppKit

// MARK: - UI Helper Extensions

extension Color {
    /// System colors that adapt to the current appearance
    static let systemBackground = Color(nsColor: .windowBackgroundColor)
    static let systemControlBackground = Color(nsColor: .controlBackgroundColor)
    static let systemSecondary = Color(nsColor: .secondaryLabelColor)
}

extension View {
    /// Common corner radius and shadow styling
    func standardCardStyle() -> some View {
        self
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    /// Standard button styling
    func standardButtonStyle() -> some View {
        self
            .buttonStyle(.plain)
            .contentShape(Rectangle())
    }
}

// MARK: - Common UI Constants

struct UIConstants {
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 4
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.1
    static let standardSpacing: CGFloat = 12
    static let smallSpacing: CGFloat = 6
}
