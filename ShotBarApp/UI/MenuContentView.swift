import SwiftUI

// MARK: - Menu UI (menubar popover)

struct MenuContentView: View {
    @ObservedObject var prefs: Preferences
    @ObservedObject var shots: ScreenshotManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            headerSection
            
            // Format/Destination section
            formatSection
            
            // Main menu section
            menuSection
        }
        .frame(minWidth: 380)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        // Remove the onAppear modifier since it's too late
    }
    
    // Header section with light theme
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // App icon with camera and blue circle background
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 32, height: 32)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("ShotBar")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Save to: \(shots.saveDirectory?.lastPathComponent ?? "Documents")/")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Settings gear icon
            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Open Settings")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // Format and Destination section matching screenshot
    private var formatSection: some View {
        VStack(spacing: 12) {
            // Format row
            HStack {
                Text("Format:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 100, alignment: .leading)
                
                // Segmented control style buttons
                HStack(spacing: 2) {
                    ForEach(ImageFormat.allCases, id: \.rawValue) { format in
                        Button(action: { prefs.imageFormat = format }) {
                            Text(format.id)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(prefs.imageFormat == format ? .white : .primary)
                                .frame(width: 50, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(prefs.imageFormat == format ? .blue : Color(nsColor: .controlBackgroundColor))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                // Keyboard shortcut
                Text("⌃⇧⌘4")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            // Destination row
            HStack {
                Text("Destination:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 100, alignment: .leading)
                
                // Combined segmented button
                HStack(spacing: 4) {
                    ForEach(Destination.allCases, id: \.rawValue) { dest in
                        Button(action: { prefs.destination = dest }) {
                            Text(dest.id.capitalized)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(prefs.destination == dest ? .white : .primary)
                                .frame(width: 80, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(prefs.destination == dest ? .blue : Color(nsColor: .controlBackgroundColor))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                // Keyboard shortcut
                Text("⌃⇧⌘3")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // Main menu section with light theme
    private var menuSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main action items
            menuItem(icon: "selection.pin.in.out",
                     title: actionTitle("Capture Selection"),
                     shortcut: "⌃⇧⌘4") {
                shots.captureSelection()
            }
            
            // Window capture button
            Button(action: {
                // Store the previous active app right before capturing
                shots.storePreviousActiveApp()
                shots.captureActiveWindow()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    
                    Text(actionTitle("Capture Active Window"))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("⌃⇧⌘4")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            menuItem(icon: "display",
                     title: actionTitle("Capture Full Screen(s)"),
                     shortcut: "⌃3") {
                shots.captureFullScreens()
            }
            
            // Divider
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            
            // Reveal folder item
            menuItem(icon: "folder",
                     title: "Reveal Save Folder",
                     shortcut: nil) {
                shots.revealSaveLocationInFinder()
            }
            
            // Sound toggle
            HStack {
                Toggle(isOn: $prefs.soundEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                            .frame(width: 20)
                        Text("Sound")
                            .foregroundStyle(.primary)
                    }
                }
                .toggleStyle(.checkbox)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            
            // Divider
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            
            // About menu item
            //            menuItem(icon: "info.circle", title: "About ShotBar", shortcut: nil) {
            //                NSApp.orderFrontStandardAboutPanel()
            //            }
            
            // Quit row
            menuItem(icon: "power", title: "Quit", shortcut: nil) {
                NSApp.terminate(nil)
            }
        }
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // Helper function for menu items with light theme
    private func menuItem(icon: String, title: String, shortcut: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func actionTitle(_ base: String) -> String {
        switch prefs.destination {
        case .file: return "\(base) → File"
        case .clipboard: return "\(base) → Clipboard"
        }
    }
}
