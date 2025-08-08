# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShotBarApp is a macOS screenshot utility application built with SwiftUI that provides:
- Selection capture (similar to macOS ⇧⌘4)  
- Active window capture
- Full screen capture across all displays
- Global hotkey support (F1-F12 keys)
- Menu bar integration

## Development Commands

### Building
```bash
# Build the app
xcodebuild -scheme ShotBarApp -configuration Debug

# Build for release
xcodebuild -scheme ShotBarApp -configuration Release

# Clean build folder
xcodebuild clean -scheme ShotBarApp
```

### Running
The app must be run from Xcode or the built .app bundle as it requires:
- Screen Recording permissions
- Menu bar integration
- Global hotkey registration

## Architecture

### Core Components

**Main App Structure (`ShotBarAppApp.swift`)**:
- `ShotBarApp`: Main app with MenuBarExtra integration
- `Preferences`: UserDefaults-backed settings storage  
- `PreferencesView`: Settings UI with hotkey configuration

**Screenshot System**:
- `ScreenshotManager`: Core capture functionality using Core Graphics APIs
- Three capture modes: selection, active window, full screen(s)
- Automatic save location detection (honors macOS screenshot preferences)

**Input System**:
- `HotkeyManager`: Global hotkey registration using Carbon Event Manager
- `Hotkey` model: F1-F12 key mapping and persistence
- `SelectionOverlay`: Full-screen overlay for drag-to-select functionality

**UI Components**:
- `Toast`: HUD notifications for capture feedback
- Custom overlay system with cross-hair cursor and visual feedback

### Key Dependencies

**System Frameworks**:
- `SwiftUI`: UI framework
- `AppKit`: macOS app integration and window management
- `CoreGraphics`: Screenshot capture APIs
- `QuartzCore`: Layer-based animation and drawing
- `Carbon.HIToolbox`: Global hotkey registration

**Permissions Required**:
- Screen Recording permission for screenshot capture
- Accessibility permissions may be needed for window detection

### File Structure

- Single file architecture in `ShotBarAppApp.swift` (~530 lines)
- All functionality consolidated for simplicity
- App runs sandboxed with minimal entitlements

## Key Technical Details

### Screenshot Capture Methods
- **Selection**: Uses `SelectionOverlay` with drag interaction → `CGWindowListCreateImage`
- **Active Window**: Queries window list via `CGWindowListCopyWindowInfo` → captures largest window from frontmost app
- **Full Screen**: Direct display capture via `CGDisplayCreateImage` for each screen

### Global Hotkey Implementation
- Uses Carbon Event Manager (legacy but functional approach)
- Registers F1-F12 keys with signature `'SHK1'`
- Event handler callbacks trigger screenshot actions

### Save Location Logic
- Reads macOS screenshot location from `com.apple.screencapture` preferences
- Falls back to Desktop if system preference unavailable
- Generates timestamped filenames: `"Screenshot YYYY-MM-DD at HH.mm.ss [Type].png"`

## Development Notes

### Common Issues
- Screen Recording permission must be granted in System Settings
- Global hotkeys may conflict with system shortcuts
- F-key behavior depends on "Use F1, F2, etc. as standard function keys" setting

### Testing
- Test all three capture modes after permission changes
- Verify hotkey registration across system restarts
- Test multi-display scenarios for full screen capture

### Code Patterns
- Heavy use of `@StateObject` and `@EnvironmentObject` for state management
- Functional approach with closures for async operations (capture callbacks)
- Error handling via Toast notifications rather than alerts