# OverLoad

A SwiftUI app for iOS, macOS, and visionOS.

## Run in Xcode

1. Install Xcode 27 or newer and the iOS simulator components.
2. Clone this repository:

   ```sh
   git clone https://github.com/OverLoad-Devs/OverLoad.git
   cd OverLoad
   open OverLoad.xcodeproj
   ```

3. Select the shared **OverLoad** scheme and an **iPhone simulator** as the run destination.
4. Press **Command-R** to build and run.

No environment files, API keys, third-party dependencies, or development team are needed for the simulator. To run on a physical device, select your own development team under **Signing & Capabilities**.

The project targets iOS 27, macOS 26.6.2, and visionOS 27. Choose a simulator with an OS version at or above the deployment target. The app currently displays “Hello, world!”.

## Build checks

GitHub Actions builds the iOS simulator app using the shared scheme and reports the required `build` check. To run that build locally:

```sh
xcodebuild build \
  -project OverLoad.xcodeproj \
  -scheme OverLoad \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

No automated test targets are configured yet. A passing build verifies compilation; it does not guarantee the app is free of runtime crashes.
