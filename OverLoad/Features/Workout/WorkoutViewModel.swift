import Foundation
import Observation
import SwiftData

struct DraftSet: Identifiable {
    let id = UUID()
    var reps = 8
    var weight = 0.0
}

struct DraftExercise: Identifiable {
    var id: UUID { exercise.id }
    let exercise: Exercise
    var sets: [DraftSet] = []
}

@Observable final class WorkoutViewModel {
    private(set) var startedAt: Date?
    var exercises: [DraftExercise] = []
    var errorMessage: String?
    var isActive: Bool { startedAt != nil }
    var canSave: Bool { exercises.contains { !$0.sets.isEmpty } }

    func start() { startedAt = .now; exercises = []; errorMessage = nil }
    func cancel() { startedAt = nil; exercises = []; errorMessage = nil }
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
        guard let startedAt, canSave else { return }
        let allSets = exercises.flatMap(\.sets)
        guard allSets.allSatisfy({ $0.reps > 0 && $0.weight >= 0 && $0.weight.isFinite }) else {
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
        do { try context.save(); cancel() }
        catch {
            context.delete(session)
            errorMessage = "Could not save workout: \(error.localizedDescription). Your draft is still available."
        }
    }
}
