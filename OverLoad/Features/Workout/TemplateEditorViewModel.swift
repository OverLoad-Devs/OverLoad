import Foundation
import Observation
import SwiftData

struct PlannedExercise: Identifiable {
    var id: UUID { exercise.id }
    let exercise: Exercise
    var setCount = 3
    var targetReps = 8
}

@Observable final class TemplateEditorViewModel {
    var name: String
    var exercises: [PlannedExercise]
    var errorMessage: String?
    private let template: WorkoutTemplate?
    var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !exercises.isEmpty }

    init(template: WorkoutTemplate? = nil) {
        self.template = template
        name = template?.name ?? ""
        exercises = template?.orderedExercises.map {
            PlannedExercise(exercise: $0.exercise, setCount: $0.setCount, targetReps: $0.targetReps)
        } ?? []
    }

    func add(_ exercise: Exercise) {
        guard !exercises.contains(where: { $0.id == exercise.id }) else { return }
        exercises.append(PlannedExercise(exercise: exercise))
    }

    @discardableResult func save(context: ModelContext) -> Bool {
        guard canSave, exercises.allSatisfy({ (1...10).contains($0.setCount) && (1...100).contains($0.targetReps) }) else {
            errorMessage = "Add a workout name and at least one exercise with valid sets and reps."
            return false
        }
        let saved = template ?? WorkoutTemplate(name: name)
        let originalExercises = saved.exercises
        if template == nil { context.insert(saved) }
        saved.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let entries = exercises.enumerated().map { index, planned in
            WorkoutTemplateExercise(exercise: planned.exercise, setCount: planned.setCount,
                                    targetReps: planned.targetReps, orderIndex: index)
        }
        saved.exercises = entries
        // Remove old entries only when replaced; library exercises and history are untouched.
        for entry in originalExercises { context.delete(entry) }
        do { try context.save(); return true }
        catch {
            context.rollback()
            name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            errorMessage = "Could not save workout: \(error.localizedDescription). Your edits are still here."
            return false
        }
    }
}
