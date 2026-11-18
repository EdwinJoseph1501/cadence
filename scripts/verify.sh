#!/usr/bin/env bash
set -euo pipefail

# Automated Phase 0 Verification Script for Cadence
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================================"
echo "          CADENCE PHASE 0 VERIFICATION SUITE            "
echo "========================================================"

# Step 1: Format & Linting Check
echo "==> [1/5] Checking Swift formatting and style..."
if command -v swift-format >/dev/null 2>&1; then
    swift-format lint --recursive Sources Tests
    echo "    ✔ swift-format lint passed cleanly."
else
    echo "    ⚠ swift-format not found in PATH; skipping format lint."
fi

# Step 2: Automated Unit Tests
echo "==> [2/5] Running automated unit test suite..."
swift test
echo "    ✔ All unit test suites passed."

# Step 3: Debug Compilation
echo "==> [3/5] Verifying debug compilation..."
swift build -c debug
echo "    ✔ Debug build succeeded."

# Step 4: Release Packaging
echo "==> [4/5] Building release .app bundle..."
"${PROJECT_ROOT}/scripts/build-app.sh" release
echo "    ✔ Release bundle generated."

# Step 5: Bundle Validation
echo "==> [5/5] Validating code signature & bundle integrity..."
codesign -v "${PROJECT_ROOT}/build/Cadence.app"
echo "    ✔ Code signature verified."

echo "========================================================"
echo "    ✔ ALL CHECKS PASSED: PHASE 0 FOUNDATION VERIFIED    "
echo "========================================================"
