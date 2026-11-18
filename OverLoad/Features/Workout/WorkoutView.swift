import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]
    @State private var model = WorkoutViewModel()
    @State private var showPicker = false
    @State private var confirmCancel = false
    @State private var exerciseToRemove: DraftExercise?
    @State private var confirmRemove = false

    var body: some View {
        NavigationStack {
            Group {
                if model.isActive {
                    List {
                        Section {
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
                        Button("Finish & Save") { model.finish(context: context) }
                            .disabled(!model.canSave)
                    }
                } else {
                    VStack(spacing: 20) {
                        if let summary = model.lastSavedSummary {
                            Label("Workout saved", systemImage: "checkmark.circle.fill")
                                .font(.headline).foregroundStyle(.green)
                            Text("\(summary.setCount) sets · \(summary.volume.formatted()) lb·reps. View it in History.")
                                .font(.subheadline).multilineTextAlignment(.center)
                        }
                        ContentUnavailableView("Ready to train?", systemImage: "dumbbell",
                                               description: Text("Start a session to log reps and weight in pounds."))
                        Button("Start Session") { model.start() }.buttonStyle(.borderedProminent)
                    }.padding()
                }
            }
            .navigationTitle("Workout")
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
