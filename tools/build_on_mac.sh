#!/usr/bin/env bash
set -euo pipefail
# Build and (optionally) install on an actual connected iPhone.
# Configure the team once in Xcode > Signing & Capabilities first.
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ERROR: requires macOS with Xcode installed and selected by xcode-select." >&2
  exit 2
fi
if ! command -v xcrun >/dev/null 2>&1; then
  echo "ERROR: Xcode command-line tools not available." >&2
  exit 2
fi
PROJECT=orelio.xcodeproj
SCHEME=orelio
BUILDDIR="$PWD/.build-iphone"
DESTINATION="generic/platform=iOS"
ARGS=()
if [[ -n "${ORELIO_DEVICE_ID:-}" ]]; then
  DESTINATION="platform=iOS,id=${ORELIO_DEVICE_ID}"
fi
if [[ -n "${ORELIO_TEAM_ID:-}" ]]; then
  ARGS+=("DEVELOPMENT_TEAM=${ORELIO_TEAM_ID}")
fi
if [[ -n "${ORELIO_BUNDLE_ID:-}" ]]; then
  ARGS+=("PRODUCT_BUNDLE_IDENTIFIER=${ORELIO_BUNDLE_ID}")
fi
if [[ -z "${ORELIO_DEVICE_ID:-}" ]]; then
  echo 'TIP: set ORELIO_DEVICE_ID to the device identifier from xcrun devicectl list devices.'
fi
mkdir -p "$BUILDDIR"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination "$DESTINATION" -derivedDataPath "$BUILDDIR" \
  -allowProvisioningUpdates CODE_SIGN_STYLE=Automatic "${ARGS[@]}" build \
  2>&1 | tee "$BUILDDIR/xcodebuild.log"
APP="$BUILDDIR/Build/Products/Debug-iphoneos/orelio.app"
if [[ ! -d "$APP" ]]; then
  echo "ERROR: app bundle missing at $APP" >&2; exit 3
fi
echo "SIGNED APP BUNDLE: $APP"
if [[ "${ORELIO_INSTALL:-0}" == '1' ]]; then
  if [[ -z "${ORELIO_DEVICE_ID:-}" ]]; then
    echo 'ERROR: ORELIO_INSTALL=1 requires ORELIO_DEVICE_ID.' >&2; exit 4
  fi
  xcrun devicectl device install app --device "$ORELIO_DEVICE_ID" "$APP"
  echo 'Installation command completed. If necessary enable Developer Mode on the iPhone.'
fi
