#!/bin/bash

# Create DMG for ShotBarApp distribution
# This creates a professional-looking disk image for easy installation

APP_NAME="ShotBarApp"
DMG_NAME="ShotBarApp-v1.0"
SOURCE_DIR="./dist"
DMG_DIR="./dmg_temp"

# Clean up any previous builds
rm -rf "${DMG_DIR}"
rm -f "${DMG_NAME}.dmg"

# Create temporary directory for DMG contents
mkdir -p "${DMG_DIR}"

# Copy app to DMG directory
cp -R "${SOURCE_DIR}/ShotBarApp.app" "${DMG_DIR}/"

# Create Applications symlink for easy installation
ln -s /Applications "${DMG_DIR}/Applications"

# Create README for installation
cat > "${DMG_DIR}/README.txt" << 'EOF'
ShotBarApp - macOS Screenshot Utility
=====================================

INSTALLATION:
1. Drag ShotBarApp.app to the Applications folder
2. Open ShotBarApp from Applications
3. Grant Screen Recording permission when prompted
4. Configure hotkeys in preferences (default: F1-F3)

USAGE:
- F1: Selection capture (drag to select area)
- F2: Active window capture 
- F3: Full screen capture
- Access preferences via menu bar icon

NOTE: This app is unsigned. You may need to:
1. Right-click the app and select "Open" 
2. Click "Open" when macOS shows security warning
3. Or go to System Preferences > Security & allow the app

For support or tips: [Your tip jar/contact info here]

Enjoy using ShotBarApp!
EOF

# Create the DMG
echo "Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDZO \
    "${DMG_NAME}.dmg"

# Clean up temp directory
rm -rf "${DMG_DIR}"

echo "DMG created: ${DMG_NAME}.dmg"
echo "Size: $(du -h ${DMG_NAME}.dmg | cut -f1)"