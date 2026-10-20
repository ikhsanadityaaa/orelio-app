# orelio iOS v0.5 — Film editor (offline)

## What changed from v0.4

- **Border editor**: Enable/disable border; Inside vs Outside; White/Black; width 0.2–8% of the photograph's shortest edge. Outside increases exported image dimensions by twice the border width on each axis; Inside covers photo-edge pixels without changing dimensions. The border is saved in each non-destructive photo recipe and can be included or excluded from batch paste.
- **Composition guides**: Rule of Thirds, Golden Ratio logarithmic spiral, Center Marker, Golden Triangles, Square Grid. The spiral supports quarter-turn rotation (0, 90, 180, 270 degrees) plus mirror (8 orientations). White or black grid, opacity slider, off toggle. Grid overlays **never export**, and the guide is clipped to the actual fitted photo, not black letterboxing. Guide settings persist locally using `@AppStorage`.
- Editor toolbar now offers `Film / Tools / Lighting / Border / Grid`.
- No brand logo/text appears inside editor workflow.
- All functionality remains on-device; no server / AI API required.

## How to open

On macOS, open `orelio.xcodeproj` in Xcode (iOS 17+), configure your development team and bundle identifier, and run on an iPhone or simulator.

## Tests and limitations

`./tools/validate.sh` runs portable Swift syntax checks, project file validation and Foundation-only model smoke tests on Linux. It does **not** compile or run UIKit, SwiftUI, Core Image or the app in iOS Simulator. Build and device testing must be done in Xcode on a Mac. Border image dimensions and SwiftUI rendering are not runtime-verified here.

`MOBILE_PREVIEW_v0.5.html` is an offline clickable browser prototype: its photo treatment and export are demonstrative, not the native Core Image output. Screen samples are included only to review UX.

No RNI proprietary presets or visual assets are included. Existing film-look quality limitations and collage work remain as documented in earlier versions.
