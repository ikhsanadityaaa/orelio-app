#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo '1/3 Checking Swift source syntax'
find orelio -type f -name '*.swift' -print0 | xargs -0 -n1 swiftc -frontend -parse
echo '2/3 Checking Xcode project structure'
plutil -lint orelio.xcodeproj/project.pbxproj
echo '3/3 Checking portable models'
model_bin="$(mktemp /tmp/orelio-model.XXXXXX)"
trap 'rm -f "$model_bin"' EXIT
swiftc orelio/Models/Models.swift orelio/Models/BatchRecipeOperation.swift orelio/Services/AppFolders.swift tools/SmokeTests/main.swift -o "$model_bin"
"$model_bin"
echo 'PASS: All Linux-executable checks passed. Full iOS build requires macOS + Xcode.'
