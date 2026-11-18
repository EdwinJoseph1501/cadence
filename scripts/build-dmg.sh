#!/usr/bin/env bash
set -euo pipefail

# Build a verified, standalone macOS DMG installer for Cadence
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
DIST_DIR="${BUILD_DIR}/dist"
APP_BUNDLE="${BUILD_DIR}/Cadence.app"
STAGING_DIR="${BUILD_DIR}/dmg-staging"

echo "========================================================"
echo "              CADENCE DMG PACKAGING PIPELINE            "
echo "========================================================"

# Step 1: Ensure release application bundle is present or build it
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "==> Application bundle not found. Building release bundle..."
    "${PROJECT_ROOT}/scripts/build-app.sh" release
fi

PLIST_PATH="${APP_BUNDLE}/Contents/Info.plist"
VERSION="$(plutil -extract CFBundleShortVersionString raw "${PLIST_PATH}")"
DMG_NAME="Cadence-${VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

echo "==> Packaging version: ${VERSION}"

# Step 2: Prepare clean staging folder
echo "==> Preparing DMG staging environment..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
mkdir -p "${DIST_DIR}"

echo "==> Copying Cadence.app..."
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"

echo "==> Creating /Applications symlink..."
ln -s /Applications "${STAGING_DIR}/Applications"

# Step 3: Create compressed UDZO disk image via hdiutil
echo "==> Generating disk image (${DMG_NAME})..."
rm -f "${DMG_PATH}"
hdiutil create \
    -volname "Cadence" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}" >/dev/null

# Clean up staging directory
rm -rf "${STAGING_DIR}"

# Step 4: Verify disk image integrity
echo "==> Validating DMG checksum and filesystem integrity..."
hdiutil verify "${DMG_PATH}" >/dev/null
echo "    ✔ DMG integrity verified."

# Step 5: Compute SHA-256 checksum
echo "==> Generating SHA-256 signature..."
SHA256="$(shasum -a 256 "${DMG_PATH}" | awk '{print $1}')"
echo "${SHA256}  ${DMG_NAME}" > "${DIST_DIR}/${DMG_NAME}.sha256"

DMG_SIZE="$(du -sh "${DMG_PATH}" | awk '{print $1}')"
echo "========================================================"
echo "    ✔ DMG CREATED: ${DMG_PATH} (${DMG_SIZE})"
echo "    ✔ SHA-256:     ${SHA256}"
echo "========================================================"
