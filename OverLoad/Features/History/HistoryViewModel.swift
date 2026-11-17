import Foundation

struct SessionExerciseSummary: Identifiable {
    var id: UUID { exercise.id }
    let exercise: Exercise
    let sets: [WorkoutSet]
}

enum HistoryViewModel {
    static func volume(_ session: WorkoutSession) -> Double {
        session.sets.reduce(0) { $0 + Double($1.reps) * $1.weight }
    }
    static func groups(_ session: WorkoutSession) -> [SessionExerciseSummary] {
        let ordered = session.sets.sorted { $0.orderIndex < $1.orderIndex }
        var groups: [SessionExerciseSummary] = []
        for set in ordered where !groups.contains(where: { $0.id == set.exercise.id }) {
            groups.append(SessionExerciseSummary(exercise: set.exercise,
                                                  sets: ordered.filter { $0.exercise.id == set.exercise.id }))
        }
        return groups
    }
}
