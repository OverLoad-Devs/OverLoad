import Foundation
import Observation
import SwiftData

struct DraftSet: Identifiable {
    let id = UUID()
    var repsText: String
    var weightText: String
    var previous: String?
    var targetReps: Int?

    var reps: Int {
        get { Int(repsText.trimmingCharacters(in: .whitespaces)) ?? 0 }
        set { repsText = String(newValue) }
    }
    var weight: Double {
        get {
            let normalized = weightText.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
            return Double(normalized) ?? .nan
        }
        set { weightText = String(newValue) }
    }
    var validationMessage: String? {
        if reps <= 0 { return "Enter a whole number of reps greater than zero." }
        if !weight.isFinite || weight < 0 { return "Enter a weight of zero or more pounds." }
        return nil
    }

    init(reps: Int = 8, weight: Double = 0) {
        repsText = String(reps)
        weightText = String(weight).replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ".")
    }
}

enum WorkoutDuration {
    static func formatted(_ duration: TimeInterval) -> String {
        let seconds = Int(max(0, duration))
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct DraftExercise: Identifiable {
    var id: UUID { exercise.id }
    let exercise: Exercise
    var sets: [DraftSet] = []
}

struct SavedWorkoutSummary {
    let name: String
    let duration: TimeInterval
    let setCount: Int
    let volume: Double
}

@Observable final class WorkoutViewModel {
    private(set) var workoutName = "Workout"
    private(set) var startedAt: Date?
    var exercises: [DraftExercise] = []
    var errorMessage: String?
    private(set) var lastSavedSummary: SavedWorkoutSummary?
    var setCount: Int { exercises.reduce(0) { $0 + $1.sets.count } }
    var isActive: Bool { startedAt != nil }
    var canSave: Bool {
        isActive && setCount > 0 && exercises.flatMap(\.sets).allSatisfy { $0.validationMessage == nil }
    }

    func start(at date: Date = .now) {
        startedAt = date; workoutName = "Workout"; exercises = []; errorMessage = nil; lastSavedSummary = nil
    }

    func start(template: WorkoutTemplate, sessions: [WorkoutSession], at date: Date = .now) {
        start(at: date)
        workoutName = template.name
        exercises = template.orderedExercises.map { planned in
            let previousSession = sessions.filter { session in
                session.sets.contains { $0.exercise.id == planned.exercise.id }
            }.max { $0.date < $1.date }
            let previousSets = previousSession?.sets.filter { $0.exercise.id == planned.exercise.id }
                .sorted { $0.orderIndex < $1.orderIndex } ?? []
            let sets = (0..<planned.setCount).map { index in
                var set = DraftSet()
                set.repsText = ""
                set.weightText = ""
                set.targetReps = planned.targetReps
                if index < previousSets.count {
                    let previous = previousSets[index]
                    set.previous = "\(previous.reps) reps × \(previous.weight.formatted()) lb"
                }
                return set
            }
            return DraftExercise(exercise: planned.exercise, sets: sets)
        }
    }

    func elapsed(at date: Date = .now) -> TimeInterval {
        guard let startedAt else { return 0 }
        return max(0, date.timeIntervalSince(startedAt))
    }
    func cancel() { startedAt = nil; exercises = []; errorMessage = nil }
    func deleteTemplate(_ template: WorkoutTemplate, context: ModelContext) {
        context.delete(template)
        do { try context.save() }
        catch {
            context.rollback()
            errorMessage = "Could not delete template: \(error.localizedDescription)"
        }
    }

    func removeExercise(id: UUID) {
        exercises.removeAll { $0.id == id }
        errorMessage = nil
    }

    static func matchingExercises(_ exercises: [Exercise], search: String) -> [Exercise] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return exercises }
        return exercises.filter {
            $0.name.localizedStandardContains(query) || $0.primary.rawValue.localizedStandardContains(query)
                || $0.secondary.contains { $0.rawValue.localizedStandardContains(query) }
        }
    }

    func add(_ exercise: Exercise) {
        guard !exercises.contains(where: { $0.id == exercise.id }) else { return }
        exercises.append(DraftExercise(exercise: exercise))
    }
    func addSet(to id: UUID, suggestion: Suggestion) {
        guard let index = exercises.firstIndex(where: { $0.id == id }) else { return }
        let previous = exercises[index].sets.last.flatMap { $0.validationMessage == nil ? $0 : nil }
        exercises[index].sets.append(DraftSet(reps: previous?.reps ?? suggestion.reps,
                                               weight: previous?.weight ?? suggestion.weight))
    }
    func finish(context: ModelContext, at endDate: Date = .now) {
        guard let startedAt, setCount > 0 else { return }
        let allSets = exercises.flatMap(\.sets)
        guard allSets.allSatisfy({ $0.validationMessage == nil }) else {
            errorMessage = "Enter positive reps and a nonnegative weight for every set."
            return
        }
        let duration = elapsed(at: endDate)
        let session = WorkoutSession(date: startedAt, name: workoutName, duration: duration)
        context.insert(session)
        var order = 0
        for entry in exercises {
            for draft in entry.sets {
                session.sets.append(WorkoutSet(exercise: entry.exercise, reps: draft.reps,
                                              weight: draft.weight, orderIndex: order))
                order += 1
            }
        }
        do {
            try context.save()
            let summary = SavedWorkoutSummary(name: workoutName, duration: duration, setCount: allSets.count,
                                              volume: allSets.reduce(0) { $0 + Double($1.reps) * $1.weight })
            cancel()
            lastSavedSummary = summary
        }
        catch {
            context.delete(session)
            errorMessage = "Could not save workout: \(error.localizedDescription). Your draft is still available."
        }
    }
}
