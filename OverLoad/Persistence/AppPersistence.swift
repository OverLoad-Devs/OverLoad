import SwiftData

@MainActor enum AppPersistence {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([Exercise.self, WorkoutSession.self, WorkoutSet.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)])
        let context = container.mainContext
        if try context.fetchCount(FetchDescriptor<Exercise>()) == 0 {
            for exercise in SampleData.exercises() { context.insert(exercise) }
            try context.save()
        }
        return container
    }
}
