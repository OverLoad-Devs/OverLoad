# OverLoad

CSC 211 HCI workout app. Swift, SwiftUI, SwiftData; iOS 17+. No third-party dependencies. Open `OverLoad.xcodeproj` and choose the shared `OverLoad` scheme. Use Xcode 27 for the committed project format and CI. The app deployment target is iOS 17, independently of the Xcode version.

## Structure

```text
OverLoad/
  App/OverLoadApp.swift             Persistent container and startup error handling
  App/RootTabView.swift             Four independent navigation tabs
  Models/WorkoutModels.swift       Shared SwiftData models and MuscleGroup
  Persistence/AppPersistence.swift Container creation and first-launch exercise seed
  Persistence/SampleData.swift     15 exercises and isolated in-memory preview data
  Features/Workout/
    WorkoutView.swift              Start, select exercises, edit sets, finish/cancel
    WorkoutViewModel.swift         DraftSet, DraftExercise, validation and save
  Features/History/
    HistoryView.swift              Saved sessions
    SessionDetailView.swift        Exercise sets and total volume
    HistoryViewModel.swift         Grouping and volume calculation
  Features/LoadCoach/
    LoadCoachEngine.swift          Pure input/output structs, config, engine
    LoadCoachViewModel.swift       Model-to-engine adapter (completed sessions only)
    LoadCoachView.swift            Exercise suggestions, badges and reasons
  Features/TrainingPath/
    TrainingPathView.swift         TODO placeholder; Training Path team owns logic
  Shared/
    SetRow.swift                   Reps/weight editor
    StatCard.swift                 Summary metric
    CoachSuggestionView.swift     Inline suggestion and status
  Assets.xcassets/
OverLoadTests/LoadCoachEngineTests.swift
OverLoadTests/WorkoutPersistenceTests.swift
.github/workflows/ci.yml
```

## Shared models

- `MuscleGroup`: String, Codable, CaseIterable; chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core.
- `Exercise`: unique UUID `id`, String `name`, MuscleGroup `primary`, [MuscleGroup] `secondary`.
- `WorkoutSession`: unique UUID `id`, Date `date`, [WorkoutSet] `sets`. Sets cascade-delete with the session, with inverse `WorkoutSet.session`.
- `WorkoutSet`: unique UUID `id`, Exercise `exercise`, Int `reps`, Double `weight` in pounds, Int `orderIndex`, optional WorkoutSession `session` inverse.

Users log only reps and weight. Do not add RPE, effort, or rating fields. Zero pounds represents bodyweight; volume is external load × reps, so bodyweight sets contribute zero. Exercise deletion is not exposed.

Draft workouts live in an `@Observable` view model, not SwiftData. Finish validates and saves a complete session; cancel discards the draft. Unsaved drafts do not survive app termination. Never put business rules in views. Every custom view has an in-memory-data preview.

## Load Coach rules

`LoadCoachConfig` centralizes starter constants: rep range 8–12, +5 lb progression, 3-session plateau window, 2 consecutive plateau checks, 2 low-rep sessions, 10% deload, nearest-5-lb rounding. These are placeholders for the Load Coach team to tune.

`LoadCoachEngine` imports Foundation only. Input is sessions for one exercise, oldest to newest. Empty sessions and invalid sets are ignored. The adapter excludes sessions without the selected exercise.

- No history: 0 lb, 8 reps, Hold, “Log your first session”.
- Every set reaches at least 12 reps: add 5 lb and target 8 reps.
- Otherwise hold the top-set weight and target one more rep, clamped to 8–12.
- Plateau: each session's best weight × reps fails to improve over its predecessor across the last 3 sessions.
- Two consecutive overlapping plateau windows (at least 4 sessions), or top sets below 8 reps twice: deload 10%, round to nearest 5 lb (ties away from zero), target 8 reps.
- Precedence: Deload → Plateau → Progress → Hold. Top set means heaviest weight, ties resolved by highest reps. Suggestions are advisory; they do not modify logged sets. No-history suggestions are starting placeholders, not personalized load prescriptions.

## Validation

```sh
xcodebuild build -project OverLoad.xcodeproj -scheme OverLoad \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project OverLoad.xcodeproj -scheme OverLoad \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' CODE_SIGNING_ALLOWED=NO
```

Use an installed iPhone simulator (iOS 17+); substitute its name if needed. CI selects an available iPhone automatically and runs the Swift Testing target under the required `build` job. Keep that check enabled.

## Collaboration

Work on `dev`; push there, let CI pass, and use a pull request into `main`. Load Coach and Training Path teams own their feature folders; coordinate changes to shared models, persistence, workout and history. Do not implement Training Path logic in this scaffold.

Commit sources, assets, project configuration, and shared schemes. Keep build output, personal Xcode settings, and secrets out of Git. Preserve unrelated user changes.
