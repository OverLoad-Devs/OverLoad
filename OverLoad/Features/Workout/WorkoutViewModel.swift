import Foundation
import Observation
import SwiftData

struct DraftSet: Identifiable {
    let id = UUID()
    var repsText: String
    var weightText: String

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

struct DraftExercise: Identifiable {
    var id: UUID { exercise.id }
    let exercise: Exercise
    var sets: [DraftSet] = []
}

struct SavedWorkoutSummary {
    let setCount: Int
    let volume: Double
}

@Observable final class WorkoutViewModel {
    private(set) var startedAt: Date?
    var exercises: [DraftExercise] = []
    var errorMessage: String?
    private(set) var lastSavedSummary: SavedWorkoutSummary?
    var setCount: Int { exercises.reduce(0) { $0 + $1.sets.count } }
    var isActive: Bool { startedAt != nil }
    var canSave: Bool {
        isActive && setCount > 0 && exercises.flatMap(\.sets).allSatisfy { $0.validationMessage == nil }
    }

    func start() { startedAt = .now; exercises = []; errorMessage = nil; lastSavedSummary = nil }
    func cancel() { startedAt = nil; exercises = []; errorMessage = nil }
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
        let previous = exercises[index].sets.last
        exercises[index].sets.append(DraftSet(reps: previous?.reps ?? suggestion.reps,
                                               weight: previous?.weight ?? suggestion.weight))
    }
    func finish(context: ModelContext) {
        guard let startedAt, setCount > 0 else { return }
        let allSets = exercises.flatMap(\.sets)
        guard allSets.allSatisfy({ $0.validationMessage == nil }) else {
            errorMessage = "Enter positive reps and a nonnegative weight for every set."
            return
        }
        let session = WorkoutSession(date: startedAt)
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
            let summary = SavedWorkoutSummary(setCount: allSets.count,
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
