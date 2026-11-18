import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable {
    case chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core
}

@Model final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var primary: MuscleGroup
    var secondary: [MuscleGroup]

    init(id: UUID = UUID(), name: String, primary: MuscleGroup, secondary: [MuscleGroup] = []) {
        self.id = id; self.name = name; self.primary = primary; self.secondary = secondary
    }
}

@Model final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var name: String = "Workout"
    var duration: TimeInterval?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session) var sets: [WorkoutSet] = []

    init(id: UUID = UUID(), date: Date = .now, name: String = "Workout", duration: TimeInterval? = nil) {
        self.id = id; self.date = date; self.name = name; self.duration = duration
    }
}

@Model final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise
    var reps: Int
    /// Weight in pounds, including zero for bodyweight movements.
    var weight: Double
    var orderIndex: Int
    var session: WorkoutSession?

    init(id: UUID = UUID(), exercise: Exercise, reps: Int, weight: Double, orderIndex: Int,
         session: WorkoutSession? = nil) {
        self.id = id; self.exercise = exercise; self.reps = reps; self.weight = weight
        self.orderIndex = orderIndex; self.session = session
    }
}
