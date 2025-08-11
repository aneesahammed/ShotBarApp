# ShotBarApp

A modern, lightweight macOS screenshot utility built with SwiftUI and ScreenCaptureKit. ShotBarApp provides a clean menu bar interface for capturing screenshots with customizable hotkeys and multiple save options.

<div align="center">

[![macOS](https://img.shields.io/badge/macOS-15.5+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#license)

</div>

## ✨ Features

### 📸 Capture Modes
- **🎯 Selection Capture**: Drag to select any area of your screen
- **🪟 Active Window**: Automatically captures the previously active window
- **🖥️ Full Screen**: Captures all connected displays

### ⚡ Quick Access
- **Global Hotkeys**: Customizable F-key shortcuts (F1-F12)
- **Menu Bar Integration**: Clean popover interface
- **Instant Feedback**: HUD notifications and optional shutter sound

### 💾 Save Options
- **Clipboard**: Copy screenshots directly to clipboard
- **File System**: Save to customizable location
- **Format Support**: PNG (lossless) or JPEG (high quality)
- **Smart Naming**: Automatic timestamp-based filenames

### 🔧 Advanced Features
- **Multi-Display Support**: Works seamlessly across multiple monitors
- **Retina Support**: Handles high-DPI displays correctly
- **Intelligent Window Detection**: Prioritizes previously active applications
- **Permission Management**: Automatic Screen Recording permission handling

## 🚀 Quick Start

### Requirements
- macOS 15.5 or later
- Xcode 15.0 or later (for building)

### Installation

#### Option 1: Download Release
1. Download the latest `ShotBarApp-v1.0.dmg` from [Releases](../../releases)
2. Open the DMG file
3. Drag ShotBarApp to Applications folder
4. **Important**: Right-click and select "Open" to bypass macOS security (unsigned app)

#### Option 2: Build from Source
```bash
git clone https://github.com/yourusername/ShotBarApp.git
cd ShotBarApp
xcodebuild -scheme ShotBarApp -configuration Release build
```

### First Launch Setup
1. Launch ShotBarApp from Applications
2. Grant **Screen Recording** permission when prompted
3. Configure hotkeys in preferences (menu bar icon → Preferences)
4. Start capturing screenshots!

## 🎮 Usage

### Default Hotkeys
- **F1**: Selection capture (drag to select area)
- **F2**: Active window capture  
- **F3**: Full screen capture

### Customization
Click the menu bar icon (📷) to access preferences:
- **Hotkeys**: Assign any F1-F12 key to capture modes
- **Save Location**: Choose clipboard or file destination
- **Image Format**: PNG or JPEG
- **Sound**: Enable/disable shutter sound

## 🏗️ Architecture

ShotBarApp uses a clean, modular architecture:

```
ShotBarApp/
├── Models/              # Data models and configuration
│   ├── Hotkey.swift     # Hotkey configuration model
│   ├── Preferences.swift # User preferences with persistence
│   ├── Enums.swift      # Core enums (ImageFormat, Destination, etc.)
│   └── Protocols.swift  # Protocol definitions
├── Services/            # Business logic and system integration
│   ├── AppServices.swift      # Central service coordinator
│   ├── HotkeyManager.swift    # Global hotkey registration
│   └── ScreenshotManager.swift # Screen capture using ScreenCaptureKit
├── UI/                  # SwiftUI interface components
│   ├── PreferencesView.swift  # Settings interface
│   └── MenuContentView.swift  # Menu bar popover content
├── Components/          # Reusable UI components
│   ├── SelectionOverlay.swift # Drag-to-select overlay
│   └── Toast.swift           # HUD notifications
├── Utils/               # Utility functions and helpers
└── Extensions/          # Swift extensions
```

### Key Design Principles
- **Separation of Concerns**: UI, business logic, and data are cleanly separated
- **Dependency Injection**: Services are injected through AppServices
- **Reactive Programming**: Uses Combine for state coordination
- **Modern APIs**: Built with ScreenCaptureKit (replacing deprecated APIs)

## 🔧 Development

### Prerequisites
- Xcode 15.0+
- macOS 15.5+ (for ScreenCaptureKit)

### Building
```bash
# Debug build
xcodebuild -scheme ShotBarApp -configuration Debug build

# Release build
xcodebuild -scheme ShotBarApp -configuration Release build

# Run tests (when available)
xcodebuild test -scheme ShotBarApp
```

### Key Technical Details

#### Screenshot System
- **ScreenCaptureKit**: Modern capture API with superior quality and performance
- **Multi-Display Handling**: Correctly handles scaled displays, Sidecar, and multiple monitors
- **Coordinate Mapping**: Precise pixel-perfect coordinate conversion across display configurations
- **Quality Settings**: Optimized for both speed and image quality

#### Hotkey System
- **Carbon Event Manager**: Uses stable Carbon APIs for system-wide hotkey capture
- **Hot Swapping**: Hotkeys can be changed at runtime without restart
- **Conflict Prevention**: Uses unique event signatures to prevent conflicts

#### Permissions
- **Screen Recording**: Required for ScreenCaptureKit, automatically prompted
- **Sandboxed**: Runs in App Sandbox with minimal required entitlements
- **No Accessibility Required**: Unlike some screenshot tools, doesn't need accessibility permissions

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Contribution
- **New Capture Modes**: Timed capture, burst mode, etc.
- **Export Formats**: Additional image formats (WebP, TIFF, etc.)
- **Cloud Integration**: Save to cloud services
- **Annotations**: Basic drawing/annotation tools
- **Accessibility**: VoiceOver support and other accessibility features
- **Performance**: Optimization for older hardware

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

## 📊 Performance & Quality

- **Memory Efficient**: Minimal memory footprint when idle
- **Fast Capture**: Sub-second capture times across all modes
- **High Quality**: Lossless PNG or high-quality JPEG (92% quality)
- **Reliable**: Extensive error handling and graceful fallbacks

## ❓ Troubleshooting

### App Won't Open
- **Problem**: "ShotBarApp can't be opened because it is from an unidentified developer"
- **Solution**: Right-click the app → "Open" → Click "Open" in the dialog

### Screenshots Don't Work
- **Problem**: No screenshots are captured
- **Solution**: Grant Screen Recording permission in System Preferences → Security & Privacy → Privacy → Screen Recording

### Hotkeys Don't Respond
- **Problem**: Function keys don't trigger screenshots
- **Solution**: Check System Preferences → Keyboard → "Use F1, F2, etc. keys as standard function keys"

### Quality Issues
- **Problem**: Blurry or low-quality screenshots
- **Solution**: The app captures at native resolution - check your display scaling settings

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit) for modern, high-quality screen capture
- Uses [SwiftUI](https://developer.apple.com/xcode/swiftui/) for the native macOS interface
- Inspired by the simplicity and functionality of classic screenshot utilities

## 📞 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Tips**: If you find this useful, tips are appreciated but never required!

---

<div align="center">

**Made with ❤️ for the macOS community**

[⭐ Star this repo](../../stargazers) • [🐛 Report Bug](../../issues) • [💡 Request Feature](../../issues)

</div>