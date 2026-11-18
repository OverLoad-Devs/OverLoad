# OverLoad

An iOS 17+ SwiftUI workout app for CSC 211, using SwiftData and no third-party dependencies.

## Run

1. Clone this repository and open `OverLoad.xcodeproj`.
2. Use Xcode 27 (matching the committed project format and CI). Install an iOS simulator runtime.
3. Select the shared **OverLoad** scheme and an iPhone simulator running iOS 17+.
4. Press **Command-R**. No API keys, environment files, or development team are needed for the simulator. Physical devices require your own signing team.

The app seeds 15 exercises on first launch. Start a workout, search exercises by name or muscle group, add sets, enter reps and pounds, and finish to save. Blank or invalid set fields show a message and block saving. Remove draft exercises with the trash button, or swipe a set to delete it. Finishing shows a saved-workout summary. Saved sessions appear in History and inform Load Coach suggestions. Cancel discards the draft; drafts do not survive app termination. Training Path is a team-owned placeholder.

## Tests and collaboration

Press **Command-U** to run the Swift Testing suite in `OverLoadTests`. CI builds and tests on pushes to `dev` and pull requests into `main`. Work on `dev`, then merge through a passing pull request. See [AGENTS.md](AGENTS.md) for model fields, folder ownership, validation commands, and the starter Load Coach rules.
