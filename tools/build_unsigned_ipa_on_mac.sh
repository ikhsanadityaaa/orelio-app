#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo 'ERROR: A macOS runner with Xcode is required.' >&2
  exit 1
fi

ROOT="$PWD"
DERIVED="$ROOT/.build-iphone-unsigned"
APP="$DERIVED/Build/Products/Release-iphoneos/orelio.app"
STAGE="$DERIVED/ipa-stage"
IPA="$ROOT/dist/orelio-unsigned.ipa"
LOG="$DERIVED/xcodebuild.log"

mkdir -p "$DERIVED" "$ROOT/dist"
# Build for a real physical iOS device (arm64), never iphonesimulator.
# This is intentionally UNSIGNED: Sideloadly re-signs using the user's Apple ID.
set -o pipefail
xcodebuild \
  -project orelio.xcodeproj \
  -scheme orelio \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  'CODE_SIGN_IDENTITY=' \
  build 2>&1 | tee "$LOG"

if [[ ! -d "$APP" || ! -f "$APP/Info.plist" ]]; then
  echo "ERROR: Device build did not create expected application: $APP" >&2
  exit 3
fi

EXECUTABLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Info.plist")
BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")
PLATFORM=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleSupportedPlatforms:0' "$APP/Info.plist")

if [[ ! -f "$APP/$EXECUTABLE" ]]; then
  echo "ERROR: Application executable is missing: $EXECUTABLE" >&2
  exit 4
fi
if [[ "$PLATFORM" != "iPhoneOS" ]]; then
  echo "ERROR: Built for $PLATFORM instead of iPhoneOS." >&2
  exit 5
fi
if ! /usr/bin/lipo "$APP/$EXECUTABLE" -verify_arch arm64; then
  echo 'ERROR: iPhone arm64 architecture missing.' >&2
  exit 6
fi

rm -rf "$STAGE"
mkdir -p "$STAGE/Payload"
/usr/bin/ditto "$APP" "$STAGE/Payload/orelio.app"
rm -f "$IPA"
(cd "$STAGE" && /usr/bin/zip -qry "$IPA" Payload)

/usr/bin/unzip -t "$IPA" >/dev/null
/usr/bin/unzip -l "$IPA" | /usr/bin/grep -q 'Payload/orelio.app/Info.plist'

echo "Device IPA created: $IPA"
echo "Executable: $EXECUTABLE | platform: $PLATFORM | arch: arm64 | bundle: $BUNDLE"
echo "IPA size: $(/usr/bin/stat -f %z "$IPA") bytes"
echo 'Unsigned IPA: do NOT tap to install from Files; sign and install from Windows using Sideloadly and your Apple Account.'
