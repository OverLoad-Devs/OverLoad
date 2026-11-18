import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query private var sessions: [WorkoutSession]
    @State private var model = WorkoutViewModel()
    @State private var showPicker = false
    @State private var confirmCancel = false
    @State private var exerciseToRemove: DraftExercise?
    @State private var confirmRemove = false
    @State private var showCreateTemplate = false
    @State private var editingTemplate: WorkoutTemplate?
    @State private var templateToDelete: WorkoutTemplate?
    @State private var confirmDeleteTemplate = false

    var body: some View {
        NavigationStack {
            Group {
                if model.isActive {
                    List {
                        Section {
                            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                                Label(WorkoutDuration.formatted(model.elapsed(at: timeline.date)), systemImage: "timer")
                                    .font(.title2.monospacedDigit())
                                    .accessibilityLabel("Elapsed workout time")
                                    .accessibilityValue(WorkoutDuration.formatted(model.elapsed(at: timeline.date)))
                            }
                            Text("\(model.exercises.count) exercises · \(model.setCount) sets")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("Weights are in pounds. Use 0 lb for bodyweight. Swipe a set to delete it.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach($model.exercises) { $entry in
                            Section {
                                CoachSuggestionView(suggestion: suggestion(entry.exercise))
                                ForEach($entry.sets) { $set in
                                    SetRow(number: (entry.sets.firstIndex { $0.id == set.id } ?? 0) + 1, set: $set)
                                }.onDelete { entry.sets.remove(atOffsets: $0) }
                                Button("Add set", systemImage: "plus") {
                                    model.addSet(to: entry.id, suggestion: suggestion(entry.exercise))
                                }
                            } header: {
                                HStack {
                                    Text(entry.exercise.name)
                                    Spacer()
                                    Button {
                                        if entry.sets.isEmpty { model.removeExercise(id: entry.id) }
                                        else { exerciseToRemove = entry; confirmRemove = true }
                                    } label: { Image(systemName: "trash") }
                                    .accessibilityLabel("Remove \(entry.exercise.name) from workout")
                                }
                            }
                        }
                        Button("Pick exercise", systemImage: "plus.circle") { showPicker = true }
                        if let error = model.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                        }
                        if model.setCount > 0 && !model.canSave {
                            Text("Fill in reps and weight for each set, or swipe to remove a skipped set.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Button("Finish & Save") { model.finish(context: context) }
                            .disabled(!model.canSave)
                    }
                } else {
                    List {
                        if let summary = model.lastSavedSummary {
                            Section {
                                Label("\(summary.name) saved", systemImage: "checkmark.circle.fill")
                                    .font(.headline).foregroundStyle(.green)
                                Text("\(summary.setCount) sets · \(WorkoutDuration.formatted(summary.duration)) · \(summary.volume.formatted()) lb·reps")
                                Text("View your weights and sets in History.").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Section {
                            Button("Create Workout", systemImage: "plus.circle.fill") { showCreateTemplate = true }
                            Button("Start Empty Workout", systemImage: "play") { model.start() }
                        }
                        Section("Your workouts") {
                            if templates.isEmpty {
                                Text("Create a workout like Pull, add your exercises and planned sets, then start it here.")
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(templates) { template in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(template.name).font(.headline)
                                    Text(template.orderedExercises
                                        .map { $0.exercise.name }.joined(separator: " · "))
                                        .font(.subheadline).foregroundStyle(.secondary)
                                    Text("\(template.exercises.count) exercises · \(template.plannedSetCount) planned sets")
                                        .font(.caption).foregroundStyle(.secondary)
                                    HStack {
                                        Button("Start", systemImage: "play.fill") {
                                            model.start(template: template, sessions: sessions)
                                        }.buttonStyle(.borderedProminent)
                                        Spacer()
                                        Button("Edit", systemImage: "pencil") { editingTemplate = template }
                                            .buttonStyle(.borderless)
                                        Button(role: .destructive) {
                                            templateToDelete = template; confirmDeleteTemplate = true
                                        } label: { Image(systemName: "trash") }
                                            .buttonStyle(.borderless)
                                            .accessibilityLabel("Delete \(template.name) template")
                                    }
                                }.padding(.vertical, 6)
                            }
                        }
                        if let error = model.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(model.isActive ? model.workoutName : "Workout")
            .toolbar {
                if model.isActive {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel", role: .destructive) { confirmCancel = true }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
            .confirmationDialog("Discard this workout?", isPresented: $confirmCancel, titleVisibility: .visible) {
                Button("Discard workout", role: .destructive) { model.cancel() }
            }
            .confirmationDialog("Remove \(exerciseToRemove?.exercise.name ?? "exercise") and its sets?",
                                isPresented: $confirmRemove,
                                titleVisibility: .visible) {
                Button("Remove from workout", role: .destructive) {
                    if let entry = exerciseToRemove { model.removeExercise(id: entry.id) }
                    exerciseToRemove = nil
                }
            } message: {
                Text("This only removes it from this draft. Your saved history stays unchanged.")
            }
            .confirmationDialog("Delete \(templateToDelete?.name ?? "workout") template?",
                                isPresented: $confirmDeleteTemplate, titleVisibility: .visible) {
                Button("Delete template", role: .destructive) {
                    if let template = templateToDelete {
                        model.deleteTemplate(template, context: context)
                    }
                    templateToDelete = nil
                }
            } message: { Text("Your completed workouts and exercise library stay unchanged.") }
            .sheet(isPresented: $showCreateTemplate) { TemplateEditorView() }
            .sheet(item: $editingTemplate) { TemplateEditorView(template: $0) }
            .sheet(isPresented: $showPicker) {
                ExercisePickerView(selectedIDs: Set(model.exercises.map(\.id))) { model.add($0) }
            }
        }
    }

    private func suggestion(_ exercise: Exercise) -> Suggestion {
        LoadCoachViewModel.suggestion(for: exercise, sessions: sessions)
    }
}

#Preview { WorkoutView().modelContainer(SampleData.preview()) }
