#!/usr/bin/env bash
set -euo pipefail

# Build and package Cadence into a native macOS .app bundle
CONFIGURATION="${1:-release}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
APP_NAME="Cadence"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Building CadenceApp (${CONFIGURATION})..."
swift build -c "${CONFIGURATION}" --package-path "${PROJECT_ROOT}"

BIN_PATH="$(swift build -c "${CONFIGURATION}" --package-path "${PROJECT_ROOT}" --show-bin-path)/CadenceApp"

if [ ! -f "${BIN_PATH}" ]; then
    echo "Error: Binary not found at ${BIN_PATH}" >&2
    exit 1
fi

echo "==> Constructing ${APP_NAME}.app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${BIN_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy application icon resources
if [ -f "${PROJECT_ROOT}/Resources/AppIcon.icns" ]; then
    echo "==> Integrating AppIcon.icns..."
    cp "${PROJECT_ROOT}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Generate Info.plist
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Cadence</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.cadence.timer</string>
    <key>CFBundleName</key>
    <string>Cadence</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.3.0</string>
    <key>CFBundleVersion</key>
    <string>3</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Cadence. All rights reserved.</string>
</dict>
</plist>
EOF

# Generate PkgInfo
printf "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Ad-hoc code sign for local development and Gatekeeper compatibility
echo "==> Applying ad-hoc codesign..."
codesign --force --deep -s - "${APP_BUNDLE}"

echo "==> Successfully packaged: ${APP_BUNDLE}"
echo "    Launch with: open '${APP_BUNDLE}'"
