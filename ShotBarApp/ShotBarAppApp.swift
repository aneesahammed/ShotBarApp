import SwiftUI
import AppKit

// MARK: - AppDelegate to run launch-time setup (Scene has no onAppear)

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = AppServices.shared // touch singletons to init
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = MenuBarIcon.makeTemplateIcon()
            button.imagePosition = .imageOnly
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: AppConstants.menuMinWidth, height: 300)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuContentView(prefs: AppServices.shared.prefs, shots: AppServices.shared.shots)
                .frame(minWidth: AppConstants.menuMinWidth)
                .padding(.vertical, AppConstants.menuPadding)
        )
        
        // Listen for hide notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hidePopover),
            name: NSNotification.Name("HideMenuBarPopover"),
            object: nil
        )
    }
    
    @objc private func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                hidePopover()
            } else {
                showPopover()
            }
        }
    }
    
    @objc private func showPopover() {
        if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    @objc private func hidePopover() {
        popover?.performClose(nil)
    }
}

// MARK: - App

@main
struct ShotBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Preferences window
        Settings {
            PreferencesView(prefs: AppServices.shared.prefs, shots: AppServices.shared.shots)
                .frame(width: AppConstants.preferencesWidth)
        }
    }
}
