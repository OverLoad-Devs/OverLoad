import Foundation
import SwiftData
import Testing
@testable import OverLoad

@MainActor struct WorkoutTemplateTests {
    // Test-only fixtures; no sample workouts or templates are seeded by the app.
    private func fixture() throws -> ModelContainer {
        let container = try AppPersistence.makeContainer(inMemory: true)
        let context = container.mainContext
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let template = WorkoutTemplate(name: "Pull")
        context.insert(template)
        for (index, name) in ["Pull-up", "Barbell Row", "Lat Pulldown", "Dumbbell Curl"].enumerated() {
            let exercise = try #require(exercises.first { $0.name == name })
            template.exercises.append(WorkoutTemplateExercise(exercise: exercise, orderIndex: index))
        }
        let row = try #require(exercises.first { $0.name == "Barbell Row" })
        let session = WorkoutSession(date: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(session)
        for index in 0..<3 {
            session.sets.append(WorkoutSet(exercise: row, reps: 10, weight: 135, orderIndex: index))
        }
        try context.save()
        return container
    }

    @Test func freshStoreHasNoDemoWorkoutsOrTemplates() throws {
        let container = try AppPersistence.makeContainer(inMemory: true)
        let context = container.mainContext
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 15)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()) == 0)
    }

    @Test func templateStartsOrderedBlankSetsAndSavesNameDurationAndWeights() throws {
        let container = try fixture()
        let context = container.mainContext
        let template = try #require(context.fetch(FetchDescriptor<WorkoutTemplate>()).first { $0.name == "Pull" })
        let oldSessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let model = WorkoutViewModel()
        model.start(template: template, sessions: oldSessions, at: start)
        #expect(model.workoutName == "Pull")
        #expect(model.exercises.map { $0.exercise.name } == ["Pull-up", "Barbell Row", "Lat Pulldown", "Dumbbell Curl"])
        #expect(model.setCount == 12)
        #expect(!model.canSave)
        #expect(model.exercises[1].sets[0].previous == "10 reps × 135 lb")
        #expect(model.elapsed(at: start.addingTimeInterval(3661)) == 3661)
        #expect(model.elapsed(at: start.addingTimeInterval(-10)) == 0)
        for exerciseIndex in model.exercises.indices {
            for setIndex in model.exercises[exerciseIndex].sets.indices {
                model.exercises[exerciseIndex].sets[setIndex].reps = 10
                model.exercises[exerciseIndex].sets[setIndex].weight = 50
            }
        }
        #expect(model.canSave)
        model.finish(context: context, at: start.addingTimeInterval(3661))
        #expect(!model.isActive)
        #expect(model.lastSavedSummary?.duration == 3661)
        let saved = try #require(context.fetch(FetchDescriptor<WorkoutSession>()).first { $0.date == start })
        #expect(saved.name == "Pull")
        #expect(saved.duration == 3661)
        #expect(saved.sets.count == 12)
        #expect(HistoryViewModel.volume(saved) == 6000)
        #expect(template.plannedSetCount == 12)
        #expect(template.exercises.allSatisfy { $0.targetReps == 8 })
        #expect(WorkoutDuration.formatted(3661) == "1:01:01")
        #expect(WorkoutDuration.formatted(61) == "01:01")
    }

    @Test func editAndDeleteTemplatePreserveLibraryAndHistory() throws {
        let container = try fixture()
        let context = container.mainContext
        let template = try #require(context.fetch(FetchDescriptor<WorkoutTemplate>()).first { $0.name == "Pull" })
        let originalSessionCount = try context.fetchCount(FetchDescriptor<WorkoutSession>())
        let originalEntryCount = try context.fetchCount(FetchDescriptor<WorkoutTemplateExercise>())
        let editor = TemplateEditorViewModel(template: template)
        editor.name = "  Pull A  "
        editor.exercises.removeLast()
        editor.exercises[0].setCount = 2
        #expect(editor.save(context: context))
        #expect(template.name == "Pull A")
        #expect(template.orderedExercises.count == 3)
        #expect(template.plannedSetCount == 8)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplateExercise>()) == originalEntryCount - 1)
        WorkoutViewModel().deleteTemplate(template, context: context)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplateExercise>()) == originalEntryCount - 4)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == originalSessionCount)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 15)
    }

    @Test func templatePersistsAcrossContainerRecreation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("workouts.store")
        try autoreleasepool {
            let container = try AppPersistence.makeContainer(storeURL: url)
            let exercise = try #require(container.mainContext.fetch(FetchDescriptor<Exercise>()).first)
            let editor = TemplateEditorViewModel()
            #expect(!editor.canSave)
            editor.name = "Pull"
            editor.add(exercise)
            editor.add(exercise)
            #expect(editor.exercises.count == 1)
            #expect(editor.save(context: container.mainContext))
        }
        let reopened = try AppPersistence.makeContainer(storeURL: url)
        let saved = try #require(reopened.mainContext.fetch(FetchDescriptor<WorkoutTemplate>()).first)
        #expect(saved.name == "Pull")
        #expect(saved.plannedSetCount == 3)
        #expect(saved.exercises[0].template?.id == saved.id)
    }

    @Test func cancelledTemplateWorkoutDoesNotCreateHistory() throws {
        let container = try fixture()
        let template = try #require(container.mainContext.fetch(FetchDescriptor<WorkoutTemplate>()).first)
        let sessions = try container.mainContext.fetch(FetchDescriptor<WorkoutSession>())
        let model = WorkoutViewModel()
        model.start(template: template, sessions: sessions)
        model.cancel()
        #expect(!model.isActive)
        #expect(model.exercises.isEmpty)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<WorkoutSession>()) == sessions.count)
    }
}
