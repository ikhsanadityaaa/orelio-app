# orelio v0.5 — build readiness audit

- Source: orelio_iOS_v0.5 archive copied without modifying Swift implementation.
- Platform: SwiftUI iOS 17+; Xcode project has Automatic Code Signing with placeholder `com.example.orelio`.
- Local OS: Linux x86_64, Swift 6.2.1, no Xcode/iOS SDK or Apple signing materials available.
- Linux checks: Swift syntax parser, Xcode project plist lint, Foundation model smoke tests (all pass).
- AppIcon.png is 1024×1024 RGB (no alpha).
- GitHub Actions macOS simulator compile-check workflow included but **not executed**.
- iOS simulator/device compilation and actual installed IPA status: **NOT VERIFIED**.
- No assertion is made that signed app/IPA exists; iPhone installation requires Xcode and Apple provisioning.
