import SwiftUI
import AppKit

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
            MenuContentView(prefs: S.prefs, shots: S.shots)
                .frame(minWidth: AppConstants.menuMinWidth)
                .padding(.vertical, AppConstants.menuPadding)
        }
        .menuBarExtraStyle(.window)
        
        // Preferences window
        Settings {
            PreferencesView(prefs: S.prefs, shots: S.shots)
                .frame(width: AppConstants.preferencesWidth)
        }
    }
}
