import Foundation
import SwiftData

@Model final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateExercise.template)
    var exercises: [WorkoutTemplateExercise] = []

    var orderedExercises: [WorkoutTemplateExercise] { exercises.sorted { $0.orderIndex < $1.orderIndex } }
    var plannedSetCount: Int { exercises.reduce(0) { $0 + $1.setCount } }

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

@Model final class WorkoutTemplateExercise {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise
    var setCount: Int
    var targetReps: Int
    var orderIndex: Int
    var template: WorkoutTemplate?

    init(exercise: Exercise, setCount: Int = 3, targetReps: Int = 8, orderIndex: Int) {
        id = UUID()
        self.exercise = exercise
        self.setCount = setCount
        self.targetReps = targetReps
        self.orderIndex = orderIndex
    }
}
