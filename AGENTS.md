# OverLoad

OverLoad is a SwiftUI app. Open `OverLoad.xcodeproj` in Xcode and use the shared `OverLoad` scheme.

## Repository layout

- `OverLoad/`: app source and asset catalogs.
- `OverLoad.xcodeproj/project.pbxproj`: committed Xcode project configuration.
- `OverLoad.xcodeproj/project.xcworkspace/`: committed workspace configuration; personal `xcuserdata` is ignored.
- `OverLoad.xcodeproj/xcshareddata/xcschemes/OverLoad.xcscheme`: shared build scheme.
- `.github/workflows/ci.yml`: GitHub Actions workflow with the required `build` check.

## Validation

Run the same simulator build used by CI:

```sh
xcodebuild build \
  -project OverLoad.xcodeproj \
  -scheme OverLoad \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

The project currently requires Xcode 27 and targets iOS 27. CI uses the `xcode-27` runner. Keep the required `build` check enabled.

No unit-test or UI-test targets are currently configured. When adding tests, create Xcode test targets and include them in the shared scheme and CI; empty test folders do not run tests.

## Working conventions

Commit app sources, assets, project configuration, and shared schemes. Keep build output, personal Xcode settings, and local secrets out of Git. Preserve unrelated user changes.
