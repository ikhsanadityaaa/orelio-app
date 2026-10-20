#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodebuild >/dev/null || { echo 'Requires Xcode on macOS.' >&2; exit 2; }
mkdir -p .build-simulator
xcodebuild -project orelio.xcodeproj -scheme orelio -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$PWD/.build-simulator" CODE_SIGNING_ALLOWED=NO build \
  2>&1 | tee .build-simulator/xcodebuild.log
