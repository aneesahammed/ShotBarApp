# Contributing to ShotBarApp

Thank you for your interest in contributing to ShotBarApp! This document provides guidelines and information for contributors.

## 🎯 Ways to Contribute

### 🐛 Bug Reports
- Use the [GitHub Issues](../../issues) template for bug reports
- Include macOS version, ShotBarApp version, and steps to reproduce
- Provide screenshots or screen recordings when helpful
- Check existing issues before creating duplicates

### 💡 Feature Requests
- Use the [GitHub Issues](../../issues) template for feature requests
- Describe the problem your feature would solve
- Consider implementation complexity and user experience impact
- Be open to alternative solutions

### 🔧 Code Contributions
- Fork the repository and create a feature branch
- Follow the existing code style and architecture
- Add tests when applicable
- Update documentation for user-facing changes
- Submit a pull request with clear description

## 🏗️ Development Setup

### Prerequisites
- **Xcode 15.0+**: Required for Swift 5.9 and SwiftUI features
- **macOS 15.5+**: Required for ScreenCaptureKit APIs
- **Git**: For version control

### Getting Started
```bash
# Clone your fork
git clone https://github.com/yourusername/ShotBarApp.git
cd ShotBarApp

# Create a feature branch
git checkout -b feature/your-feature-name

# Open in Xcode
open ShotBarApp.xcodeproj
```

### Building and Testing
```bash
# Debug build
xcodebuild -scheme ShotBarApp -configuration Debug build

# Release build
xcodebuild -scheme ShotBarApp -configuration Release build

# Run the app from Xcode for debugging
# The app requires Screen Recording permission for testing
```

## 📋 Code Guidelines

### Swift Style
- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use descriptive variable and function names
- Keep functions focused and under 50 lines when possible
- Add documentation comments for public APIs

### Architecture Principles
- **Separation of Concerns**: Keep UI, business logic, and data models separate
- **Single Responsibility**: Each class/struct should have one clear purpose
- **Dependency Injection**: Use AppServices for service coordination
- **Reactive Programming**: Use Combine for state management

### File Organization
```
ShotBarApp/
├── Models/              # Data models only, no business logic
├── Services/            # Business logic, system APIs, managers
├── UI/                  # SwiftUI views and view models
├── Components/          # Reusable UI components
├── Utils/               # Utility functions and helpers
└── Extensions/          # Swift extensions
```

### Coding Standards
```swift
// ✅ Good: Descriptive names
func captureActiveWindowWithIntelligentDetection() {
    // Implementation
}

// ❌ Bad: Unclear abbreviations
func capWin() {
    // Implementation
}

// ✅ Good: Clear separation of concerns
class ScreenshotManager: ObservableObject {
    private let toast = Toast()
    
    func captureSelection() {
        // Screenshot logic only
    }
}

// ✅ Good: Proper error handling
do {
    let image = try await SCScreenshotManager.captureImage(...)
    saveImage(image)
} catch {
    toast.show(text: "Capture failed: \(error.localizedDescription)")
}
```

## 🧪 Testing Guidelines

### Manual Testing Checklist
- [ ] Test all capture modes (Selection, Window, Full Screen)
- [ ] Test on multiple displays (if available)
- [ ] Test hotkey customization
- [ ] Test both clipboard and file saving
- [ ] Test PNG and JPEG formats
- [ ] Test permission flow on fresh install
- [ ] Test with different display scaling factors

### Screenshots for Testing
When testing, verify these scenarios work correctly:
1. **Selection Capture**: Dotted rectangle appears, captures exact selection
2. **Window Capture**: Captures the correct window, handles overlapping windows
3. **Full Screen**: Captures all displays correctly
4. **Multi-Display**: Works across different display configurations
5. **Retina/Scaling**: Maintains quality on high-DPI displays

## 📝 Pull Request Process

### Before Submitting
1. **Test thoroughly** on your local machine
2. **Update documentation** if you've changed user-facing behavior
3. **Check code style** matches existing patterns
4. **Verify build** succeeds in both Debug and Release configurations

### PR Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tested on macOS [version]
- [ ] Manual testing completed
- [ ] All capture modes tested
- [ ] Permission flow tested

## Screenshots (if applicable)
Include screenshots or screen recordings for UI changes
```

### Review Process
1. **Automated Checks**: Ensure code builds successfully
2. **Manual Review**: Code quality, architecture, and functionality review
3. **Testing**: Maintainers will test on various configurations
4. **Feedback**: Address any requested changes
5. **Merge**: PR will be merged once approved

## 🎨 UI/UX Guidelines

### Design Principles
- **Native macOS Feel**: Follow Apple's Human Interface Guidelines
- **Minimal and Clean**: Avoid clutter, focus on core functionality
- **Accessibility First**: Support VoiceOver and other accessibility features
- **Performance**: Maintain responsive UI even during captures

### SwiftUI Best Practices
- Use `@Published` for observable properties
- Prefer composition over inheritance
- Keep views small and focused
- Use proper state management patterns

## 🚀 Feature Development

### High-Impact Areas
- **Performance Optimization**: Faster capture times, lower memory usage
- **Accessibility**: VoiceOver support, keyboard navigation
- **Advanced Capture**: Timed capture, burst mode, video recording
- **Cloud Integration**: Save to Dropbox, Google Drive, etc.
- **Annotation Tools**: Basic drawing and text overlay features

### Implementation Guidelines
1. **Research First**: Study existing patterns in the codebase
2. **Start Small**: Implement MVP version first
3. **User Experience**: Consider the full user journey
4. **Error Handling**: Plan for failure scenarios
5. **Performance**: Profile and optimize critical paths

## 🐛 Debugging Tips

### Common Issues
- **Permission Problems**: Check Screen Recording permission in System Preferences
- **Coordinate Issues**: Test with multiple display configurations
- **Hotkey Conflicts**: Verify hotkey registration and conflicts
- **Memory Leaks**: Use Instruments to profile memory usage

### Useful Debugging Tools
```swift
// Add temporary debug prints
print("Debug: Selection rect = \(rect)")
print("Debug: Display bounds = \(screen.frame)")

// Use breakpoints in key functions:
// - captureSelection()
// - captureActiveWindow() 
// - captureDisplayRegion()
```

## 📖 Resources

### Apple Documentation
- [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Learning Resources
- [Swift Programming Language](https://docs.swift.org/swift-book/)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [macOS App Architecture](https://developer.apple.com/documentation/swiftui/app-structure)

## 💬 Community

### Getting Help
- **GitHub Discussions**: For questions and general discussion
- **GitHub Issues**: For bugs and feature requests
- **Code Review**: Learning opportunity through PR feedback

### Code of Conduct
- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow
- Focus on the code, not the person

## 🎉 Recognition

Contributors will be recognized in:
- **README.md**: Contributors section
- **Release Notes**: Major contributions highlighted
- **GitHub**: Contributor badges and statistics

Thank you for helping make ShotBarApp better for everyone! 🙏