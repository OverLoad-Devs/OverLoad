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
    @Test func searchMatchesNamesAndMuscles() {
        let bench = Exercise(name: "Bench Press", primary: .chest, secondary: [.triceps])
        let squat = Exercise(name: "Squat", primary: .quads)
        #expect(WorkoutViewModel.matchingExercises([bench, squat], search: " BENCH ").map(\.id) == [bench.id])
        #expect(WorkoutViewModel.matchingExercises([bench, squat], search: "triceps").map(\.id) == [bench.id])
        #expect(WorkoutViewModel.matchingExercises([bench, squat], search: "quads").map(\.id) == [squat.id])
        #expect(WorkoutViewModel.matchingExercises([bench], search: "missing").isEmpty)
    }

    @Test func blankAndInvalidInputsBlockSaving() {
        var set = DraftSet(reps: 8, weight: 95)
        set.repsText = ""
        #expect(set.validationMessage != nil)
        set.repsText = "8.5"
        #expect(set.validationMessage != nil)
        set.repsText = "8"
        set.weightText = ""
        #expect(set.validationMessage != nil)
        set.weightText = "-1"
        #expect(set.validationMessage != nil)
        set.weightText = "nan"
        #expect(set.validationMessage != nil)
        set.weightText = "0"
        #expect(set.validationMessage == nil)
    }

    @Test func removingExerciseOnlyChangesDraftAndSaveShowsSummary() throws {
        let container = try AppPersistence.makeContainer(inMemory: true)
        let context = container.mainContext
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let model = WorkoutViewModel()
        let first = try #require(exercises.first)
        let second = try #require(exercises.last)
        model.start()
        model.add(first)
        model.add(second)
        let suggestion = Suggestion(weight: 95, reps: 10, status: .hold, reason: "Test")
        model.addSet(to: first.id, suggestion: suggestion)
        model.addSet(to: second.id, suggestion: suggestion)
        model.removeExercise(id: first.id)
        #expect(model.setCount == 1)
        model.exercises[0].sets[0].weightText = ""
        #expect(!model.canSave)
        model.exercises[0].sets[0].weightText = "95"
        #expect(model.canSave)
        model.finish(context: context)
        #expect(model.lastSavedSummary?.setCount == 1)
        #expect(model.lastSavedSummary?.volume == 950)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 15)
        let session = try #require(context.fetch(FetchDescriptor<WorkoutSession>()).first)
        #expect(session.sets.first?.exercise.id == second.id)
        model.start()
        #expect(model.lastSavedSummary == nil)
        #expect(!model.canSave)
    }

}
