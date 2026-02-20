#!/bin/bash
set -euo pipefail

APP_NAME="ThePort"
DISPLAY_NAME="ThePort"
DMG_NAME="ThePort.dmg"
BUILD_DIR=".build_output"
APP_PATH="${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app"
DMG_DIR="${BUILD_DIR}/dmg"
VERSION="${1:-$(date +%Y%m%d)}"

echo "==> Creating DMG for ${DISPLAY_NAME} (${VERSION})"

# Verify the .app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "Error: ${APP_PATH} not found. Run 'make release' first."
    exit 1
fi

# Clean previous DMG artifacts
rm -rf "${DMG_DIR}"
mkdir -p "${DMG_DIR}"

# Copy app to staging directory
cp -R "${APP_PATH}" "${DMG_DIR}/"

# Create a symlink to /Applications for drag-and-drop install
ln -s /Applications "${DMG_DIR}/Applications"

# Create the DMG
echo "==> Packaging DMG..."
hdiutil create \
    -volname "${DISPLAY_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov \
    -format UDZO \
    "${BUILD_DIR}/${DMG_NAME}"

# Clean staging
rm -rf "${DMG_DIR}"

echo "==> DMG created: ${BUILD_DIR}/${DMG_NAME}"
echo "    Size: $(du -h "${BUILD_DIR}/${DMG_NAME}" | cut -f1)"
