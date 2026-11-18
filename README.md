# OverLoad

An iOS 17+ SwiftUI workout app for CSC 211, using SwiftData and no third-party dependencies.

## Run

1. Clone this repository and open `OverLoad.xcodeproj`.
2. Use Xcode 27 (matching the committed project format and CI). Install an iOS simulator runtime.
3. Select the shared **OverLoad** scheme and an iPhone simulator running iOS 17+.
4. Press **Command-R**. No API keys, environment files, or development team are needed for the simulator. Physical devices require your own signing team.

The app seeds 15 exercises on first launch. Start a workout, search exercises by name or muscle group, add sets, enter reps and pounds, and finish to save. Blank or invalid set fields show a message and block saving. Remove draft exercises with the trash button, or swipe a set to delete it. Finishing shows a saved-workout summary. Saved sessions appear in History and inform Load Coach suggestions. Cancel discards the draft; drafts do not survive app termination. Training Path is a team-owned placeholder.

## Tests and collaboration

Press **Command-U** to run the Swift Testing suite in `OverLoadTests`. CI builds and tests on pushes to `dev` and pull requests into `main`. Build on a feature branch, then open a PR into `dev` when the work is ready. Promote reviewed work from `dev` to `main` through a separate passing PR. See [AGENTS.md](AGENTS.md) for model fields, folder ownership, validation commands, and the starter Load Coach rules.

## Create and run a reusable workout

1. Open **Workout → Create Workout**, name it (for example, **Pull**), and add exercises.
2. Choose each exercise’s planned set count and target reps. Use **Edit** to reorder exercises, then **Save**.
3. Tap **Start** on that workout. Its exercises and set rows are already laid out, and the elapsed timer starts.
4. Enter actual reps and pounds for each set. Previous logged reps/weights appear as a reference when available. Swipe away skipped sets; all remaining rows must be filled before saving.
5. Tap **Finish & Save**. History keeps the workout name, duration, every set’s weight/reps, and total volume.

Edit or delete a saved workout routine without changing past sessions. You can still start an empty workout. The timer includes time outside the app, but an unfinished session is lost if the app is terminated.
