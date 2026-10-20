#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null; then
  echo 'This script must run on macOS with Xcode (for example GitHub Actions macos-15).' >&2
  exit 1
fi
mkdir -p .build-iphone-unsigned dist
# Compile for real iPhone architecture, intentionally unsigned. Signing happens on
# the user's Windows computer with Sideloadly and their own free Apple Account.
set -o pipefail
xcodebuild \
  -project orelio.xcodeproj \
  -scheme orelio \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$PWD/.build-iphone-unsigned" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build 2>&1 | tee .build-iphone-unsigned/xcodebuild.log
APP="$PWD/.build-iphone-unsigned/Build/Products/Release-iphoneos/orelio.app"
if [[ ! -d "$APP" ]]; then
  echo "Build apparently succeeded but no app bundle at: $APP" >&2
  exit 3
fi
rm -rf .build-iphone-unsigned/ipa-stage
mkdir -p .build-iphone-unsigned/ipa-stage/Payload
/usr/bin/ditto "$APP" .build-iphone-unsigned/ipa-stage/Payload/orelio.app
IPA="$PWD/dist/orelio-unsigned.ipa"
rm -f "$IPA"
(cd .build-iphone-unsigned/ipa-stage && /usr/bin/zip -qry "$IPA" Payload)
/usr/bin/unzip -t "$IPA" >/dev/null
/usr/bin/unzip -l "$IPA" | grep -q 'Payload/orelio.app/'
echo "Unsigned IPA is ready: $IPA"
echo 'DO NOT install by tapping this file on iPhone. Sign and install with Sideloadly using your own free Apple Account.'
