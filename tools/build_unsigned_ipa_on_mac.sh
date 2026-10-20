#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build-iphone-unsigned dist
set -o pipefail
xcodebuild -project orelio.xcodeproj -scheme orelio -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath "$PWD/.build-iphone-unsigned" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build 2>&1 | tee .build-iphone-unsigned/xcodebuild.log
APP="$PWD/.build-iphone-unsigned/Build/Products/Release-iphoneos/orelio.app"
test -d "$APP"
mkdir -p .build-iphone-unsigned/ipa-stage/Payload
/usr/bin/ditto "$APP" .build-iphone-unsigned/ipa-stage/Payload/orelio.app
IPA="$PWD/dist/orelio-unsigned.ipa"
(cd .build-iphone-unsigned/ipa-stage && /usr/bin/zip -qry "$IPA" Payload)
/usr/bin/unzip -t "$IPA" >/dev/null
echo "Unsigned IPA: $IPA. Must be signed with your own Apple Account for sideload installation."
