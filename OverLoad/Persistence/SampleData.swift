import Foundation
import SwiftData

@MainActor enum SampleData {
    static func exercises() -> [Exercise] {
        [Exercise(name: "Bench Press", primary: .chest, secondary: [.triceps, .shoulders]),
         Exercise(name: "Squat", primary: .quads, secondary: [.glutes, .core]),
         Exercise(name: "Deadlift", primary: .hamstrings, secondary: [.glutes, .back]),
         Exercise(name: "Overhead Press", primary: .shoulders, secondary: [.triceps]),
         Exercise(name: "Barbell Row", primary: .back, secondary: [.biceps]),
         Exercise(name: "Pull-up", primary: .back, secondary: [.biceps]),
         Exercise(name: "Lat Pulldown", primary: .back, secondary: [.biceps]),
         Exercise(name: "Dumbbell Curl", primary: .biceps),
         Exercise(name: "Triceps Pushdown", primary: .triceps),
         Exercise(name: "Leg Press", primary: .quads, secondary: [.glutes]),
         Exercise(name: "Romanian Deadlift", primary: .hamstrings, secondary: [.glutes]),
         Exercise(name: "Hip Thrust", primary: .glutes),
         Exercise(name: "Calf Raise", primary: .calves),
         Exercise(name: "Lateral Raise", primary: .shoulders),
         Exercise(name: "Cable Crunch", primary: .core)]
    }

    static func preview() -> ModelContainer {
        do {
            let container = try AppPersistence.makeContainer(inMemory: true)
            let context = container.mainContext
            let exercises = try context.fetch(FetchDescriptor<Exercise>())
            if let exercise = exercises.first {
                let session = WorkoutSession(date: .now.addingTimeInterval(-86400))
                context.insert(session)
                for index in 0..<3 {
                    let set = WorkoutSet(exercise: exercise, reps: 10, weight: 95, orderIndex: index)
                    session.sets.append(set)
                }
                try context.save()
            }
            return container
        } catch { fatalError("Preview data could not be created: \(error)") }
    }
}
