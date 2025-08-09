# ShotBar App Architecture

## Overview
ShotBar is a macOS screenshot utility built with SwiftUI and AppKit, organized into a clean, modular architecture.

## Project Structure

### Core App
- **`ShotBarAppApp.swift`** - Main app entry point and scene configuration
- **`AppDelegate.swift`** - Application lifecycle management

### Models (`Models/`)
- **`Preferences.swift`** - User preferences and settings management
- **`Hotkey.swift`** - Hotkey data model and display logic
- **`Enums.swift`** - App-wide enumerations
- **`Protocols.swift`** - Common protocol definitions

### Services (`Services/`)
- **`AppServices.swift`** - Central service coordinator and dependency injection
- **`HotkeyManager.swift`** - Global hotkey registration and management
- **`ScreenshotManager.swift`** - Screenshot capture and processing

### UI Components (`UI/`)
- **`MenuContentView.swift`** - Main menubar popover interface
- **`PreferencesView.swift`** - Settings and preferences window

### Components (`Components/`)
- **`SelectionOverlay.swift`** - Screenshot selection overlay
- **`Toast.swift`** - Notification toast messages

### Extensions (`Extensions/`)
- **`Publisher+Extensions.swift`** - Combine framework extensions

### Utilities (`Utils/`)
- **`Constants.swift`** - App-wide constants and configuration
- **`UIHelpers.swift`** - Common UI helper functions and extensions

## Architecture Principles

### 1. Separation of Concerns
- Each file has a single, well-defined responsibility
- Models handle data, Services handle business logic, UI handles presentation

### 2. Dependency Injection
- `AppServices` acts as a service locator
- Dependencies are injected through constructors

### 3. Protocol-Oriented Design
- Common interfaces defined in `Protocols.swift`
- Enables better testing and modularity

### 4. Constants Management
- All magic numbers and strings centralized in `Constants.swift`
- Easy to maintain and modify

### 5. Extension Organization
- Swift extensions organized by functionality
- Publisher extensions for Combine framework

## Data Flow

```
User Action → UI Component → Service → Model → Persistence
     ↑                                           ↓
     ←─────────── UI Update ←───────────────────┘
```

## Key Design Patterns

- **Singleton Pattern**: `AppServices.shared` for service coordination
- **Observer Pattern**: `@Published` properties with Combine
- **Factory Pattern**: Service creation and initialization
- **Strategy Pattern**: Different screenshot capture methods

## Benefits of This Structure

1. **Maintainability**: Clear separation makes code easier to understand and modify
2. **Testability**: Services and models can be tested independently
3. **Reusability**: Components can be reused across different parts of the app
4. **Scalability**: Easy to add new features without affecting existing code
5. **Readability**: Consistent naming and organization conventions
