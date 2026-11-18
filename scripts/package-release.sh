#!/usr/bin/env bash
set -euo pipefail

# Package Cadence into a verified, distributable release archive
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
DIST_DIR="${BUILD_DIR}/dist"
APP_BUNDLE="${BUILD_DIR}/Cadence.app"

echo "========================================================"
echo "          CADENCE RELEASE PACKAGING PIPELINE            "
echo "========================================================"

# Step 1: Build & assemble release application
echo "==> [1/5] Building release application bundle..."
"${PROJECT_ROOT}/scripts/build-app.sh" release

# Step 2: Validate bundle integrity and resources
echo "==> [2/5] Validating application bundle resources..."
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: Bundle missing at ${APP_BUNDLE}" >&2
    exit 1
fi

BINARY_PATH="${APP_BUNDLE}/Contents/MacOS/Cadence"
if [ ! -x "${BINARY_PATH}" ]; then
    echo "Error: Executable missing or non-executable at ${BINARY_PATH}" >&2
    exit 1
fi

ICON_PATH="${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
if [ ! -s "${ICON_PATH}" ]; then
    echo "Error: AppIcon.icns missing or empty at ${ICON_PATH}" >&2
    exit 1
fi

PLIST_PATH="${APP_BUNDLE}/Contents/Info.plist"
if [ ! -f "${PLIST_PATH}" ]; then
    echo "Error: Info.plist missing at ${PLIST_PATH}" >&2
    exit 1
fi

plutil -lint "${PLIST_PATH}" >/dev/null

BUNDLE_ID="$(plutil -extract CFBundleIdentifier raw "${PLIST_PATH}")"
if [ "${BUNDLE_ID}" != "com.cadence.timer" ]; then
    echo "Error: Unexpected bundle ID: ${BUNDLE_ID} (expected com.cadence.timer)" >&2
    exit 1
fi

VERSION="$(plutil -extract CFBundleShortVersionString raw "${PLIST_PATH}")"
BUILD_NUM="$(plutil -extract CFBundleVersion raw "${PLIST_PATH}")"

echo "    ✔ Binary executable: OK"
echo "    ✔ Application Icon (AppIcon.icns): OK ($(du -sh "${ICON_PATH}" | awk '{print $1}'))"
echo "    ✔ Info.plist metadata: OK (Bundle ID: ${BUNDLE_ID}, Version: ${VERSION} build ${BUILD_NUM})"

# Step 3: Verify code signature
echo "==> [3/5] Verifying code signature..."
codesign --verify --deep --strict "${APP_BUNDLE}"
echo "    ✔ Code signature verified (ad-hoc development signature)."

# Step 4: Construct release ZIP archive and DMG installer
echo "==> [4/6] Creating distributable ZIP archive..."
mkdir -p "${DIST_DIR}"
ZIP_NAME="Cadence-v${VERSION}-macos.zip"
ZIP_PATH="${DIST_DIR}/${ZIP_NAME}"

rm -f "${ZIP_PATH}"

# ditto preserves resource forks, extended attributes, and Mach-O permissions
(cd "${BUILD_DIR}" && ditto -c -k --keepParent "Cadence.app" "${ZIP_PATH}")

# Verify archive integrity
unzip -tq "${ZIP_PATH}"
echo "    ✔ ZIP archive created and verified."

echo "==> [5/6] Building standalone DMG installer..."
"${PROJECT_ROOT}/scripts/build-dmg.sh"

# Step 6: Report artifact summary and checksum
echo "==> [6/6] Generating release summary..."
ARCHIVE_SIZE="$(du -sh "${ZIP_PATH}" | awk '{print $1}')"
SHA256="$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')"
echo "${SHA256}  ${ZIP_NAME}" > "${DIST_DIR}/${ZIP_NAME}.sha256"

echo "========================================================"
echo "          CADENCE RELEASE ARTIFACT GENERATED            "
echo "========================================================"
echo "Artifact:   ${ZIP_PATH}"
echo "Version:    v${VERSION} (build ${BUILD_NUM})"
echo "Size:       ${ARCHIVE_SIZE}"
echo "SHA-256:    ${SHA256}"
echo ""
echo "Distribution Notes:"
echo "• The application is signed with a local ad-hoc code signature."
echo "• If distributing outside Apple Developer ID notarization, users"
echo "  downloading via browsers may need to clear quarantine attributes:"
echo "    xattr -cr /Applications/Cadence.app"
echo "  or Control-click -> Open in Finder."
echo "========================================================"
