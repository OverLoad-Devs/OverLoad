import Foundation
import SwiftData
import Testing
@testable import OverLoad

@MainActor struct WorkoutPersistenceTests {
    @Test func seedAndFinishRoundTrip() throws {
        let container = try AppPersistence.makeContainer(inMemory: true)
        let context = container.mainContext
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 15)
        let exercise = try #require(exercises.first)
        let model = WorkoutViewModel()
        model.start()
        model.add(exercise)
        model.add(exercise)
        #expect(model.exercises.count == 1)
        model.addSet(to: exercise.id, suggestion: Suggestion(weight: 95, reps: 10, status: .hold, reason: "Test"))
        model.finish(context: context)
        #expect(!model.isActive)
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let session = try #require(sessions.first)
        #expect(sessions.count == 1)
        #expect(session.sets.count == 1)
        #expect(session.sets.first?.session?.id == session.id)
        #expect(HistoryViewModel.volume(session) == 950)
        #expect(HistoryViewModel.groups(session).first?.exercise.id == exercise.id)
        #expect(LoadCoachViewModel.suggestion(for: exercise, sessions: sessions).reps == 11)
        context.delete(session)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 15)
    }

    @Test func invalidDraftDoesNotSaveAndCancelDiscards() throws {
        let container = try AppPersistence.makeContainer(inMemory: true)
        let model = WorkoutViewModel()
        let exercise = try #require(container.mainContext.fetch(FetchDescriptor<Exercise>()).first)
        model.start()
        model.add(exercise)
        model.addSet(to: exercise.id, suggestion: LoadCoachEngine.suggestNext(history: []))
        model.exercises[0].sets[0].reps = 0
        model.finish(context: container.mainContext)
        #expect(model.errorMessage != nil)
        #expect(model.isActive)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<WorkoutSession>()) == 0)
        model.cancel()
        #expect(!model.isActive)
        #expect(model.exercises.isEmpty)
    }
}
