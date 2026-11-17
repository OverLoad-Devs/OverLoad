import Foundation

/// Shared adapter: only completed, saved sessions enter the engine.
enum LoadCoachViewModel {
    static func suggestion(for exercise: Exercise, sessions: [WorkoutSession]) -> Suggestion {
        let history = sessions.sorted { $0.date < $1.date }.compactMap { session -> [SetRecord]? in
            let sets = session.sets.filter { $0.exercise.id == exercise.id }.sorted { $0.orderIndex < $1.orderIndex }
            guard !sets.isEmpty else { return nil }
            return sets.map { SetRecord(reps: $0.reps, weight: $0.weight, date: session.date) }
        }
        return LoadCoachEngine.suggestNext(history: history)
    }
}
