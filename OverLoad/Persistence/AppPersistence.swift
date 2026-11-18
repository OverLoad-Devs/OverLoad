import Foundation
import SwiftData

@MainActor enum AppPersistence {
    static var schema: Schema {
        Schema([Exercise.self, WorkoutSession.self, WorkoutSet.self, WorkoutTemplate.self, WorkoutTemplateExercise.self])
    }

    static func makeContainer(inMemory: Bool = false, storeURL: URL? = nil) throws -> ModelContainer {
        let schema = schema
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        }
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        if try context.fetchCount(FetchDescriptor<Exercise>()) == 0 {
            for exercise in SampleData.exercises() { context.insert(exercise) }
            try context.save()
        }
        return container
    }
}
