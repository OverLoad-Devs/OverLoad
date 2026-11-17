import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var availableExercises: [Exercise]
    @Query private var sessions: [WorkoutSession]
    @State private var model = WorkoutViewModel()
    @State private var showPicker = false
    @State private var confirmCancel = false

    var body: some View {
        NavigationStack {
            Group {
                if model.isActive {
                    List {
                        ForEach($model.exercises) { $entry in
                            Section(entry.exercise.name) {
                                CoachSuggestionView(suggestion: suggestion(entry.exercise))
                                ForEach(Array(entry.sets.indices), id: \.self) { index in
                                    SetRow(number: index + 1, set: $entry.sets[index])
                                }.onDelete { entry.sets.remove(atOffsets: $0) }
                                Button("Add set", systemImage: "plus") {
                                    model.addSet(to: entry.id, suggestion: suggestion(entry.exercise))
                                }
                            }
                        }
                        Button("Pick exercise", systemImage: "plus.circle") { showPicker = true }
                        if let error = model.errorMessage { Text(error).foregroundStyle(.red) }
                        Button("Finish & Save") { model.finish(context: context) }
                            .disabled(!model.canSave)
                    }
                } else {
                    VStack(spacing: 20) {
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
            .sheet(isPresented: $showPicker) {
                NavigationStack {
                    List(availableExercises) { exercise in
                        Button {
                            model.add(exercise); showPicker = false
                        } label: {
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Text(exercise.primary.rawValue.capitalized).foregroundStyle(.secondary)
                            }
                        }.disabled(model.exercises.contains { $0.id == exercise.id })
                    }.navigationTitle("Pick Exercise")
                        .toolbar { Button("Done") { showPicker = false } }
                }
            }
        }
    }

    private func suggestion(_ exercise: Exercise) -> Suggestion {
        LoadCoachViewModel.suggestion(for: exercise, sessions: sessions)
    }
}

#Preview { WorkoutView().modelContainer(SampleData.preview()) }
