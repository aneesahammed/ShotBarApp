import SwiftUI

// MARK: - Preferences UI

struct PreferencesView: View {
    @ObservedObject var prefs: Preferences
    @ObservedObject var shots: ScreenshotManager
    
    var body: some View {
        Form {
            Section("Default Behavior") {
                HStack {
                    Text("Format")
                    Spacer()
                    Picker("Format", selection: $prefs.imageFormat) {
                        ForEach(ImageFormat.allCases) { f in Text(f.id) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                HStack {
                    Text("Destination")
                    Spacer()
                    Picker("Destination", selection: $prefs.destination) {
                        Text("File").tag(Destination.file)
                        Text("Clipboard").tag(Destination.clipboard)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
                Toggle("Sound", isOn: $prefs.soundEnabled)
            }
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
                Text("Tip: Some keyboards require holding Fn for F-keys unless you enable \"Use F1, F2, etc. as standard function keys\".")
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
